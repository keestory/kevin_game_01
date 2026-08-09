import SpriteKit
import UIKit

@MainActor
protocol TrainGameSceneDelegate: AnyObject {
    func gameScene(_ scene: GameScene, didEmit event: GameEvent)
}

@MainActor
final class GameScene: SKScene {
    weak var gameDelegate: TrainGameSceneDelegate?

    private let seed: UInt64
    private let difficulty: StageDifficulty
    private let countPlan: CountRunPlan
    private var flowState: CountFlowState
    private var snapshot = RunSnapshot()
    private var effectsRNG: SeededRandom
    private var stationArrayIndex = 0
    private var lastUpdateTime: TimeInterval = 0
    private var resultRemaining: TimeInterval = 0
    private var stationElapsedMillisecondsExact: Double = 0
    private var snapshotEmitRemaining: TimeInterval = 0
    private var stationResolved = false
    private var runFinished = false
    private var rescuePending = false
    private var reduceMotion = false
    private var exactStops = 0
    private var exactStreak = 0
    private var bestExactStreak = 0
    private var safeStops = 0

    private let worldRoot = SKNode()
    private let skylineLayer = SKNode()
    private let platformLayer = SKNode()
    private let platformCrowdLayer = SKNode()
    private let trainRoot = SKNode()
    private let interiorLayer = SKNode()
    private let trainArtworkLayer = SKNode()
    private let doorLayer = SKNode()
    private let passengerTransitLayer = SKNode()
    private let particleLayer = SKNode()
    private let countCardRoot = SKNode()
    private let countCard = SKShapeNode()
    private let masterSceneSprite = SKSpriteNode()
    private let targetLabel = SKLabelNode()
    private let currentLabel = SKLabelNode()
    private let statusLabel = SKLabelNode()
    private let resultLabel = SKLabelNode()
    private let trainShadow = SKShapeNode(ellipseOf: CGSize(width: 430, height: 54))
    private var trainSprite = SKSpriteNode()
    private var doorFrames: [SKShapeNode] = []
    private var doorLeftPanels: [SKShapeNode] = []
    private var doorRightPanels: [SKShapeNode] = []
    private var ambientStars: [SKShapeNode] = []
    private var passengerPool: [SKSpriteNode] = []

    private let trainSize = CGSize(width: 468, height: 198)
    private let trainCenter = CGPoint(x: 194, y: 449)
    private let doorOffsetsX: [CGFloat] = [-13, 61, 129, 186]
    private let doorSizes: [CGSize] = [
        CGSize(width: 42, height: 91),
        CGSize(width: 37, height: 82),
        CGSize(width: 32, height: 74),
        CGSize(width: 27, height: 65)
    ]

    private var stationPlan: StationCountPlan { countPlan.stations[stationArrayIndex] }

    init(size: CGSize, seed: UInt64, difficulty: StageDifficulty) {
        let generatedPlan = GameRules.countRunPlan(seed: seed, difficulty: difficulty)
        self.seed = seed
        self.difficulty = difficulty
        self.countPlan = generatedPlan
        self.flowState = GameRules.initialCountFlowState(for: generatedPlan.stations[0])
        self.effectsRNG = SeededRandom(seed: seed ^ 0xA5A5_A5A5_5A5A_5A5A)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = UIColor(hex: 0x07132C)

        snapshot.duration = 60
        snapshot.stage = difficulty.stage
        snapshot.targetScore = 3_000
        snapshot.targetExited = 3
        snapshot.stationCount = countPlan.stations.count
        snapshot.safetyHandles = difficulty.safetyHandles
        snapshot.assisted = difficulty.assisted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard worldRoot.parent == nil else { return }
        view.isMultipleTouchEnabled = false
        buildOwnerMasterWorld()
        prewarmPassengerPool(count: 36)
        configureStation(at: 0, animated: false)
        snapshot.phase = .playing
        emitSnapshot()
    }

    override func update(_ currentTime: TimeInterval) {
        guard snapshot.phase == .playing, !runFinished else { return }
        guard lastUpdateTime != 0 else {
            lastUpdateTime = currentTime
            return
        }

        let rawDelta = max(0, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime

        if snapshot.clockStarted {
            snapshot.elapsed = min(snapshot.duration, snapshot.elapsed + rawDelta)
            if snapshot.elapsed >= snapshot.duration, !stationResolved {
                resolveClose(observedRevision: snapshot.countRevision, timedOut: true)
            }
        }

        if stationResolved {
            resultRemaining = max(0, resultRemaining - rawDelta)
            if resultRemaining == 0 { advanceToNextStationOrFinish() }
        } else {
            stationElapsedMillisecondsExact += rawDelta * 1_000
            let targetMilliseconds = max(flowState.elapsedMilliseconds, Int(stationElapsedMillisecondsExact.rounded(.down)))
            let advance = GameRules.advanceFlow(
                state: flowState,
                throughMilliseconds: targetMilliseconds,
                plan: stationPlan
            )
            flowState = advance.state
            if !advance.appliedEvents.isEmpty {
                for event in advance.appliedEvents {
                    animateFlowEvent(event)
                    if event.direction == .exit {
                        snapshot.exited += event.passengerCount
                    } else {
                        snapshot.boarded += event.passengerCount
                    }
                }
                syncSnapshotFromFlow()
                emitSnapshot()
            } else {
                syncSnapshotFromFlow()
            }

            if flowState.phase == .boarding, !snapshot.clockStarted {
                snapshot.clockStarted = true
                emitSnapshot()
            }
            if flowState.phase == .timedOut {
                resolveClose(observedRevision: flowState.countRevision, timedOut: true)
            }
        }

        updateAmbientWorld()
        snapshotEmitRemaining -= rawDelta
        if snapshotEmitRemaining <= 0 {
            snapshotEmitRemaining = 0.08
            emitSnapshot()
        }
    }

    func closeDoors(observedRevision: Int) {
        resolveClose(observedRevision: observedRevision, timedOut: false)
    }

    /// 과거 자동화와의 컴파일 호환용. rev3에서는 제동이 아니라 문 닫기다.
    func applyBrake() {
        closeDoors(observedRevision: snapshot.countRevision)
    }

    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        if enabled {
            trainRoot.removeAction(forKey: "idle")
            trainRoot.position.y = 0
            particleLayer.removeAllChildren()
            ambientStars.forEach { $0.removeAllActions() }
        } else {
            runTrainIdle()
            animateStars()
        }
    }

    func setRunPaused(_ paused: Bool) {
        guard !runFinished, !rescuePending else { return }
        if paused, snapshot.phase == .playing {
            snapshot.phase = .paused
            isPaused = true
        } else if !paused, snapshot.phase == .paused {
            snapshot.phase = .playing
            lastUpdateTime = 0
            isPaused = false
        }
        emitSnapshot()
    }

    func acceptRescue() {
        guard rescuePending, !snapshot.rescueUsed, !runFinished else { return }
        rescuePending = false
        snapshot.rescueUsed = true
        snapshot.duration += 12
        snapshot.phase = .playing
        isPaused = false
        emitSnapshot()
    }

    func declineRescue() {
        guard rescuePending, !runFinished else { return }
        rescuePending = false
        isPaused = false
        finish(completed: false)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), point.y < 175 else { return }
        closeDoors(observedRevision: snapshot.countRevision)
    }

    private func configureStation(at index: Int, animated: Bool) {
        stationArrayIndex = index
        flowState = GameRules.initialCountFlowState(for: stationPlan)
        stationResolved = false
        stationElapsedMillisecondsExact = 0
        resultRemaining = 0
        snapshot.stopIndex = stationPlan.index
        snapshot.station = stationPlan.index
        snapshot.lastCloseDelta = nil
        snapshot.lastBrakeGrade = nil
        snapshot.doorsOpen = true
        snapshot.canBrake = false
        resultLabel.alpha = 0
        syncSnapshotFromFlow()
        openAllDoors(animated: animated)
        rebuildAmbientPlatformCrowd()
        if animated { animateStationArrival() }
        updateCountCard()
        emitSnapshot()
    }

    private func syncSnapshotFromFlow() {
        snapshot.onboardCount = flowState.onboardCount
        snapshot.targetOnboardCount = stationPlan.targetOnboard
        snapshot.countRevision = flowState.countRevision
        snapshot.flowPhase = flowState.phase
        snapshot.canCloseDoors = flowState.phase == .boarding && !stationResolved
        snapshot.canBrake = snapshot.canCloseDoors
        snapshot.flowProgress = min(
            1,
            max(0, Double(flowState.elapsedMilliseconds) / Double(max(1, stationPlan.deadlineMilliseconds)))
        )
        updateCountCard()
    }

    private func resolveClose(observedRevision: Int, timedOut: Bool) {
        guard snapshot.phase == .playing, !stationResolved, snapshot.canCloseDoors || timedOut else { return }
        let resolution = GameRules.resolveDoorClose(
            state: flowState,
            plan: stationPlan,
            observedCountRevision: observedRevision
        )
        guard resolution.result != .stale else {
            syncSnapshotFromFlow()
            showResult("인원이 바뀌었어요 · 다시 확인", color: UIColor(hex: 0xFFD15A))
            emitSnapshot()
            return
        }
        guard resolution.shouldCloseDoors else { return }

        stationResolved = true
        snapshot.canCloseDoors = false
        snapshot.canBrake = false
        snapshot.doorsOpen = false
        let delta = resolution.onboardCount - resolution.targetOnboardCount
        snapshot.lastCloseDelta = delta
        closeAllDoors(animated: true)
        resultRemaining = reduceMotion ? 0.9 : 1.8

        switch resolution.result {
        case .exact:
            exactStops += 1
            exactStreak += 1
            bestExactStreak = max(bestExactStreak, exactStreak)
            snapshot.currentChain = exactStops
            snapshot.bestChain = bestExactStreak
            snapshot.score += 1_000 + max(0, exactStreak - 1) * 250
            snapshot.lastBrakeGrade = .perfect
            let streakText = exactStreak >= 2 ? " · 정확 ×\(exactStreak)" : ""
            showResult("정원 딱 맞음!\(streakText)", color: UIColor(hex: 0x54D69B))
            celebrateExact()
            gameDelegate?.gameScene(self, didEmit: .perfect)
        case .under(let count):
            exactStreak = 0
            if count == 1 {
                safeStops += 1
                snapshot.score += 400
                snapshot.lastBrakeGrade = .safe
                gameDelegate?.gameScene(self, didEmit: .match(1))
            } else {
                snapshot.lastBrakeGrade = .missed
                gameDelegate?.gameScene(self, didEmit: .overflow)
            }
            showResult("\(count)자리 비었어요 · \(resolution.onboardCount)/\(resolution.targetOnboardCount)", color: UIColor(hex: 0x67A9FF))
        case .over(let count):
            exactStreak = 0
            if count == 1 {
                safeStops += 1
                snapshot.score += 400
                snapshot.lastBrakeGrade = .safe
                gameDelegate?.gameScene(self, didEmit: .match(1))
            } else {
                snapshot.lastBrakeGrade = .missed
                gameDelegate?.gameScene(self, didEmit: .overflow)
            }
            showResult("\(count)명 초과했어요 · \(resolution.onboardCount)/\(resolution.targetOnboardCount)", color: UIColor(hex: 0xFF7868))
        case .stale:
            break
        }
        if timedOut {
            statusLabel.text = "안전을 위해 자동으로 닫았어요"
        }
        emitSnapshot()
    }

    private func advanceToNextStationOrFinish() {
        if stationArrayIndex + 1 < countPlan.stations.count {
            configureStation(at: stationArrayIndex + 1, animated: true)
        } else {
            finish(completed: exactStops >= 3)
        }
    }

    private func finish(completed: Bool) {
        guard !runFinished else { return }
        runFinished = true
        snapshot.phase = .finished
        snapshot.canCloseDoors = false
        snapshot.canBrake = false
        isUserInteractionEnabled = false
        let result = RunResult(
            score: snapshot.score,
            boarded: snapshot.boarded,
            exited: snapshot.exited,
            bestChain: bestExactStreak,
            completed: completed,
            dailySeed: seed,
            stage: snapshot.stage,
            targetScore: snapshot.targetScore,
            rescueUsed: snapshot.rescueUsed,
            assisted: snapshot.assisted
        )
        emitSnapshot()
        gameDelegate?.gameScene(self, didEmit: .finished(result))
    }

    private func buildNightWorld() {
        worldRoot.zPosition = -100
        addChild(worldRoot)
        for (color, y, height) in [(0x07132C as UInt, 0.0, 0.36), (0x0A2140, 0.36, 0.32), (0x153C59, 0.68, 0.32)] {
            let band = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: size.height * height + 2))
            band.position = CGPoint(x: size.width / 2, y: size.height * (y + height / 2))
            band.fillColor = UIColor(hex: color)
            band.strokeColor = .clear
            band.zPosition = -120
            worldRoot.addChild(band)
        }

        skylineLayer.zPosition = -90
        worldRoot.addChild(skylineLayer)
        for index in 0..<12 {
            let width = CGFloat(30 + index % 4 * 9)
            let height = CGFloat(92 + index % 5 * 25)
            let building = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 4)
            building.position = CGPoint(x: CGFloat(index) * 38 - 10, y: 408 + height / 2)
            building.fillColor = UIColor(hex: [0x102744, 0x153251, 0x173A58][index % 3])
            building.strokeColor = UIColor.white.withAlphaComponent(0.05)
            skylineLayer.addChild(building)
            for row in 0..<4 {
                for column in 0..<2 where (row + column + index).isMultiple(of: 2) {
                    let window = SKShapeNode(rectOf: CGSize(width: 4, height: 7), cornerRadius: 1)
                    window.position = CGPoint(x: -7 + CGFloat(column) * 14, y: -height * 0.28 + CGFloat(row) * 19)
                    window.fillColor = UIColor(hex: [0xFFD36B, 0x61E5D1, 0x6AA7FF][(row + index) % 3], alpha: 0.58)
                    window.strokeColor = .clear
                    building.addChild(window)
                }
            }
        }

        for index in 0..<18 {
            let star = SKShapeNode(circleOfRadius: CGFloat(index % 3 + 1) * 0.65)
            star.position = CGPoint(x: CGFloat((index * 61) % 390), y: CGFloat(575 + (index * 43) % 215))
            star.fillColor = UIColor(hex: [0x61E5D1, 0x7AB0FF, 0xFFD36B][index % 3], alpha: 0.72)
            star.strokeColor = .clear
            star.zPosition = -80
            ambientStars.append(star)
            worldRoot.addChild(star)
        }
        animateStars()

        let canopy = SKShapeNode(rectOf: CGSize(width: size.width + 30, height: 18), cornerRadius: 7)
        canopy.position = CGPoint(x: size.width / 2, y: 620)
        canopy.fillColor = UIColor(hex: 0x203653)
        canopy.strokeColor = UIColor(hex: 0x61E5D1, alpha: 0.22)
        canopy.glowWidth = 4
        canopy.zPosition = -40
        worldRoot.addChild(canopy)
    }

    /// The owner-approved reference is the runtime composition contract.
    /// Dynamic passengers, count feedback, and effects are layered above it.
    private func buildOwnerMasterWorld() {
        worldRoot.zPosition = -100
        addChild(worldRoot)

        let texture = SKTexture(imageNamed: "OwnerMasterScene")
        texture.filteringMode = .linear
        let sourceSize = texture.size()
        let scale = max(
            size.width / max(1, sourceSize.width),
            size.height / max(1, sourceSize.height)
        )
        masterSceneSprite.texture = texture
        masterSceneSprite.size = CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
        masterSceneSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        masterSceneSprite.zPosition = -120
        worldRoot.addChild(masterSceneSprite)

        passengerTransitLayer.zPosition = 20
        worldRoot.addChild(passengerTransitLayer)
        particleLayer.zPosition = 80
        worldRoot.addChild(particleLayer)

        resultLabel.fontName = "AppleSDGothicNeo-Heavy"
        resultLabel.fontSize = 22
        resultLabel.position = CGPoint(x: size.width / 2, y: 585)
        resultLabel.zPosition = 90
        resultLabel.alpha = 0
        worldRoot.addChild(resultLabel)
    }

    private func buildPlatform() {
        platformLayer.zPosition = -10
        worldRoot.addChild(platformLayer)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -40, y: 345))
        path.addLine(to: CGPoint(x: size.width + 28, y: 322))
        path.addLine(to: CGPoint(x: size.width + 40, y: 122))
        path.addLine(to: CGPoint(x: -40, y: 144))
        path.closeSubpath()
        let platform = SKShapeNode(path: path)
        platform.fillColor = UIColor(hex: 0x26344A)
        platform.strokeColor = UIColor(hex: 0x7B91A6, alpha: 0.35)
        platform.lineWidth = 2
        platformLayer.addChild(platform)

        let edgePath = CGMutablePath()
        edgePath.move(to: CGPoint(x: -20, y: 337))
        edgePath.addLine(to: CGPoint(x: size.width + 20, y: 314))
        let edge = SKShapeNode(path: edgePath)
        edge.strokeColor = UIColor(hex: 0xFFD15A)
        edge.lineWidth = 10
        edge.glowWidth = 2
        platformLayer.addChild(edge)

        platformCrowdLayer.zPosition = 30
        worldRoot.addChild(platformCrowdLayer)
        particleLayer.zPosition = 80
        worldRoot.addChild(particleLayer)
    }

    private func buildTrain() {
        trainRoot.zPosition = 10
        worldRoot.addChild(trainRoot)
        trainShadow.position = CGPoint(x: trainCenter.x + 8, y: trainCenter.y - 88)
        trainShadow.fillColor = UIColor.black.withAlphaComponent(0.48)
        trainShadow.strokeColor = .clear
        trainRoot.addChild(trainShadow)

        interiorLayer.zPosition = 1
        trainRoot.addChild(interiorLayer)
        for index in 0..<4 {
            let interior = SKShapeNode(rectOf: CGSize(width: doorSizes[index].width - 4, height: doorSizes[index].height - 5), cornerRadius: 7)
            interior.position = doorPosition(index)
            interior.fillColor = UIColor(hex: 0x231910)
            interior.strokeColor = UIColor(hex: 0xFFCE82, alpha: 0.35)
            interior.glowWidth = 8
            interiorLayer.addChild(interior)
        }

        trainArtworkLayer.zPosition = 5
        trainRoot.addChild(trainArtworkLayer)
        trainSprite = SKSpriteNode(imageNamed: "DioramaTrain")
        trainSprite.position = trainCenter
        trainSprite.size = trainSize
        trainSprite.texture?.filteringMode = .linear
        trainArtworkLayer.addChild(trainSprite)

        doorLayer.zPosition = 8
        trainRoot.addChild(doorLayer)
        for index in 0..<4 {
            let size = doorSizes[index]
            let position = doorPosition(index)
            let frame = SKShapeNode(rectOf: CGSize(width: size.width + 5, height: size.height + 6), cornerRadius: 8)
            frame.position = position
            frame.fillColor = UIColor(hex: 0xFFD78A, alpha: 0.08)
            frame.strokeColor = UIColor(hex: 0x61E5D1, alpha: 0.42)
            frame.lineWidth = 2
            frame.glowWidth = 4
            doorLayer.addChild(frame)
            doorFrames.append(frame)

            let panelWidth = size.width / 2 - 1
            let left = makeDoorPanel(size: CGSize(width: panelWidth, height: size.height - 3))
            left.position = CGPoint(x: position.x - panelWidth / 2, y: position.y)
            doorLayer.addChild(left)
            doorLeftPanels.append(left)
            let right = makeDoorPanel(size: CGSize(width: panelWidth, height: size.height - 3))
            right.position = CGPoint(x: position.x + panelWidth / 2, y: position.y)
            doorLayer.addChild(right)
            doorRightPanels.append(right)
        }
        passengerTransitLayer.zPosition = 14
        trainRoot.addChild(passengerTransitLayer)
        runTrainIdle()
    }

    private func buildCountCard() {
        countCardRoot.position = CGPoint(x: size.width / 2, y: 660)
        countCardRoot.zPosition = 40
        worldRoot.addChild(countCardRoot)
        countCard.path = CGPath(roundedRect: CGRect(x: -150, y: -37, width: 300, height: 74), cornerWidth: 25, cornerHeight: 25, transform: nil)
        countCard.fillColor = UIColor(hex: 0x0A1936, alpha: 0.93)
        countCard.strokeColor = UIColor(hex: 0xFFD15A, alpha: 0.72)
        countCard.lineWidth = 3
        countCardRoot.addChild(countCard)

        targetLabel.fontName = "AppleSDGothicNeo-Heavy"
        targetLabel.fontSize = 18
        targetLabel.horizontalAlignmentMode = .left
        targetLabel.position = CGPoint(x: -126, y: -7)
        targetLabel.fontColor = UIColor(hex: 0xFFD15A)
        countCardRoot.addChild(targetLabel)
        currentLabel.fontName = "AppleSDGothicNeo-Heavy"
        currentLabel.fontSize = 32
        currentLabel.horizontalAlignmentMode = .right
        currentLabel.position = CGPoint(x: 126, y: -11)
        countCardRoot.addChild(currentLabel)

        statusLabel.fontName = "AppleSDGothicNeo-Bold"
        statusLabel.fontSize = 17
        statusLabel.position = CGPoint(x: size.width / 2, y: 607)
        statusLabel.zPosition = 45
        worldRoot.addChild(statusLabel)
        resultLabel.fontName = "AppleSDGothicNeo-Heavy"
        resultLabel.fontSize = 21
        resultLabel.position = CGPoint(x: size.width / 2, y: 576)
        resultLabel.zPosition = 70
        resultLabel.alpha = 0
        worldRoot.addChild(resultLabel)
    }

    private func updateCountCard() {
        targetLabel.text = "목표  \(stationPlan.targetOnboard)명"
        currentLabel.text = "현재 \(flowState.onboardCount)명"
        let isExact = flowState.onboardCount == stationPlan.targetOnboard
        currentLabel.fontColor = isExact ? UIColor(hex: 0x54D69B) : .white
        countCard.strokeColor = isExact ? UIColor(hex: 0x54D69B) : UIColor(hex: 0xFFD15A, alpha: 0.72)
        countCard.glowWidth = isExact ? 10 : 2
        statusLabel.text = switch flowState.phase {
        case .automaticExit: "승객이 내리는 중 · 잠시 기다려요"
        case .boarding: isExact ? "지금! 문을 닫으세요" : "현재와 목표가 같아질 때 문 닫기"
        case .doorsClosed: "안전 확인 · 출발 준비"
        case .timedOut: "안전을 위해 자동으로 닫아요"
        }
        statusLabel.fontColor = isExact ? UIColor(hex: 0x54D69B) : UIColor.white.withAlphaComponent(0.78)
    }

    private func makeDoorPanel(size: CGSize) -> SKShapeNode {
        let panel = SKShapeNode(rectOf: size, cornerRadius: 3)
        panel.fillColor = UIColor(hex: 0x263D65)
        panel.strokeColor = UIColor(hex: 0x61E5D1, alpha: 0.46)
        panel.lineWidth = 1.2
        return panel
    }

    private func openAllDoors(animated: Bool) {
        for index in doorLeftPanels.indices {
            let distance = doorSizes[index].width * 0.42
            let duration = animated && !reduceMotion ? 0.22 : 0
            doorLeftPanels[index].run(.group([
                eased(.moveBy(x: -distance, y: 0, duration: duration), mode: .easeOut),
                .fadeAlpha(to: 0, duration: duration)
            ]))
            doorRightPanels[index].run(.group([
                eased(.moveBy(x: distance, y: 0, duration: duration), mode: .easeOut),
                .fadeAlpha(to: 0, duration: duration)
            ]))
            doorFrames[index].fillColor = UIColor(hex: 0xFFD78A, alpha: 0.10)
        }
    }

    private func closeAllDoors(animated: Bool) {
        for index in doorLeftPanels.indices {
            let position = doorPosition(index)
            let panelWidth = doorSizes[index].width / 2 - 1
            let duration = animated && !reduceMotion ? 0.24 : 0
            doorLeftPanels[index].run(.group([
                eased(.move(to: CGPoint(x: position.x - panelWidth / 2, y: position.y), duration: duration), mode: .easeIn),
                .fadeAlpha(to: 1, duration: duration)
            ]))
            doorRightPanels[index].run(.group([
                eased(.move(to: CGPoint(x: position.x + panelWidth / 2, y: position.y), duration: duration), mode: .easeIn),
                .fadeAlpha(to: 1, duration: duration)
            ]))
            doorFrames[index].fillColor = .clear
        }
    }

    private func prewarmPassengerPool(count: Int) {
        for index in 0..<count {
            let sprite = makePassengerSprite(archetype: index % 8, height: 50)
            sprite.isHidden = true
            passengerTransitLayer.addChild(sprite)
            passengerPool.append(sprite)
        }
    }

    private func acquirePassenger(archetype: Int, height: CGFloat) -> SKSpriteNode? {
        guard let sprite = passengerPool.first(where: \.isHidden) else { return nil }
        sprite.texture = passengerTexture(archetype: archetype)
        sprite.size = CGSize(width: height * 0.42, height: height)
        sprite.alpha = 1
        sprite.setScale(1)
        sprite.removeAllActions()
        sprite.isHidden = false
        return sprite
    }

    private func releasePassenger(_ sprite: SKSpriteNode) {
        sprite.removeAllActions()
        sprite.isHidden = true
        sprite.position = .zero
    }

    private func animateFlowEvent(_ event: PassengerFlowEvent) {
        for passengerIndex in 0..<event.passengerCount {
            guard let passenger = acquirePassenger(
                archetype: Int((event.visualSeed + UInt64(passengerIndex)) % 8),
                height: CGFloat(72 + passengerIndex % 3 * 5)
            ) else { continue }
            let doorIndex = (event.id + passengerIndex) % 4
            let door = doorPosition(doorIndex)
            let doorThreshold = CGPoint(
                x: door.x,
                y: door.y - doorSizes[doorIndex].height * 0.43
            )
            let platformPoint = CGPoint(
                x: CGFloat(44 + ((event.id * 67 + passengerIndex * 31) % 300)),
                y: CGFloat(232 + ((event.id + passengerIndex) % 3) * 20)
            )
            let platformInTrain = platformPoint
            // Domain events are authoritative threshold crossings. Start the
            // visual at that same threshold so the visible count never leads it.
            passenger.position = doorThreshold
            passenger.setScale(0.82)

            let movement: SKAction
            if event.direction == .exit {
                movement = .group([
                    eased(.move(to: platformInTrain, duration: reduceMotion ? 0.10 : 0.58), mode: .easeOut),
                    eased(.scale(to: 1.0, duration: reduceMotion ? 0.10 : 0.58), mode: .easeOut)
                ])
            } else {
                movement = .group([
                    eased(.move(to: CGPoint(x: door.x, y: door.y + 5), duration: reduceMotion ? 0.10 : 0.34), mode: .easeIn),
                    .fadeOut(withDuration: reduceMotion ? 0.10 : 0.34),
                    eased(.scale(to: 0.68, duration: reduceMotion ? 0.10 : 0.34), mode: .easeIn)
                ])
            }
            passenger.run(.sequence([
                movement,
                .run { [weak self, weak passenger] in
                    guard let self, let passenger else { return }
                    self.releasePassenger(passenger)
                }
            ]))
        }
    }

    private func buildAmbientPlatformCrowd() {
        rebuildAmbientPlatformCrowd()
    }

    private func rebuildAmbientPlatformCrowd() {
        platformCrowdLayer.removeAllChildren()
        for index in 0..<14 {
            let passenger = makePassengerSprite(archetype: (stationArrayIndex * 3 + index) % 8, height: CGFloat(72 + index % 3 * 9))
            passenger.position = CGPoint(x: CGFloat(18 + (index * 59) % 362), y: CGFloat(178 + (index % 4) * 28))
            passenger.zPosition = CGFloat(index % 4)
            passenger.alpha = index < 8 ? 1 : 0.72
            platformCrowdLayer.addChild(passenger)
        }
    }

    private func passengerTexture(archetype: Int) -> SKTexture {
        let sheet = SKTexture(imageNamed: "CommuterSheet")
        sheet.filteringMode = .linear
        let width = 1.0 / 8.0
        let texture = SKTexture(rect: CGRect(x: CGFloat(archetype % 8) * width, y: 0, width: width, height: 1), in: sheet)
        texture.filteringMode = .linear
        return texture
    }

    private func makePassengerSprite(archetype: Int, height: CGFloat) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: passengerTexture(archetype: archetype))
        sprite.size = CGSize(width: height * 0.42, height: height)
        return sprite
    }

    private func celebrateExact() {
        guard !reduceMotion else { return }
        for index in 0..<18 {
            let particle = SKShapeNode(circleOfRadius: CGFloat(2 + index % 3))
            particle.position = CGPoint(x: size.width / 2, y: 560)
            particle.fillColor = [UIColor(hex: 0x54D69B), UIColor(hex: 0xFFD15A), .white][index % 3]
            particle.strokeColor = .clear
            particle.glowWidth = 3
            particleLayer.addChild(particle)
            let angle = Double(index) / 18 * .pi * 2
            let distance = effectsRNG.double(in: 42...105)
            particle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.52),
                    .fadeOut(withDuration: 0.52)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func showResult(_ text: String, color: UIColor) {
        resultLabel.removeAllActions()
        resultLabel.text = text
        resultLabel.fontColor = color
        resultLabel.alpha = 1
        if !reduceMotion {
            resultLabel.setScale(0.82)
            resultLabel.run(eased(.scale(to: 1, duration: 0.16), mode: .easeOut))
        }
    }

    private func animateStationArrival() {
        guard !reduceMotion else { return }
        masterSceneSprite.alpha = 0.86
        masterSceneSprite.run(.fadeAlpha(to: 1, duration: 0.34))
    }

    private func runTrainIdle() {
        guard !reduceMotion, trainRoot.action(forKey: "idle") == nil else { return }
        trainRoot.run(.repeatForever(.sequence([
            eased(.moveBy(x: 0, y: 1.5, duration: 0.70), mode: .easeInEaseOut),
            eased(.moveBy(x: 0, y: -1.5, duration: 0.70), mode: .easeInEaseOut)
        ])), withKey: "idle")
    }

    private func animateStars() {
        guard !reduceMotion else { return }
        for (index, star) in ambientStars.enumerated() where star.action(forKey: "twinkle") == nil {
            star.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.22, duration: 0.7 + Double(index % 4) * 0.18),
                .fadeAlpha(to: 0.82, duration: 0.8 + Double(index % 3) * 0.16)
            ])), withKey: "twinkle")
        }
    }

    private func updateAmbientWorld() {
        guard !reduceMotion else { return }
        skylineLayer.position.x = sin(snapshot.elapsed * 0.09) * 2
    }

    private func doorPosition(_ index: Int) -> CGPoint {
        let xPositions: [CGFloat] = [166, 235, 293, 347]
        let yPositions: [CGFloat] = [424, 420, 416, 412]
        return CGPoint(
            x: xPositions[min(max(0, index), xPositions.count - 1)],
            y: yPositions[min(max(0, index), yPositions.count - 1)]
        )
    }

    private func eased(_ action: SKAction, mode: SKActionTimingMode) -> SKAction {
        action.timingMode = mode
        return action
    }

    private func emitSnapshot() {
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
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
