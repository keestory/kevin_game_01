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
    private let gameArt = GameArtCatalog.shared

#if DEBUG
    private let artShowcaseKind: AttackItemKind?
    private let artShowcaseOverdrive: Bool
    private weak var artShowcaseAccessibilityMarker: UIView?
#endif

    private let backgroundRoot = SKNode()
    private let structureRoot = SKNode()
    private let attackEffectsRoot = SKNode()
    private let effectsRoot = SKNode()
    private let ballNode = SKShapeNode(circleOfRadius: 10)
    private let ballCoreNode = SKShapeNode(circleOfRadius: 4)
    private let paddleNode = SKShapeNode(
        rectOf: CGSize(width: CGFloat(GameRules.paddleWidth), height: CGFloat(GameRules.paddleHeight)),
        cornerRadius: GameRadius.button
    )
    private let paddleGlowNode = SKShapeNode(
        rectOf: CGSize(width: CGFloat(GameRules.paddleWidth + 14), height: CGFloat(GameRules.paddleHeight + 10)),
        cornerRadius: GameRadius.card
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
    private let maximumConcurrentGeneralEffects = 24

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
#if DEBUG
        self.artShowcaseOverdrive = arguments.contains("-uiTestingOverdriveShowcase")
        if let argumentIndex = arguments.firstIndex(of: "-uiTestingArtShowcase"),
           arguments.indices.contains(argumentIndex + 1) {
            self.artShowcaseKind = GameArtCatalog.shared.attackKind(
                showcaseArgument: arguments[argumentIndex + 1]
            )
        } else {
            self.artShowcaseKind = nil
        }
#endif
        self.launchDelay = arguments.contains("-uiTestingFastFail") || arguments.contains("-captureHold")
            ? 3_600
            : 2.2
        super.init(size: size)
        scaleMode = .aspectFill
        anchorPoint = .zero
        backgroundColor = UIColor(hex: GamePalette.canvasHex)
        snapshot.bestScore = bestScore
        snapshot.bestHeight = bestHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard backgroundRoot.parent == nil else { return }
        view.isMultipleTouchEnabled = false
        gameArt.preload()
        buildBackground()
        buildGameplayNodes()
        rebuildStructure(animated: false)
        snapshot.phase = .playing
        syncSnapshot()
        renderState()
        emitSnapshot()
#if DEBUG
        installArtShowcaseIfRequested(in: view)
#endif
    }

    override func willMove(from view: SKView) {
#if DEBUG
        artShowcaseAccessibilityMarker?.removeFromSuperview()
#endif
        super.willMove(from: view)
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
            attackEffectsRoot.removeAllChildren()
            trailNodes.forEach { $0.alpha = 0 }
            backgroundRoot.removeAction(forKey: "drift")
#if DEBUG
            if let artShowcaseKind {
                showAttackBurst(
                    kind: artShowcaseKind,
                    level: 3,
                    at: CGPoint(x: size.width / 2, y: 350),
                    overdrive: artShowcaseOverdrive,
                    heldForShowcase: true
                )
            }
#endif
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
                showFloatingText("공명 폭주 · 6초!", color: UIColor(hex: GamePalette.warningHex))
                gameDelegate?.gameScene(self, didEmit: .powerActivated)
            case .powerExpired:
                break
            case .negativeHit:
                showFloatingText("−250 · 지지점을 노리세요", color: UIColor(hex: GamePalette.dangerHex))
                gameDelegate?.gameScene(self, didEmit: .negativeHit)
            case .cleanDrop:
                showFloatingText("위험 제거 +120", color: UIColor(hex: GamePalette.successHex))
                gameDelegate?.gameScene(self, didEmit: .cleanDrop)
            case .armorChanged(let id, _):
                updateBrickAppearance(id: id)
                animateBrickHit(id: id)
            case .itemCollected(let kind, let level, let carrierID):
                showAttackBurst(kind: kind, level: level, sourceID: carrierID)
                gameDelegate?.gameScene(self, didEmit: .itemCollected(kind))
            case .itemOverdriveScheduled:
                break
            case .itemOverdriveActivated(let kind, let rank, _, let carrierID):
                showAttackBurst(
                    kind: kind,
                    level: rank,
                    sourceID: carrierID,
                    overdrive: true
                )
            case .pierceChargesChanged:
                break
            case .segmentAdvanced:
                break
            case .levelAdvanced(let profile):
                rebuildStructure(animated: true)
                showLevelTransition(profile)
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
        snapshot.overdriveCount = state.attackItems.overdriveCount
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
        base.fillColor = UIColor(hex: GamePalette.canvasHex)
        base.strokeColor = .clear
        backgroundRoot.addChild(base)

        let backdrop = SKSpriteNode(texture: gameArt.texture(.playfieldBackground))
        backdrop.size = size
        backdrop.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backdrop.alpha = visualVariant == .impactPop ? 0.90 : 0.80
        backdrop.blendMode = .alpha
        backdrop.zPosition = 0
        backgroundRoot.addChild(backdrop)

        for index in 0..<7 {
            let glow = SKShapeNode(circleOfRadius: CGFloat(54 + index * 11))
            glow.position = CGPoint(
                x: index.isMultiple(of: 2) ? 40 : size.width - 30,
                y: CGFloat(180 + index * 92)
            )
            glow.fillColor = UIColor(
                hex: index.isMultiple(of: 2) ? GamePalette.infoHex : GamePalette.dangerHex
            )
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
            line.strokeColor = UIColor(hex: GamePalette.borderSubtleHex)
                .withAlphaComponent(index.isMultiple(of: 5) ? 0.30 : 0.12)
            line.lineWidth = index.isMultiple(of: 5) ? 1.3 : 0.8
            backgroundRoot.addChild(line)
        }

        let sideRail = SKShapeNode(rectOf: CGSize(width: 4, height: 690), cornerRadius: 2)
        sideRail.position = CGPoint(x: 18, y: 450)
        sideRail.fillColor = UIColor(hex: GamePalette.successHex).withAlphaComponent(0.28)
        sideRail.strokeColor = .clear
        backgroundRoot.addChild(sideRail)

        for index in 0..<6 {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = "\(index * 10)m"
            label.fontSize = 10
            label.fontColor = UIColor(hex: GamePalette.textMutedHex).withAlphaComponent(0.82)
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
            pbLine.strokeColor = UIColor(hex: GamePalette.warningHex).withAlphaComponent(0.72)
            pbLine.lineWidth = 2
            pbLine.zPosition = 2
            backgroundRoot.addChild(pbLine)

            let pbLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            pbLabel.text = "PB \(storedBestHeight)m"
            pbLabel.fontSize = 10
            pbLabel.fontColor = UIColor(hex: GamePalette.warningHex)
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

        effectsRoot.zPosition = 18
        addChild(effectsRoot)

        paddleGlowNode.fillColor = UIColor(hex: GamePalette.successHex).withAlphaComponent(0.10)
        paddleGlowNode.strokeColor = UIColor(hex: GamePalette.successHex).withAlphaComponent(0.22)
        paddleGlowNode.lineWidth = 2
        paddleGlowNode.zPosition = 5
        addChild(paddleGlowNode)

        paddleNode.fillTexture = nil
        paddleNode.fillColor = UIColor(hex: GamePalette.surface3Hex)
        paddleNode.strokeColor = UIColor(hex: GamePalette.infoHex)
        paddleNode.lineWidth = 2.5
        paddleNode.glowWidth = 3
        paddleNode.zPosition = 6
        decorateMechanicalPaddle()
        addChild(paddleNode)

        ballNode.fillTexture = gameArt.gameplayTexture(.ballChrome)
        ballNode.fillColor = UIColor(hex: GamePalette.textPrimaryHex)
        ballNode.strokeColor = UIColor(hex: GamePalette.deepHex)
        ballNode.lineWidth = 3
        ballNode.glowWidth = 5
        ballNode.zPosition = 20
        addChild(ballNode)

        ballCoreNode.fillColor = UIColor(hex: GamePalette.successHex)
        ballCoreNode.strokeColor = .clear
        ballCoreNode.zPosition = 21
        addChild(ballCoreNode)

        landingNode.fillColor = UIColor(hex: GamePalette.warningHex).withAlphaComponent(0.58)
        landingNode.strokeColor = UIColor(hex: GamePalette.textPrimaryHex).withAlphaComponent(0.44)
        landingNode.lineWidth = 1
        landingNode.zPosition = 4
        addChild(landingNode)

        for index in 0..<8 {
            let radius = CGFloat(max(2, 7 - index / 2))
            let trail = SKShapeNode(circleOfRadius: radius)
            trail.fillColor = UIColor(hex: GamePalette.successHex)
                .withAlphaComponent(0.18 - CGFloat(index) * 0.02)
            trail.strokeColor = .clear
            trail.zPosition = 12 - CGFloat(index) * 0.1
            addChild(trail)
            trailNodes.append(trail)
        }

        feedbackLabel.removeFromParent()
        segmentLabel.removeFromParent()
    }

    private func decorateMechanicalPaddle() {
        paddleNode.removeAllChildren()

        let core = SKShapeNode(
            rectOf: CGSize(width: CGFloat(GameRules.paddleWidth - 34), height: 8),
            cornerRadius: 4
        )
        core.fillColor = UIColor(hex: GamePalette.fireHex)
        core.strokeColor = UIColor(hex: GamePalette.fireCoreHex)
        core.lineWidth = 1.5
        core.glowWidth = 5
        core.zPosition = 1
        paddleNode.addChild(core)

        for direction: CGFloat in [-1, 1] {
            let endCap = SKShapeNode(
                rectOf: CGSize(width: 18, height: CGFloat(GameRules.paddleHeight - 4)),
                cornerRadius: 3
            )
            endCap.position.x = direction * CGFloat(GameRules.paddleWidth / 2 - 10)
            endCap.fillColor = UIColor(hex: GamePalette.deepHex)
            endCap.strokeColor = UIColor(hex: GamePalette.warningHex)
            endCap.lineWidth = 2
            endCap.zPosition = 2
            paddleNode.addChild(endCap)
        }

        for direction: CGFloat in [-1, 1] {
            let energyTick = SKShapeNode(
                rectOf: CGSize(width: 17, height: 2.5),
                cornerRadius: 1.25
            )
            energyTick.position = CGPoint(x: 0, y: direction * 6)
            energyTick.fillColor = UIColor(hex: GamePalette.infoHex)
            energyTick.strokeColor = .clear
            energyTick.glowWidth = 2
            energyTick.zPosition = 2
            paddleNode.addChild(energyTick)
        }
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
                    ? UIColor(hex: GamePalette.dangerHex).withAlphaComponent(0.78)
                    : UIColor(
                        hex: visualVariant == .impactPop
                            ? GamePalette.warningHex
                            : GamePalette.borderStrongHex
                    )
                    .withAlphaComponent(visualVariant == .impactPop ? 0.34 : 0.44)
                link.lineWidth = brick.role == .negative ? 3.0 : 1.8
                link.zPosition = -1
                structureRoot.addChild(link)
                linkNodes[SupportLinkKey(brickID: brick.id, supportID: supportID)] = link
            }
        }

        for (order, brick) in state.bricks.filter({ !$0.isRemoved }).enumerated() {
            let node = makeBrickNode(brick)
            node.alpha = animated ? 0 : 1
            node.setScale(animated && !reduceMotion ? 0.96 : 1)
            structureRoot.addChild(node)
            brickNodes[brick.id] = node
            if animated, !reduceMotion {
                node.run(
                    .sequence([
                        .wait(forDuration: min(0.34, Double(order) * 0.011)),
                        .group([
                            .fadeIn(withDuration: 0.20),
                            .scale(to: 1, duration: 0.20)
                        ])
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
            cornerRadius: GameRadius.brick
        )
        shape.name = "body"
        shape.lineWidth = brick.role == .prism ? 4.5 : 3
        shape.glowWidth = brick.role == .prism ? 4 : 0
        shape.fillTexture = gameArt.gameplayTexture(.brickMaterial)
        shape.zPosition = 0

        let materialTint: UIColor
        switch brick.role {
        case .normal:
            let color = UIColor(
                hex: GamePalette.brickHex(brick.signature?.color ?? .blue)
            )
            materialTint = color
            shape.fillColor = color.withAlphaComponent(visualVariant == .impactPop ? 0.88 : 0.78)
            shape.strokeColor = UIColor(hex: GamePalette.textPrimaryHex).withAlphaComponent(0.72)
        case .support:
            materialTint = UIColor(hex: GamePalette.warningHex)
            shape.fillColor = UIColor(hex: GamePalette.surface2Hex)
            shape.strokeColor = UIColor(hex: GamePalette.warningHex)
        case .prism:
            materialTint = UIColor(hex: GamePalette.warningHex)
            shape.fillColor = UIColor(hex: GamePalette.surface3Hex)
            shape.strokeColor = UIColor(hex: GamePalette.warningHex)
        case .negative:
            materialTint = UIColor(hex: GamePalette.dangerHex)
            shape.fillColor = UIColor(hex: GamePalette.dangerHex).withAlphaComponent(0.24)
            shape.strokeColor = UIColor(hex: GamePalette.dangerHex)
        }
        root.addChild(shape)

        let tintOverlay = SKShapeNode(
            rectOf: CGSize(width: CGFloat(brick.rect.width), height: CGFloat(brick.rect.height)),
            cornerRadius: GameRadius.brick
        )
        tintOverlay.name = "materialTint"
        tintOverlay.fillColor = materialTint.withAlphaComponent(
            brick.role == .negative ? 0.36 : 0.20
        )
        tintOverlay.strokeColor = .clear
        tintOverlay.zPosition = 1
        root.addChild(tintOverlay)

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
        label.fontColor = UIColor(hex: GamePalette.textPrimaryHex)
        label.verticalAlignmentMode = .center
        label.position.y = -1
        label.zPosition = 3
        root.addChild(label)

        if brick.maximumHitPoints > 1, brick.maximumHitPoints < Int.max {
            for pipIndex in 0..<brick.maximumHitPoints {
                let pip = SKShapeNode(circleOfRadius: 3)
                pip.fillColor = pipIndex < brick.hitPoints
                    ? UIColor(hex: GamePalette.warningHex)
                    : UIColor(hex: GamePalette.textPrimaryHex).withAlphaComponent(0.16)
                pip.strokeColor = .clear
                pip.position = CGPoint(
                    x: CGFloat((Double(pipIndex) - Double(brick.maximumHitPoints - 1) / 2) * 10),
                    y: CGFloat(-brick.rect.height / 2 + 7)
                )
                pip.zPosition = 4
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
                    ? UIColor(hex: GamePalette.shieldBlueHex)
                    : UIColor(hex: GamePalette.textPrimaryHex).withAlphaComponent(0.12)
                plate.strokeColor = armorIndex < brick.armor
                    ? UIColor(hex: GamePalette.textPrimaryHex).withAlphaComponent(0.70)
                    : .clear
                plate.lineWidth = 0.8
                plate.position = CGPoint(
                    x: CGFloat(-brick.rect.width / 2 + 8 + Double(armorIndex) * 14),
                    y: CGFloat(brick.rect.height / 2 - 6)
                )
                plate.zPosition = 6
                root.addChild(plate)
            }
        }

        if let item = brick.embeddedItem {
            let badge = SKShapeNode(circleOfRadius: 12)
            badge.fillColor = UIColor(hex: GamePalette.deepHex).withAlphaComponent(0.96)
            badge.strokeColor = UIColor(hex: GamePalette.attackHex(item))
            badge.lineWidth = 2.5
            badge.glowWidth = visualVariant == .impactPop ? 3 : 2
            badge.position = CGPoint(
                x: CGFloat(brick.rect.width / 2 - 12),
                y: CGFloat(brick.rect.height / 2 - 12)
            )
            badge.zPosition = 8
            root.addChild(badge)

            let itemLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            itemLabel.text = item.badge
            itemLabel.fontSize = item == .flame || item == .wind ? 11 : 14
            itemLabel.fontColor = UIColor(hex: GamePalette.attackCoreHex(item))
            itemLabel.verticalAlignmentMode = .center
            itemLabel.position.y = -0.5
            badge.addChild(itemLabel)
        }

    }

    private func addPattern(_ pattern: BrickPattern, to root: SKNode, brick: ShotBrick) {
        let color = UIColor(hex: GamePalette.textPrimaryHex)
            .withAlphaComponent(visualVariant == .impactPop ? 0.32 : 0.22)
        let halfWidth = CGFloat(brick.rect.width / 2 - 7)
        let halfHeight = CGFloat(brick.rect.height / 2 - 7)

        func addLine(from: CGPoint, to: CGPoint) {
            let path = CGMutablePath()
            path.move(to: from)
            path.addLine(to: to)
            let line = SKShapeNode(path: path)
            line.strokeColor = color
            line.lineWidth = visualVariant == .impactPop ? 2 : 1.4
            line.zPosition = 2
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
                    dot.zPosition = 2
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
        ballNode.fillColor = powerActive
            ? UIColor(hex: GamePalette.warningHex)
            : UIColor(hex: GamePalette.textPrimaryHex)
        ballNode.strokeColor = powerActive
            ? UIColor(hex: GamePalette.successHex)
            : UIColor(
                hex: pierceReady ? GamePalette.attackHex(.pierce) : GamePalette.deepHex
            )
        ballNode.glowWidth = powerActive ? 13 : 5
        ballCoreNode.fillColor = powerActive
            ? UIColor(hex: GamePalette.dangerHex)
            : UIColor(
                hex: pierceReady ? GamePalette.attackCoreHex(.pierce) : GamePalette.successHex
            )
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
            trail.fillColor = UIColor(
                hex: powerActive ? GamePalette.warningHex : GamePalette.successHex
            )
            .withAlphaComponent(0.18 - CGFloat(index) * 0.02)
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
        let color = UIColor(
            hex: edgeShot ? GamePalette.warningHex : GamePalette.successHex
        )
        let ring = SKShapeNode(circleOfRadius: edgeShot ? 30 : 20)
        ring.position = paddleNode.position
        ring.strokeColor = color
        ring.fillColor = .clear
        ring.lineWidth = 3
        ring.zPosition = 0
        addGeneralEffect(ring)
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
        guard let node = brickNodes[id], node.parent != nil else { return }
        node.removeAction(forKey: "hit")
        if reduceMotion {
            guard let brick = state.bricks.first(where: { $0.id == id }) else { return }
            let outline = SKShapeNode(
                rectOf: CGSize(
                    width: CGFloat(brick.rect.width),
                    height: CGFloat(brick.rect.height)
                ),
                cornerRadius: GameRadius.brick
            )
            outline.position = node.position
            outline.fillColor = .clear
            outline.strokeColor = UIColor(hex: GamePalette.warningHex)
            outline.lineWidth = 3
            outline.alpha = 0.92
            outline.zPosition = 0
            addGeneralEffect(outline)
            outline.run(
                .sequence([
                    .fadeAlpha(to: 0.24, duration: 0.16),
                    .removeFromParent()
                ])
            )
            return
        }
        node.run(
            .sequence([
                .scale(to: 1.10, duration: 0.055),
                .scale(to: 1.0, duration: 0.075)
            ]),
            withKey: "hit"
        )
        showBrickHitSparks(id: id, center: node.position)
    }

    private func showBrickHitSparks(id: Int, center: CGPoint) {
        let sparkCount = 4
        for index in 0..<sparkCount {
            let angleIndex = (abs(id) + index * 2) % 8
            let angle = CGFloat(angleIndex) * (.pi / 4)
            let distance = CGFloat(14 + index * 3)
            let spark = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 1.8 : 1.3)
            spark.position = center
            spark.fillColor = UIColor(hex: GamePalette.warningHex)
            spark.strokeColor = UIColor(hex: GamePalette.textPrimaryHex)
            spark.lineWidth = 0.6
            spark.zPosition = 0
            addGeneralEffect(spark)
            spark.run(
                .sequence([
                    .group([
                        .moveBy(
                            x: cos(angle) * distance,
                            y: sin(angle) * distance,
                            duration: 0.18
                        ),
                        .fadeOut(withDuration: 0.18)
                    ]),
                    .removeFromParent()
                ])
            )
        }
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
            node.run(
                .colorize(
                    with: UIColor(hex: GamePalette.attackHex(kind)),
                    colorBlendFactor: 0.8,
                    duration: GameMotion.instant
                )
            )
            action = .group([
                .scale(to: 1.50, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ])
        }
        node.run(.sequence([action, .removeFromParent()]))
    }

    private func showAttackBurst(
        kind: AttackItemKind,
        level: Int,
        sourceID: Int,
        overdrive: Bool = false
    ) {
        let source = state.bricks.first(where: { $0.id == sourceID })?.rect.center
            ?? ShotVector(x: GameRules.fieldWidth / 2, y: 360)
        let center = CGPoint(x: CGFloat(source.x), y: CGFloat(source.y))
        showAttackBurst(kind: kind, level: level, at: center, overdrive: overdrive)
    }

    private func showAttackBurst(
        kind: AttackItemKind,
        level: Int,
        at center: CGPoint,
        overdrive: Bool = false,
        heldForShowcase: Bool = false
    ) {
        while attackEffectsRoot.children.count >= GameArtCatalog.maximumConcurrentAttackEffects {
            guard let oldest = attackEffectsRoot.children.first else { break }
            oldest.removeAllActions()
            oldest.removeFromParent()
        }

        let color = UIColor(hex: GamePalette.attackHex(kind))
        let coreColor = UIColor(hex: GamePalette.attackCoreHex(kind))

        let burst = SKNode()
        burst.name = heldForShowcase
            ? "art-showcase-\(showcaseArgument(for: kind))"
            : "attack-\(kind.name)"
        burst.position = center
        burst.zPosition = 0
        attackEffectsRoot.addChild(burst)

        let raster = SKSpriteNode(texture: gameArt.attackTexture(for: kind))
        let clampedLevel = max(1, min(3, level))
        let rasterDiameter = overdrive ? CGFloat(164) : CGFloat(88 + clampedLevel * 12)
        raster.name = "raster"
        raster.size = CGSize(width: rasterDiameter, height: rasterDiameter)
        raster.alpha = reduceMotion ? (overdrive ? 0.68 : 0.52) : (overdrive ? 0.92 : 0.72)
        raster.blendMode = .add
        raster.zPosition = 0
        burst.addChild(raster)

        addAttackCue(kind: kind, color: color, coreColor: coreColor, to: burst)

        let glyph = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        glyph.text = overdrive ? "\(kind.badge) MAX" : kind.badge
        glyph.fontSize = overdrive ? 18 : 16
        glyph.fontColor = coreColor
        glyph.verticalAlignmentMode = .center
        glyph.zPosition = 2
        burst.addChild(glyph)

        let levelScale = overdrive ? 1.18 : 1 + CGFloat(clampedLevel - 1) * 0.10
        burst.setScale(levelScale)

        if overdrive {
            let ring = SKShapeNode(circleOfRadius: 44)
            ring.strokeColor = coreColor
            ring.fillColor = .clear
            ring.lineWidth = 4
            ring.glowWidth = reduceMotion ? 0 : 5
            ring.zPosition = 1
            burst.addChild(ring)
        }

        if heldForShowcase {
            return
        } else if reduceMotion {
            burst.run(.sequence([.wait(forDuration: GameMotion.normal), .removeFromParent()]))
        } else {
            burst.run(
                .sequence([
                    .group([
                        .scale(to: levelScale * 1.65, duration: GameMotion.slow),
                        .fadeOut(withDuration: GameMotion.slow)
                    ]),
                    .removeFromParent()
                ])
            )
        }
    }

    private func showLevelTransition(_ profile: DifficultyProfile) {
        let outline = SKShapeNode(
            rectOf: CGSize(width: 346, height: 256),
            cornerRadius: GameRadius.panel
        )
        outline.position = CGPoint(x: size.width / 2, y: 385)
        outline.fillColor = .clear
        outline.strokeColor = UIColor(hex: GamePalette.infoHex)
        outline.lineWidth = 2.5
        outline.glowWidth = reduceMotion ? 0 : 4
        outline.alpha = reduceMotion ? 0.72 : 0.88
        outline.zPosition = 0
        addGeneralEffect(outline)
        if reduceMotion {
            outline.run(
                .sequence([
                    .wait(forDuration: 0.42),
                    .fadeOut(withDuration: 0.20),
                    .removeFromParent()
                ])
            )
        } else {
            outline.setScale(0.96)
            outline.run(
                .sequence([
                    .group([
                        .scale(to: 1, duration: 0.24),
                        .sequence([
                            .wait(forDuration: 0.34),
                            .fadeOut(withDuration: 0.20)
                        ])
                    ]),
                    .removeFromParent()
                ])
            )
        }
        showFloatingText(
            "LEVEL \(profile.level) · SPEED \(Int(profile.entryBallSpeed))",
            color: UIColor(hex: GamePalette.infoHex)
        )
    }

    private func addGeneralEffect(_ node: SKNode) {
        while effectsRoot.children.count >= maximumConcurrentGeneralEffects {
            guard let oldest = effectsRoot.children.first else { break }
            oldest.removeAllActions()
            oldest.removeFromParent()
        }
        effectsRoot.addChild(node)
    }

    private func addAttackCue(
        kind: AttackItemKind,
        color: UIColor,
        coreColor: UIColor,
        to root: SKNode
    ) {
        let path = CGMutablePath()
        switch kind {
        case .lightning:
            path.move(to: CGPoint(x: -5, y: 30))
            path.addLine(to: CGPoint(x: 4, y: 18))
            path.move(to: CGPoint(x: 2, y: 15))
            path.addLine(to: CGPoint(x: -3, y: 4))
            path.move(to: CGPoint(x: -2, y: 1))
            path.addLine(to: CGPoint(x: 5, y: -12))
            path.move(to: CGPoint(x: 3, y: -15))
            path.addLine(to: CGPoint(x: -5, y: -30))
            path.move(to: CGPoint(x: 3, y: 16))
            path.addLine(to: CGPoint(x: 22, y: 8))
            path.addLine(to: CGPoint(x: 13, y: -1))
            path.move(to: CGPoint(x: -2, y: 3))
            path.addLine(to: CGPoint(x: -22, y: -6))
            path.addLine(to: CGPoint(x: -12, y: -16))
        case .flame:
            path.move(to: CGPoint(x: 0, y: -27))
            path.addCurve(
                to: CGPoint(x: 0, y: 29),
                control1: CGPoint(x: -10, y: 5),
                control2: CGPoint(x: -6, y: 18)
            )
            path.addCurve(
                to: CGPoint(x: 0, y: -27),
                control1: CGPoint(x: 13, y: 14),
                control2: CGPoint(x: 14, y: -7)
            )
            for offset: CGFloat in [-18, 18] {
                path.move(to: CGPoint(x: 0, y: -24))
                path.addQuadCurve(
                    to: CGPoint(x: offset, y: 14),
                    control: CGPoint(x: offset * 0.9, y: -5)
                )
            }

            for (position, radius) in [
                (CGPoint(x: -23, y: 21), CGFloat(3)),
                (CGPoint(x: 24, y: 10), CGFloat(2.5)),
                (CGPoint(x: -15, y: 31), CGFloat(2))
            ] {
                let ember = SKShapeNode(circleOfRadius: radius)
                ember.position = position
                ember.fillColor = coreColor
                ember.strokeColor = .clear
                root.addChild(ember)
            }
        case .wind:
            for offset: CGFloat in [-13, 0, 13] {
                path.move(to: CGPoint(x: -32, y: offset - 4))
                path.addQuadCurve(
                    to: CGPoint(x: 29, y: offset + 4),
                    control: CGPoint(x: 0, y: offset + 14)
                )
                path.addQuadCurve(
                    to: CGPoint(x: 18, y: offset - 5),
                    control: CGPoint(x: 29, y: offset - 8)
                )
            }
        case .pierce:
            path.move(to: CGPoint(x: -35, y: 0))
            path.addLine(to: CGPoint(x: 28, y: 0))
            path.move(to: CGPoint(x: 15, y: 11))
            path.addLine(to: CGPoint(x: 30, y: 0))
            path.addLine(to: CGPoint(x: 15, y: -11))
            path.move(to: CGPoint(x: -19, y: 17))
            path.addLine(to: CGPoint(x: 9, y: -17))
            path.move(to: CGPoint(x: -19, y: -17))
            path.addLine(to: CGPoint(x: 9, y: 17))
        }

        let cue = SKShapeNode(path: path)
        cue.strokeColor = color
        cue.fillColor = .clear
        cue.lineWidth = kind == .pierce ? 3.5 : 3
        cue.lineCap = .round
        cue.lineJoin = .round
        cue.glowWidth = reduceMotion ? 0 : 2.5
        cue.zPosition = 1
        root.addChild(cue)
    }

    private func showcaseArgument(for kind: AttackItemKind) -> String {
        switch kind {
        case .lightning: "lightning"
        case .flame: "flame"
        case .wind: "wind"
        case .pierce: "pierce"
        }
    }

#if DEBUG
    private func installArtShowcaseIfRequested(in view: SKView) {
        guard let artShowcaseKind else { return }

        showAttackBurst(
            kind: artShowcaseKind,
            level: 3,
            at: CGPoint(x: size.width / 2, y: 350),
            overdrive: artShowcaseOverdrive,
            heldForShowcase: true
        )

        artShowcaseAccessibilityMarker?.removeFromSuperview()
        let marker = UIView(frame: CGRect(x: 8, y: 8, width: 44, height: 44))
        marker.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        marker.isAccessibilityElement = true
        let suffix = artShowcaseOverdrive ? "-overdrive" : ""
        marker.accessibilityIdentifier = "artShowcase-\(showcaseArgument(for: artShowcaseKind))\(suffix)"
        marker.accessibilityLabel = artShowcaseOverdrive
            ? "\(artShowcaseKind.name) MAX overdrive showcase"
            : "\(artShowcaseKind.name) raster effect showcase"
        marker.accessibilityTraits = .image
        view.addSubview(marker)
        artShowcaseAccessibilityMarker = marker
    }
#endif

    private func showFloatingText(_ text: String, color: UIColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 20
        label.fontColor = color
        label.position = CGPoint(x: size.width / 2, y: 360)
        label.zPosition = 1
        addGeneralEffect(label)
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

}
