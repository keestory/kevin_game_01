import SpriteKit
import UIKit

@MainActor
protocol GameSceneDelegate: AnyObject {
    func gameScene(_ scene: GameScene, didEmit event: GameEvent)
}

@MainActor
final class GameScene: SKScene {
    weak var gameDelegate: GameSceneDelegate?

    private let seed: UInt64
    private let storedBestScore: Int
    private let storedBestHeight: Int
    private let visualVariant: VisualVariant
    private var state: ReturnShotState
    private var snapshot = RunSnapshot()
    private var lastUpdateTime: TimeInterval = 0
    private var accumulator: TimeInterval = 0
    private var snapshotAccumulator: TimeInterval = 0
    private var runFinished = false
    private var reduceMotion = false
    private let uiTestingFastFail = ProcessInfo.processInfo.arguments.contains("-uiTestingFastFail")
    private var testMissCountdown: TimeInterval?
    private var launchDelay: TimeInterval

    private let backgroundRoot = SKNode()
    private let structureRoot = SKNode()
    private let attackEffectsRoot = SKNode()
    private let effectsRoot = SKNode()
    private let ballNode = SKShapeNode(circleOfRadius: 10)
    private let ballCoreNode = SKShapeNode(circleOfRadius: 4)
    private let paddleNode = SKShapeNode(
        rectOf: CGSize(width: CGFloat(GameRules.paddleWidth), height: CGFloat(GameRules.paddleHeight)),
        cornerRadius: 9
    )
    private let paddleGlowNode = SKShapeNode(
        rectOf: CGSize(width: CGFloat(GameRules.paddleWidth + 14), height: CGFloat(GameRules.paddleHeight + 10)),
        cornerRadius: 14
    )
    private let landingNode = SKShapeNode(
        rectOf: CGSize(width: 58, height: 5),
        cornerRadius: 2.5
    )
    private let feedbackLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let segmentLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var brickNodes: [Int: SKNode] = [:]
    private struct SupportLinkKey: Hashable {
        let brickID: Int
        let supportID: Int
    }

    private var linkNodes: [SupportLinkKey: SKShapeNode] = [:]
    private var trailNodes: [SKShapeNode] = []
    private var trailHistory: [ShotVector] = []
    private var targetPaddleX: Double

    init(
        size: CGSize,
        seed: UInt64,
        bestScore: Int = 0,
        bestHeight: Int = 0,
        visualVariant: VisualVariant = .precisionNeon
    ) {
        self.seed = seed
        self.storedBestScore = bestScore
        self.storedBestHeight = bestHeight
        self.visualVariant = visualVariant
        self.state = GameRules.initialReturnShotState(seed: seed)
        self.targetPaddleX = Double(size.width / 2)
        let arguments = ProcessInfo.processInfo.arguments
        self.launchDelay = arguments.contains("-uiTestingFastFail") || arguments.contains("-captureHold")
            ? 3_600
            : 2.2
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = .zero
        backgroundColor = UIColor(hex: 0x071225)
        snapshot.bestScore = bestScore
        snapshot.bestHeight = bestHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard backgroundRoot.parent == nil else { return }
        view.isMultipleTouchEnabled = false
        buildBackground()
        buildGameplayNodes()
        rebuildStructure(animated: false)
        snapshot.phase = .playing
        syncSnapshot()
        renderState()
        emitSnapshot()
    }

    override func update(_ currentTime: TimeInterval) {
        guard snapshot.phase == .playing, !runFinished else { return }
        guard lastUpdateTime != 0 else {
            lastUpdateTime = currentTime
            return
        }

        let rawDelta = max(0, min(0.25, currentTime - lastUpdateTime))
        lastUpdateTime = currentTime
        snapshot.elapsed += rawDelta
        accumulator += rawDelta
        snapshotAccumulator += rawDelta

        if launchDelay > 0 {
            launchDelay = max(0, launchDelay - rawDelta)
            state.feedback = "패들을 공 아래로 옮겨 첫 리턴을 준비하세요"
            renderState()
            syncSnapshot()
            if snapshotAccumulator >= 0.05 {
                snapshotAccumulator = 0
                emitSnapshot()
            }
            return
        }

        if let countdown = testMissCountdown {
            testMissCountdown = countdown - rawDelta
        }
        if let countdown = testMissCountdown, countdown <= 0 {
            testMissCountdown = nil
            state.ball.position.y = GameRules.missLine - state.ball.radius - 1
            state.ball.velocity = ShotVector(x: 0, y: -370)
        }

        var steps = 0
        var emittedEvents: [ShotSimulationEvent] = []
        while accumulator >= GameRules.tickDuration, steps < 30 {
            emittedEvents.append(
                contentsOf: GameRules.stepReturnShot(
                    state: &state,
                    paddleTargetX: targetPaddleX
                )
            )
            accumulator -= GameRules.tickDuration
            steps += 1
            if state.phase == .finished { break }
        }
        if steps == 30 { accumulator = 0 }

        if !emittedEvents.isEmpty {
            processSimulationEvents(emittedEvents)
        }
        renderState()
        syncSnapshot()

        if snapshotAccumulator >= 0.05 {
            snapshotAccumulator = 0
            emitSnapshot()
        }
        if state.phase == .finished {
            finishRun()
        }
    }

    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        if enabled {
            effectsRoot.removeAllChildren()
            trailNodes.forEach { $0.alpha = 0 }
            backgroundRoot.removeAction(forKey: "drift")
        } else {
            trailNodes.forEach { $0.alpha = 1 }
            startBackgroundDrift()
        }
    }

    func setRunPaused(_ paused: Bool) {
        guard !runFinished else { return }
        if paused, snapshot.phase == .playing {
            snapshot.phase = .paused
            state.phase = .paused
            isPaused = true
        } else if !paused, snapshot.phase == .paused {
            snapshot.phase = .playing
            state.phase = .playing
            lastUpdateTime = 0
            accumulator = 0
            isPaused = false
            if uiTestingFastFail {
                launchDelay = 0
                testMissCountdown = 0.8
            }
        }
        emitSnapshot()
    }

    func movePaddleForAccessibility(by delta: Double) {
        guard snapshot.phase == .playing else { return }
        let minimumX = GameRules.sideWall + GameRules.paddleWidth / 2
        let maximumX = GameRules.fieldWidth - GameRules.sideWall - GameRules.paddleWidth / 2
        targetPaddleX = min(maximumX, max(minimumX, targetPaddleX + delta))
        state.feedback = delta < 0 ? "패들을 왼쪽으로 이동" : "패들을 오른쪽으로 이동"
        syncSnapshot()
        emitSnapshot()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updatePaddleTarget(from: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updatePaddleTarget(from: touches)
    }

    private func updatePaddleTarget(from touches: Set<UITouch>) {
        guard snapshot.phase == .playing, let point = touches.first?.location(in: self) else { return }
        targetPaddleX = Double(point.x)
    }

    private func processSimulationEvents(_ events: [ShotSimulationEvent]) {
        for event in events {
            switch event {
            case .paddleReturn(let edgeShot):
                animatePaddleReturn(edgeShot: edgeShot)
                gameDelegate?.gameScene(self, didEmit: .paddleReturn(edgeShot: edgeShot))
            case .brickHit(let id, _):
                updateBrickAppearance(id: id)
                animateBrickHit(id: id)
            case .brickRemoved(let id, let cause, let points):
                animateBrickRemoval(id: id, cause: cause)
                if points > 0 {
                    gameDelegate?.gameScene(self, didEmit: .brickDestroyed(points: points))
                }
            case .comboChanged:
                break
            case .linkChanged:
                break
            case .powerActivated:
                showFloatingText("공명 폭주 · 6초!", color: UIColor(hex: 0xFFD84D))
                gameDelegate?.gameScene(self, didEmit: .powerActivated)
            case .powerExpired:
                break
            case .negativeHit:
                showFloatingText("−250 · 지지점을 노리세요", color: UIColor(hex: 0xFF6B72))
                gameDelegate?.gameScene(self, didEmit: .negativeHit)
            case .cleanDrop:
                showFloatingText("위험 제거 +120", color: UIColor(hex: 0x49E2B4))
                gameDelegate?.gameScene(self, didEmit: .cleanDrop)
            case .armorChanged(let id, _):
                updateBrickAppearance(id: id)
                animateBrickHit(id: id)
            case .itemCollected(let kind, let level, let carrierID):
                showAttackBurst(kind: kind, level: level, sourceID: carrierID)
                gameDelegate?.gameScene(self, didEmit: .itemCollected(kind))
            case .pierceChargesChanged:
                break
            case .segmentAdvanced:
                rebuildStructure(animated: true)
            case .missed:
                break
            }
        }
    }

    private func syncSnapshot() {
        snapshot.phase = state.phase
        snapshot.score = Int(clamping: state.score)
        snapshot.height = state.height
        snapshot.combo = state.combo
        snapshot.maxCombo = state.maxCombo
        snapshot.link = state.link
        snapshot.maxLink = state.maxLink
        snapshot.powerProgress = Double(state.powerTicks) / Double(GameRules.powerDurationTicks)
        snapshot.powerSeconds = Double(state.powerTicks) / Double(GameRules.tickRate)
        snapshot.powerActivations = state.powerActivations
        snapshot.segment = state.segment + 1
        snapshot.feedback = state.feedback
        snapshot.isReturnShot = state.returnShotTicks > 0
        snapshot.destroyedBrickCount = state.destroyedBrickCount
        snapshot.attackItemLevels = state.attackItems.levels
        snapshot.pierceCharges = state.attackItems.pierceCharges
        snapshot.totalItemsCollected = state.attackItems.totalCollected
        snapshot.lastCollectedItem = state.attackItems.lastCollected
        snapshot.stageArmor = GameRules.stageArmor(segment: state.segment)
        snapshot.bestScore = storedBestScore
        snapshot.bestHeight = storedBestHeight
    }

    private func finishRun() {
        guard !runFinished else { return }
        runFinished = true
        snapshot.phase = .finished
        isUserInteractionEnabled = false
        renderState()
        syncSnapshot()
        emitSnapshot()
        let result = RunResult(
            score: Int(clamping: state.score),
            height: state.height,
            maxCombo: state.maxCombo,
            maxLink: state.maxLink,
            powerActivations: state.powerActivations,
            destroyedBrickCount: state.destroyedBrickCount,
            dailySeed: seed,
            previousBestScore: storedBestScore,
            previousBestHeight: storedBestHeight,
            attackItemLevels: state.attackItems.levels,
            totalItemsCollected: state.attackItems.totalCollected
        )
        gameDelegate?.gameScene(self, didEmit: .finished(result))
    }

    private func emitSnapshot() {
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
    }

    private func buildBackground() {
        backgroundRoot.zPosition = -100
        addChild(backgroundRoot)

        let base = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: size.height + 4))
        base.position = CGPoint(x: size.width / 2, y: size.height / 2)
        base.fillColor = UIColor(hex: 0x071225)
        base.strokeColor = .clear
        backgroundRoot.addChild(base)

        let backdrop = SKSpriteNode(imageNamed: "ReturnShotBackdrop")
        backdrop.size = CGSize(width: size.height * 2 / 3, height: size.height)
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.alpha = visualVariant == .impactPop ? 0.66 : 0.48
        backdrop.blendMode = .alpha
        backdrop.zPosition = 0
        backgroundRoot.addChild(backdrop)

        for index in 0..<7 {
            let glow = SKShapeNode(circleOfRadius: CGFloat(54 + index * 11))
            glow.position = CGPoint(
                x: index.isMultiple(of: 2) ? 40 : size.width - 30,
                y: CGFloat(180 + index * 92)
            )
            glow.fillColor = UIColor(hex: index.isMultiple(of: 2) ? 0x1A5C78 : 0x4A214F)
                .withAlphaComponent(0.035)
            glow.strokeColor = .clear
            backgroundRoot.addChild(glow)
        }

        for index in 0..<13 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            let y = CGFloat(142 + index * 50)
            path.move(to: CGPoint(x: 22, y: y))
            path.addLine(to: CGPoint(x: size.width - 22, y: y))
            line.path = path
            line.strokeColor = UIColor.white.withAlphaComponent(index.isMultiple(of: 5) ? 0.14 : 0.045)
            line.lineWidth = index.isMultiple(of: 5) ? 1.3 : 0.8
            backgroundRoot.addChild(line)
        }

        let sideRail = SKShapeNode(rectOf: CGSize(width: 4, height: 690), cornerRadius: 2)
        sideRail.position = CGPoint(x: 18, y: 450)
        sideRail.fillColor = UIColor(hex: 0x49E2B4).withAlphaComponent(0.28)
        sideRail.strokeColor = .clear
        backgroundRoot.addChild(sideRail)

        for index in 0..<6 {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "\(index * 10)m"
            label.fontSize = 10
            label.fontColor = UIColor.white.withAlphaComponent(0.52)
            label.horizontalAlignmentMode = .left
            label.position = CGPoint(x: 24, y: 164 + CGFloat(index * 108))
            backgroundRoot.addChild(label)
        }

        if storedBestHeight > 0 {
            let pbY = min(size.height - 150, 164 + CGFloat(storedBestHeight) * 6)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 24, y: pbY))
            path.addLine(to: CGPoint(x: size.width - 20, y: pbY))
            let pbLine = SKShapeNode(path: path)
            pbLine.strokeColor = UIColor(hex: 0xFFD84D).withAlphaComponent(0.72)
            pbLine.lineWidth = 2
            pbLine.zPosition = 2
            backgroundRoot.addChild(pbLine)

            let pbLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            pbLabel.text = "PB \(storedBestHeight)m"
            pbLabel.fontSize = 10
            pbLabel.fontColor = UIColor(hex: 0xFFD84D)
            pbLabel.horizontalAlignmentMode = .right
            pbLabel.position = CGPoint(x: size.width - 24, y: pbY + 5)
            pbLabel.zPosition = 3
            backgroundRoot.addChild(pbLabel)
        }
        startBackgroundDrift()
    }

    private func startBackgroundDrift() {
        guard !reduceMotion, backgroundRoot.action(forKey: "drift") == nil else { return }
        let moveUp = SKAction.moveBy(x: 0, y: 3, duration: 2.4)
        let moveDown = SKAction.moveBy(x: 0, y: -3, duration: 2.4)
        backgroundRoot.run(.repeatForever(.sequence([moveUp, moveDown])), withKey: "drift")
    }

    private func buildGameplayNodes() {
        structureRoot.zPosition = 0
        addChild(structureRoot)

        attackEffectsRoot.zPosition = 14
        addChild(attackEffectsRoot)

        effectsRoot.zPosition = 30
        addChild(effectsRoot)

        paddleGlowNode.fillColor = UIColor(hex: 0x49E2B4).withAlphaComponent(0.10)
        paddleGlowNode.strokeColor = UIColor(hex: 0x49E2B4).withAlphaComponent(0.22)
        paddleGlowNode.lineWidth = 2
        paddleGlowNode.zPosition = 5
        addChild(paddleGlowNode)

        paddleNode.fillColor = UIColor(hex: 0x122B43)
        paddleNode.strokeColor = UIColor(hex: 0x49E2B4)
        paddleNode.lineWidth = 4
        paddleNode.glowWidth = 7
        paddleNode.zPosition = 6
        addChild(paddleNode)

        ballNode.fillColor = .white
        ballNode.strokeColor = UIColor(hex: 0x071225)
        ballNode.lineWidth = 3
        ballNode.glowWidth = 5
        ballNode.zPosition = 20
        addChild(ballNode)

        ballCoreNode.fillColor = UIColor(hex: 0x49E2B4)
        ballCoreNode.strokeColor = .clear
        ballCoreNode.zPosition = 21
        addChild(ballCoreNode)

        landingNode.fillColor = UIColor(hex: 0xFFD84D).withAlphaComponent(0.58)
        landingNode.strokeColor = UIColor.white.withAlphaComponent(0.44)
        landingNode.lineWidth = 1
        landingNode.zPosition = 4
        addChild(landingNode)

        for index in 0..<8 {
            let radius = CGFloat(max(2, 7 - index / 2))
            let trail = SKShapeNode(circleOfRadius: radius)
            trail.fillColor = UIColor(hex: 0x49E2B4).withAlphaComponent(0.28 - CGFloat(index) * 0.025)
            trail.strokeColor = .clear
            trail.zPosition = 12 - CGFloat(index) * 0.1
            addChild(trail)
            trailNodes.append(trail)
        }

        feedbackLabel.removeFromParent()
        segmentLabel.removeFromParent()
    }

    private func rebuildStructure(animated: Bool) {
        structureRoot.removeAllChildren()
        brickNodes.removeAll(keepingCapacity: true)
        linkNodes.removeAll(keepingCapacity: true)

        for brick in state.bricks where !brick.isRemoved && !brick.supportIDs.isEmpty {
            for supportID in brick.supportIDs {
                guard let support = state.bricks.first(where: { $0.id == supportID && !$0.isRemoved }) else { continue }
                let path = CGMutablePath()
                path.move(
                    to: CGPoint(
                        x: CGFloat(brick.rect.center.x),
                        y: CGFloat(brick.rect.minY)
                    )
                )
                path.addLine(
                    to: CGPoint(
                        x: CGFloat(support.rect.center.x),
                        y: CGFloat(support.rect.maxY)
                    )
                )
                let link = SKShapeNode(path: path)
                link.strokeColor = brick.role == .negative
                    ? UIColor(hex: 0xFF6B72).withAlphaComponent(0.78)
                    : UIColor(hex: visualVariant == .impactPop ? 0xFFD84D : 0xC9D7E8)
                        .withAlphaComponent(visualVariant == .impactPop ? 0.34 : 0.20)
                link.lineWidth = brick.role == .negative ? 3.0 : 1.8
                link.zPosition = -1
                structureRoot.addChild(link)
                linkNodes[SupportLinkKey(brickID: brick.id, supportID: supportID)] = link
            }
        }

        for brick in state.bricks where !brick.isRemoved {
            let node = makeBrickNode(brick)
            node.alpha = animated ? 0 : 1
            node.setScale(animated ? 0.8 : 1)
            structureRoot.addChild(node)
            brickNodes[brick.id] = node
            if animated, !reduceMotion {
                node.run(
                    .group([
                        .fadeIn(withDuration: 0.22),
                        .scale(to: 1, duration: 0.22)
                    ])
                )
            } else {
                node.alpha = 1
                node.setScale(1)
            }
        }
    }

    private func makeBrickNode(_ brick: ShotBrick) -> SKNode {
        let root = SKNode()
        root.name = "brick-\(brick.id)"
        root.position = CGPoint(x: CGFloat(brick.rect.center.x), y: CGFloat(brick.rect.center.y))
        root.zPosition = 2
        decorateBrickNode(root, brick: brick)
        return root
    }

    private func decorateBrickNode(_ root: SKNode, brick: ShotBrick) {
        root.removeAllChildren()
        let shape = SKShapeNode(
            rectOf: CGSize(width: CGFloat(brick.rect.width), height: CGFloat(brick.rect.height)),
            cornerRadius: visualVariant == .impactPop ? 7 : (brick.role == .negative ? 8 : 12)
        )
        shape.name = "body"
        shape.lineWidth = brick.role == .prism ? 4.5 : 3
        shape.glowWidth = brick.role == .prism ? 7 : (visualVariant == .impactPop ? 4 : 2)

        switch brick.role {
        case .normal:
            let color = UIColor(hex: brick.signature?.color.tintHex ?? 0x6AA8FF)
            shape.fillColor = color.withAlphaComponent(visualVariant == .impactPop ? 0.88 : 0.78)
            shape.strokeColor = color.lighter(by: 0.34)
        case .support:
            shape.fillColor = UIColor(hex: 0x172A45)
            shape.strokeColor = UIColor(hex: 0xFFD84D)
        case .prism:
            shape.fillColor = UIColor(hex: 0x473B6D)
            shape.strokeColor = UIColor(hex: 0xFFD84D)
        case .negative:
            shape.fillColor = UIColor(hex: 0x3B1524)
            shape.strokeColor = UIColor(hex: 0xFF6B72)
        }
        root.addChild(shape)

        if let pattern = brick.signature?.pattern,
           brick.role == .normal || brick.role == .prism {
            addPattern(pattern, to: root, brick: brick)
        }

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        switch brick.role {
        case .normal, .prism:
            label.text = brick.signature?.mark.badge ?? "◆"
        case .support:
            label.text = "⌁"
        case .negative:
            label.text = "−"
        }
        label.fontSize = brick.role == .negative ? 28 : (visualVariant == .impactPop ? 21 : 19)
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.position.y = -1
        root.addChild(label)

        if brick.maximumHitPoints > 1, brick.maximumHitPoints < Int.max {
            for pipIndex in 0..<brick.maximumHitPoints {
                let pip = SKShapeNode(circleOfRadius: 3)
                pip.fillColor = pipIndex < brick.hitPoints ? UIColor(hex: 0xFFD84D) : UIColor.white.withAlphaComponent(0.16)
                pip.strokeColor = .clear
                pip.position = CGPoint(
                    x: CGFloat((Double(pipIndex) - Double(brick.maximumHitPoints - 1) / 2) * 10),
                    y: CGFloat(-brick.rect.height / 2 + 7)
                )
                root.addChild(pip)
            }
        }

        if brick.maximumArmor > 0 {
            for armorIndex in 0..<brick.maximumArmor {
                let plate = SKShapeNode(
                    rectOf: CGSize(width: 12, height: 5),
                    cornerRadius: 2
                )
                plate.fillColor = armorIndex < brick.armor
                    ? UIColor(hex: 0xA9E7FF)
                    : UIColor.white.withAlphaComponent(0.12)
                plate.strokeColor = armorIndex < brick.armor
                    ? UIColor.white.withAlphaComponent(0.70)
                    : .clear
                plate.lineWidth = 0.8
                plate.position = CGPoint(
                    x: CGFloat(-brick.rect.width / 2 + 8 + Double(armorIndex) * 14),
                    y: CGFloat(brick.rect.height / 2 - 6)
                )
                root.addChild(plate)
            }
        }

        if let item = brick.embeddedItem {
            let badge = SKShapeNode(circleOfRadius: 12)
            badge.fillColor = UIColor(hex: 0x071225).withAlphaComponent(0.96)
            badge.strokeColor = UIColor(hex: item.tintHex)
            badge.lineWidth = 2.5
            badge.glowWidth = visualVariant == .impactPop ? 5 : 3
            badge.position = CGPoint(
                x: CGFloat(brick.rect.width / 2 - 12),
                y: CGFloat(brick.rect.height / 2 - 12)
            )
            badge.zPosition = 8
            root.addChild(badge)

            let itemLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            itemLabel.text = item.badge
            itemLabel.fontSize = item == .flame || item == .wind ? 11 : 14
            itemLabel.fontColor = .white
            itemLabel.verticalAlignmentMode = .center
            itemLabel.position.y = -0.5
            badge.addChild(itemLabel)
        }

        if brick.role == .negative {
            let warning = SKLabelNode(fontNamed: "AvenirNext-Bold")
            warning.text = "직접 −250"
            warning.fontSize = 9
            warning.fontColor = UIColor(hex: 0xFFB1A9)
            warning.position.y = CGFloat(-brick.rect.height / 2 - 13)
            root.addChild(warning)
        }
    }

    private func addPattern(_ pattern: BrickPattern, to root: SKNode, brick: ShotBrick) {
        let color = UIColor.white.withAlphaComponent(visualVariant == .impactPop ? 0.32 : 0.22)
        let halfWidth = CGFloat(brick.rect.width / 2 - 7)
        let halfHeight = CGFloat(brick.rect.height / 2 - 7)

        func addLine(from: CGPoint, to: CGPoint) {
            let path = CGMutablePath()
            path.move(to: from)
            path.addLine(to: to)
            let line = SKShapeNode(path: path)
            line.strokeColor = color
            line.lineWidth = visualVariant == .impactPop ? 2 : 1.4
            root.addChild(line)
        }

        switch pattern {
        case .stripe:
            for offset: CGFloat in [-9, 0, 9] {
                addLine(
                    from: CGPoint(x: -halfWidth, y: CGFloat(offset) - 4),
                    to: CGPoint(x: halfWidth, y: CGFloat(offset) + 4)
                )
            }
        case .dot:
            for x in [-halfWidth + 3, halfWidth - 3] {
                for y in [-halfHeight + 3, halfHeight - 3] {
                    let dot = SKShapeNode(circleOfRadius: visualVariant == .impactPop ? 2.5 : 2)
                    dot.position = CGPoint(x: x, y: y)
                    dot.fillColor = color
                    dot.strokeColor = .clear
                    root.addChild(dot)
                }
            }
        case .grid:
            addLine(from: CGPoint(x: -halfWidth, y: 0), to: CGPoint(x: halfWidth, y: 0))
            addLine(from: CGPoint(x: 0, y: -halfHeight), to: CGPoint(x: 0, y: halfHeight))
        }
    }

    private func updateBrickAppearance(id: Int) {
        guard let root = brickNodes[id],
              let brick = state.bricks.first(where: { $0.id == id }),
              !brick.isRemoved else { return }
        decorateBrickNode(root, brick: brick)
    }

    private func renderState() {
        let ballPosition = CGPoint(x: CGFloat(state.ball.position.x), y: CGFloat(state.ball.position.y))
        ballNode.position = ballPosition
        ballCoreNode.position = ballPosition
        paddleNode.position = CGPoint(x: CGFloat(state.paddleX), y: CGFloat(GameRules.paddleY))
        paddleGlowNode.position = paddleNode.position

        let powerActive = state.isPowerActive
        let pierceReady = state.attackItems.pierceCharges > 0
        ballNode.fillColor = powerActive ? UIColor(hex: 0xFFD84D) : .white
        ballNode.strokeColor = powerActive
            ? UIColor(hex: 0x49E2B4)
            : UIColor(hex: pierceReady ? AttackItemKind.pierce.tintHex : 0x071225)
        ballNode.glowWidth = powerActive ? 13 : 5
        ballCoreNode.fillColor = powerActive
            ? UIColor(hex: 0xFF6B72)
            : UIColor(hex: pierceReady ? AttackItemKind.pierce.tintHex : 0x49E2B4)
        let ballScale = powerActive ? 1.24 : 1
        ballNode.setScale(ballScale)
        ballCoreNode.setScale(ballScale)

        trailHistory.insert(state.ball.position, at: 0)
        if trailHistory.count > trailNodes.count * 2 {
            trailHistory.removeLast(trailHistory.count - trailNodes.count * 2)
        }
        for (index, trail) in trailNodes.enumerated() {
            let historyIndex = min(trailHistory.count - 1, index * 2)
            guard historyIndex >= 0, trailHistory.indices.contains(historyIndex) else { continue }
            let point = trailHistory[historyIndex]
            trail.position = CGPoint(x: CGFloat(point.x), y: CGFloat(point.y))
            trail.fillColor = (powerActive ? UIColor(hex: 0xFFD84D) : UIColor(hex: 0x49E2B4))
                .withAlphaComponent(0.27 - CGFloat(index) * 0.025)
            trail.isHidden = reduceMotion
        }
        updateLandingIndicator()
    }

    private func updateLandingIndicator() {
        guard state.ball.velocity.y < -1 else {
            landingNode.isHidden = true
            return
        }
        let travelTime = (GameRules.paddleY - state.ball.position.y) / state.ball.velocity.y
        guard travelTime > 0, travelTime < 3 else {
            landingNode.isHidden = true
            return
        }
        let rawX = state.ball.position.x + state.ball.velocity.x * travelTime
        let minimumX = GameRules.sideWall + state.ball.radius
        let maximumX = GameRules.fieldWidth - GameRules.sideWall - state.ball.radius
        let width = maximumX - minimumX
        let shifted = rawX - minimumX
        let period = width * 2
        var folded = shifted.truncatingRemainder(dividingBy: period)
        if folded < 0 { folded += period }
        let predictedX = minimumX + (folded <= width ? folded : period - folded)
        landingNode.position = CGPoint(x: CGFloat(predictedX), y: CGFloat(GameRules.paddleY + 20))
        landingNode.isHidden = false
    }

    private func animatePaddleReturn(edgeShot: Bool) {
        guard !reduceMotion else { return }
        let color = edgeShot ? UIColor(hex: 0xFFD84D) : UIColor(hex: 0x49E2B4)
        let ring = SKShapeNode(circleOfRadius: edgeShot ? 30 : 20)
        ring.position = paddleNode.position
        ring.strokeColor = color
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.zPosition = 24
        effectsRoot.addChild(ring)
        ring.run(
            .sequence([
                .group([
                    .scale(to: 1.8, duration: 0.18),
                    .fadeOut(withDuration: 0.18)
                ]),
                .removeFromParent()
            ])
        )
    }

    private func animateBrickHit(id: Int) {
        guard !reduceMotion, let node = brickNodes[id], node.parent != nil else { return }
        node.removeAction(forKey: "hit")
        node.run(
            .sequence([
                .scale(to: 1.10, duration: 0.055),
                .scale(to: 1.0, duration: 0.075)
            ]),
            withKey: "hit"
        )
    }

    private func animateBrickRemoval(id: Int, cause: ShotRemovalCause) {
        guard let node = brickNodes.removeValue(forKey: id) else { return }
        let removedLinkKeys = linkNodes.keys.filter { $0.brickID == id || $0.supportID == id }
        for key in removedLinkKeys {
            linkNodes.removeValue(forKey: key)?.removeFromParent()
        }
        if reduceMotion {
            node.removeFromParent()
            return
        }
        let action: SKAction
        switch cause {
        case .direct, .shockwave:
            action = .group([
                .scale(to: 1.35, duration: 0.16),
                .fadeOut(withDuration: 0.16),
                .rotate(byAngle: 0.18, duration: 0.16)
            ])
        case .unsupportedFall:
            action = .group([
                .moveBy(x: 0, y: -125, duration: 0.34),
                .fadeOut(withDuration: 0.34),
                .rotate(byAngle: 0.42, duration: 0.34)
            ])
        case .attackItem(let kind):
            node.run(.colorize(with: UIColor(hex: kind.tintHex), colorBlendFactor: 0.8, duration: 0.08))
            action = .group([
                .scale(to: 1.50, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ])
        }
        node.run(.sequence([action, .removeFromParent()]))
    }

    private func showAttackBurst(kind: AttackItemKind, level: Int, sourceID: Int) {
        let color = UIColor(hex: kind.tintHex)
        let source = state.bricks.first(where: { $0.id == sourceID })?.rect.center
            ?? ShotVector(x: GameRules.fieldWidth / 2, y: 360)
        let center = CGPoint(x: CGFloat(source.x), y: CGFloat(source.y))

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.position = center
        ring.strokeColor = color
        ring.fillColor = .clear
        ring.lineWidth = 4
        ring.glowWidth = reduceMotion ? 0 : 5
        ring.zPosition = 0
        attackEffectsRoot.addChild(ring)
        addAttackCue(kind: kind, color: color, to: ring)

        let glyph = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        glyph.text = kind.badge
        glyph.fontSize = 18
        glyph.fontColor = .white
        glyph.verticalAlignmentMode = .center
        ring.addChild(glyph)

        if reduceMotion {
            ring.run(.sequence([.wait(forDuration: 0.18), .removeFromParent()]))
        } else {
            ring.run(
                .sequence([
                    .group([
                        .scale(to: 2.6, duration: 0.32),
                        .fadeOut(withDuration: 0.32)
                    ]),
                    .removeFromParent()
                ])
            )
        }
    }

    private func addAttackCue(kind: AttackItemKind, color: UIColor, to root: SKNode) {
        let path = CGMutablePath()
        switch kind {
        case .lightning:
            path.move(to: CGPoint(x: -6, y: 16))
            path.addLine(to: CGPoint(x: 3, y: 5))
            path.addLine(to: CGPoint(x: -2, y: 5))
            path.addLine(to: CGPoint(x: 7, y: -16))
        case .flame:
            path.move(to: CGPoint(x: 0, y: 17))
            path.addCurve(
                to: CGPoint(x: 0, y: -16),
                control1: CGPoint(x: 17, y: 5),
                control2: CGPoint(x: 10, y: -13)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: 17),
                control1: CGPoint(x: -14, y: -10),
                control2: CGPoint(x: -10, y: 5)
            )
        case .wind:
            for offset in [-9.0, 0.0, 9.0] {
                path.move(to: CGPoint(x: -15, y: offset - 3))
                path.addQuadCurve(
                    to: CGPoint(x: 15, y: offset + 3),
                    control: CGPoint(x: 0, y: offset + 9)
                )
            }
        case .pierce:
            for offset: CGFloat in [-5, 5] {
                path.move(to: CGPoint(x: -15 + offset, y: 0))
                path.addLine(to: CGPoint(x: 9 + offset, y: 0))
                path.move(to: CGPoint(x: 2 + offset, y: 8))
                path.addLine(to: CGPoint(x: 10 + offset, y: 0))
                path.addLine(to: CGPoint(x: 2 + offset, y: -8))
            }
        }

        let cue = SKShapeNode(path: path)
        cue.strokeColor = color
        cue.fillColor = .clear
        cue.lineWidth = 3
        cue.lineCap = .round
        cue.lineJoin = .round
        cue.glowWidth = reduceMotion ? 0 : 2
        root.addChild(cue)
    }

    private func showFloatingText(_ text: String, color: UIColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 20
        label.fontColor = color
        label.position = CGPoint(x: size.width / 2, y: 360)
        label.zPosition = 50
        effectsRoot.addChild(label)
        if reduceMotion {
            label.run(.sequence([.wait(forDuration: 0.45), .removeFromParent()]))
        } else {
            label.run(
                .sequence([
                    .group([
                        .moveBy(x: 0, y: 36, duration: 0.52),
                        .sequence([.wait(forDuration: 0.22), .fadeOut(withDuration: 0.30)])
                    ]),
                    .removeFromParent()
                ])
            )
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    func lighter(by amount: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }
        return UIColor(
            red: min(1, red + amount),
            green: min(1, green + amount),
            blue: min(1, blue + amount),
            alpha: alpha
        )
    }
}
