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
    private var passengerRNG: SeededRandom
    private var effectsRNG: SeededRandom
    private var snapshot = RunSnapshot()
    private var currentPlan: StationPlan!
    private var lastUpdateTime: TimeInterval = 0
    private var approachElapsed: TimeInterval = 0
    private var resolutionRemaining: TimeInterval = 0
    private var runFinished = false
    private var rescuePending = false
    private var reduceMotion = false

    private let worldRoot = SKNode()
    private let farCityLayer = SKNode()
    private let tunnelLayer = SKNode()
    private let platformRoot = SKNode()
    private let waitingPassengerLayer = SKNode()
    private let trainRoot = SKNode()
    private let onboardPassengerLayer = SKNode()
    private let transitPassengerLayer = SKNode()
    private let particleLayer = SKNode()
    private let stationNameLabel = SKLabelNode()
    private let resultLabel = SKLabelNode()
    private let cabinGlow = SKShapeNode()
    private let routeDisplay = SKLabelNode()
    private var doorPanels: [(left: SKShapeNode, right: SKShapeNode)] = []
    private var sleepers: [SKShapeNode] = []
    private var tunnelPillars: [SKShapeNode] = []
    private var speedLines: [SKShapeNode] = []

    private var isResolvingStop: Bool { resolutionRemaining > 0 }
    private var stationCycleDuration: TimeInterval { 12 }
    private var trainBodyCenterY: CGFloat { max(365, size.height * 0.47) }
    private var trainBodyWidth: CGFloat { min(366, size.width - 24) }

    init(size: CGSize, seed: UInt64, difficulty: StageDifficulty) {
        self.seed = seed
        self.difficulty = difficulty
        self.passengerRNG = SeededRandom(seed: seed)
        self.effectsRNG = SeededRandom(seed: seed ^ 0xA5A5_A5A5_5A5A_5A5A)
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = UIColor(hex: 0x10182C)

        snapshot.duration = difficulty.duration
        snapshot.stage = difficulty.stage
        snapshot.targetScore = difficulty.targetScore
        snapshot.targetExited = difficulty.targetExited
        snapshot.stationCount = difficulty.stationCount
        snapshot.safetyHandles = difficulty.safetyHandles
        snapshot.assisted = difficulty.assisted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard worldRoot.parent == nil else { return }
        view.isMultipleTouchEnabled = false
        buildWorld()
        buildPlatform()
        buildTrain()
        buildOverlayLabels()
        refillOnboardPassengers()
        beginStation(index: 1)
        snapshot.phase = .playing
        emitSnapshot()
    }

    override func update(_ currentTime: TimeInterval) {
        guard snapshot.phase == .playing, !runFinished else { return }
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let rawDelta = max(0, currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        let frameDelta = min(rawDelta, 1.0 / 30.0)
        // 첫 운행은 열차가 실제 제동 가능 구간에 진입하기 전까지 60초를 차감하지 않는다.
        let clockIsActive = snapshot.stopIndex > 1
            || isResolvingStop
            || approachElapsed >= currentPlan.approachDuration * 0.12
        if clockIsActive {
            snapshot.elapsed = min(snapshot.duration, snapshot.elapsed + frameDelta)
        }

        if isResolvingStop {
            resolutionRemaining = max(0, resolutionRemaining - frameDelta)
            updateScenery(delta: frameDelta, speedScale: 0.12)
            if resolutionRemaining == 0 {
                completeStation()
            }
        } else {
            approachElapsed += frameDelta
            let progress = approachElapsed / max(0.1, currentPlan.approachDuration)
            snapshot.approachProgress = min(1.15, max(0, progress))
            snapshot.canBrake = progress >= 0.12 && progress <= 1.10
            updateScenery(delta: frameDelta, speedScale: currentPlan.speedScale)
            updateApproachVisuals(progress: progress)

            if progress > 1.10 {
                resolveCurrentStop(tappedAt: nil)
            }
        }

        if !reduceMotion {
            trainRoot.position.y = sin(snapshot.elapsed * 8.5) * 1.4
        }
        emitSnapshot()
    }

    func applyBrake() {
        guard snapshot.phase == .playing,
              snapshot.canBrake,
              !isResolvingStop,
              !runFinished else { return }
        resolveCurrentStop(tappedAt: approachElapsed)
    }

    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        farCityLayer.isHidden = enabled
        speedLines.forEach { $0.isHidden = enabled }
        if enabled { trainRoot.position.y = 0 }
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
        snapshot.stationCount += 1
        snapshot.duration += stationCycleDuration
        snapshot.phase = .playing
        isPaused = false
        isUserInteractionEnabled = true
        beginStation(index: snapshot.stopIndex + 1)
        showFloatingText("추가 역 운행 · 한 번 더!", color: UIColor(hex: 0x36D6A0))
        lastUpdateTime = 0
        emitSnapshot()
    }

    func declineRescue() {
        guard rescuePending, !runFinished else { return }
        rescuePending = false
        isPaused = false
        finish(completed: false)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self), point.y < size.height * 0.34 else { return }
        applyBrake()
    }

    private func beginStation(index: Int) {
        snapshot.stopIndex = index
        snapshot.station = index
        snapshot.approachProgress = 0
        snapshot.canBrake = false
        snapshot.doorsOpen = false
        snapshot.lastBrakeGrade = nil
        approachElapsed = 0
        resolutionRemaining = 0
        currentPlan = GameRules.stationPlan(index: index, difficulty: difficulty)
        waitingPassengerLayer.isHidden = true

        platformRoot.removeAllActions()
        platformRoot.position.x = size.width * 0.92
        stationNameLabel.text = currentPlan.name
        routeDisplay.text = "정위치 급행 · 1호차"
        resultLabel.alpha = 0
        closeDoors(animated: false)
        rebuildWaitingPassengers(count: currentPlan.boardDemand)
    }

    private func resolveCurrentStop(tappedAt: TimeInterval?) {
        guard !isResolvingStop, !runFinished else { return }
        let resolution = GameRules.resolveBrake(tappedAt: tappedAt, plan: currentPlan)
        snapshot.canBrake = false
        snapshot.lastBrakeGrade = resolution.grade
        snapshot.exited += resolution.exitedCount
        snapshot.boarded += currentPlan.boardDemand
        snapshot.score += resolution.scoreGained
        snapshot.lastWasPerfect = resolution.grade == .perfect

        if resolution.grade == .perfect {
            snapshot.currentChain += 1
            snapshot.bestChain = max(snapshot.bestChain, snapshot.currentChain)
            gameDelegate?.gameScene(self, didEmit: .perfect)
        } else {
            snapshot.currentChain = 0
        }

        if resolution.grade == .missed {
            snapshot.safetyHandles = max(0, snapshot.safetyHandles - 1)
            gameDelegate?.gameScene(self, didEmit: .overflow)
        } else if resolution.grade != .perfect {
            gameDelegate?.gameScene(self, didEmit: .match(resolution.exitedCount))
        }

        let minimumResolution = resolution.grade == .missed ? 3.2 : 4.0
        resolutionRemaining = max(minimumResolution, stationCycleDuration - approachElapsed)
        animateBrake(resolution)
        emitSnapshot()
    }

    private func completeStation() {
        closeDoors(animated: true)
        refillOnboardPassengers()

        if snapshot.stopIndex >= snapshot.stationCount {
            snapshot.elapsed = snapshot.duration
            let completed = snapshot.exited >= snapshot.targetExited
            if completed {
                finish(completed: true)
            } else {
                requestRescueOrFinish()
            }
        } else {
            beginStation(index: snapshot.stopIndex + 1)
        }
    }

    private func requestRescueOrFinish() {
        let gap = max(0, snapshot.targetExited - snapshot.exited)
        guard !snapshot.rescueUsed, gap <= 8 else {
            finish(completed: false)
            return
        }
        rescuePending = true
        snapshot.phase = .awaitingRescue
        isPaused = true
        emitSnapshot()
        gameDelegate?.gameScene(self, didEmit: .rescueRequested)
    }

    private func finish(completed: Bool) {
        guard !runFinished else { return }
        runFinished = true
        snapshot.phase = .finished
        isUserInteractionEnabled = false
        let result = RunResult(
            score: snapshot.score,
            boarded: snapshot.boarded,
            exited: snapshot.exited,
            bestChain: snapshot.bestChain,
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

    private func buildWorld() {
        worldRoot.zPosition = -100
        addChild(worldRoot)

        farCityLayer.zPosition = -100
        worldRoot.addChild(farCityLayer)
        for index in 0..<9 {
            let width = CGFloat(44 + (index % 3) * 18)
            let height = CGFloat(90 + (index % 4) * 28)
            let building = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 6)
            building.position = CGPoint(x: CGFloat(index) * 76 - 36, y: trainBodyCenterY + 84)
            building.fillColor = UIColor(hex: [0x15213A, 0x192A49, 0x1D3153][index % 3])
            building.strokeColor = UIColor.white.withAlphaComponent(0.04)
            farCityLayer.addChild(building)

            for row in 0..<3 {
                for column in 0..<2 where (row + column + index).isMultiple(of: 2) {
                    let light = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 2)
                    light.position = CGPoint(
                        x: -width * 0.20 + CGFloat(column) * width * 0.38,
                        y: -height * 0.28 + CGFloat(row) * 24
                    )
                    light.fillColor = UIColor(hex: row.isMultiple(of: 2) ? 0xFFD84D : 0x7B9CFF).withAlphaComponent(0.42)
                    light.strokeColor = .clear
                    building.addChild(light)
                }
            }
        }

        tunnelLayer.zPosition = -80
        worldRoot.addChild(tunnelLayer)
        for index in 0..<6 {
            let pillar = SKShapeNode(rectOf: CGSize(width: 18, height: size.height * 0.60), cornerRadius: 6)
            pillar.position = CGPoint(x: CGFloat(index) * 94, y: size.height * 0.48)
            pillar.fillColor = UIColor(hex: 0x26344C)
            pillar.strokeColor = UIColor(hex: 0x4A5C75).withAlphaComponent(0.35)
            tunnelLayer.addChild(pillar)
            tunnelPillars.append(pillar)
        }

        for index in 0..<8 {
            let line = SKShapeNode(rectOf: CGSize(width: 42, height: 2), cornerRadius: 1)
            line.position = CGPoint(x: CGFloat(index) * 68, y: CGFloat(510 + (index % 4) * 38))
            line.fillColor = UIColor(hex: index.isMultiple(of: 2) ? 0x36D6A0 : 0x7B9CFF).withAlphaComponent(0.34)
            line.strokeColor = .clear
            worldRoot.addChild(line)
            speedLines.append(line)
        }

        let railA = SKShapeNode(rectOf: CGSize(width: size.width + 40, height: 6), cornerRadius: 3)
        railA.position = CGPoint(x: size.width / 2, y: trainBodyCenterY - 135)
        railA.fillColor = UIColor(hex: 0x9AA7B4)
        railA.strokeColor = .clear
        worldRoot.addChild(railA)

        let railB = railA.copy() as! SKShapeNode
        railB.position.y -= 34
        worldRoot.addChild(railB)

        for index in 0..<12 {
            let sleeper = SKShapeNode(rectOf: CGSize(width: 11, height: 62), cornerRadius: 3)
            sleeper.position = CGPoint(x: CGFloat(index) * 38, y: trainBodyCenterY - 151)
            sleeper.zRotation = .pi / 2
            sleeper.fillColor = UIColor(hex: 0x4A4038)
            sleeper.strokeColor = .clear
            worldRoot.addChild(sleeper)
            sleepers.append(sleeper)
        }
    }

    private func buildPlatform() {
        platformRoot.zPosition = -35
        worldRoot.addChild(platformRoot)

        let wall = SKShapeNode(rectOf: CGSize(width: 760, height: 270), cornerRadius: 18)
        wall.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 20)
        wall.fillColor = UIColor(hex: 0xD8D3C8)
        wall.strokeColor = UIColor.white.withAlphaComponent(0.30)
        platformRoot.addChild(wall)

        let sign = SKShapeNode(rectOf: CGSize(width: 176, height: 46), cornerRadius: 13)
        sign.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 145)
        sign.fillColor = UIColor(hex: 0x18324A)
        sign.strokeColor = UIColor(hex: 0x36D6A0)
        sign.lineWidth = 2
        platformRoot.addChild(sign)

        stationNameLabel.fontName = "AppleSDGothicNeo-Heavy"
        stationNameLabel.fontSize = 19
        stationNameLabel.fontColor = .white
        stationNameLabel.verticalAlignmentMode = .center
        stationNameLabel.position = sign.position
        platformRoot.addChild(stationNameLabel)

        let paving = SKShapeNode(rectOf: CGSize(width: 760, height: 28))
        paving.position = CGPoint(x: size.width / 2, y: trainBodyCenterY - 123)
        paving.fillColor = UIColor(hex: 0xFFD84D)
        paving.strokeColor = .clear
        platformRoot.addChild(paving)
        for index in 0..<28 {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.position = CGPoint(x: CGFloat(index) * 28 - 160, y: 0)
            dot.fillColor = UIColor(hex: 0x8A6A10).withAlphaComponent(0.45)
            dot.strokeColor = .clear
            paving.addChild(dot)
        }

        let stopLine = SKShapeNode(rectOf: CGSize(width: 10, height: 245), cornerRadius: 5)
        stopLine.position = CGPoint(x: 65, y: trainBodyCenterY + 6)
        stopLine.fillColor = UIColor(hex: 0xFFD84D)
        stopLine.strokeColor = UIColor.white.withAlphaComponent(0.8)
        stopLine.glowWidth = 5
        platformRoot.addChild(stopLine)

        waitingPassengerLayer.zPosition = 8
        platformRoot.addChild(waitingPassengerLayer)
    }

    private func buildTrain() {
        trainRoot.zPosition = 20
        addChild(trainRoot)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: trainBodyWidth + 24, height: 34))
        shadow.position = CGPoint(x: size.width / 2, y: trainBodyCenterY - 147)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.34)
        shadow.strokeColor = .clear
        trainRoot.addChild(shadow)

        let body = SKShapeNode(rectOf: CGSize(width: trainBodyWidth, height: 226), cornerRadius: 28)
        body.position = CGPoint(x: size.width / 2, y: trainBodyCenterY)
        body.fillColor = UIColor(hex: 0xC9D0D6)
        body.strokeColor = UIColor.white.withAlphaComponent(0.72)
        body.lineWidth = 3
        trainRoot.addChild(body)

        let skirt = SKShapeNode(rectOf: CGSize(width: trainBodyWidth - 4, height: 42), cornerRadius: 12)
        skirt.position = CGPoint(x: size.width / 2, y: trainBodyCenterY - 92)
        skirt.fillColor = UIColor(hex: 0x536170)
        skirt.strokeColor = .clear
        trainRoot.addChild(skirt)

        let routeStripe = SKShapeNode(rectOf: CGSize(width: trainBodyWidth - 16, height: 12), cornerRadius: 6)
        routeStripe.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 65)
        routeStripe.fillColor = UIColor(hex: 0xFFD84D)
        routeStripe.strokeColor = .clear
        trainRoot.addChild(routeStripe)

        cabinGlow.path = CGPath(
            roundedRect: CGRect(x: -trainBodyWidth / 2 + 12, y: -40, width: trainBodyWidth - 24, height: 92),
            cornerWidth: 16,
            cornerHeight: 16,
            transform: nil
        )
        cabinGlow.position = CGPoint(x: size.width / 2, y: trainBodyCenterY)
        cabinGlow.fillColor = UIColor(hex: 0xFFF0B8).withAlphaComponent(0.18)
        cabinGlow.strokeColor = .clear
        trainRoot.addChild(cabinGlow)

        onboardPassengerLayer.zPosition = 1
        trainRoot.addChild(onboardPassengerLayer)

        let windowCenters: [CGFloat] = [45, 143, 247, 345]
        for center in windowCenters {
            let window = SKShapeNode(rectOf: CGSize(width: 44, height: 55), cornerRadius: 12)
            window.position = CGPoint(x: center, y: trainBodyCenterY + 20)
            window.fillColor = UIColor(hex: 0x18324A)
            window.strokeColor = UIColor.white.withAlphaComponent(0.62)
            window.lineWidth = 2
            trainRoot.addChild(window)

            let reflection = SKShapeNode(rectOf: CGSize(width: 5, height: 38), cornerRadius: 2.5)
            reflection.position = CGPoint(x: -11, y: 3)
            reflection.zRotation = -0.14
            reflection.fillColor = UIColor.white.withAlphaComponent(0.16)
            reflection.strokeColor = .clear
            window.addChild(reflection)
        }

        let doorCenters: [CGFloat] = [96, 196, 296]
        for center in doorCenters {
            let frame = SKShapeNode(rectOf: CGSize(width: 70, height: 126), cornerRadius: 10)
            frame.position = CGPoint(x: center, y: trainBodyCenterY - 14)
            frame.fillColor = UIColor(hex: 0x707D88)
            frame.strokeColor = UIColor(hex: 0xEEF3F6)
            frame.lineWidth = 3
            trainRoot.addChild(frame)

            let left = makeDoorPanel()
            left.position = CGPoint(x: center - 17, y: trainBodyCenterY - 14)
            trainRoot.addChild(left)

            let right = makeDoorPanel()
            right.position = CGPoint(x: center + 17, y: trainBodyCenterY - 14)
            trainRoot.addChild(right)
            doorPanels.append((left, right))

            let status = SKShapeNode(circleOfRadius: 5)
            status.position = CGPoint(x: center, y: trainBodyCenterY + 56)
            status.fillColor = UIColor(hex: 0x36D6A0)
            status.strokeColor = UIColor.white.withAlphaComponent(0.7)
            status.glowWidth = 3
            trainRoot.addChild(status)
        }

        routeDisplay.fontName = "AppleSDGothicNeo-Bold"
        routeDisplay.fontSize = 13
        routeDisplay.fontColor = UIColor(hex: 0x36D6A0)
        routeDisplay.verticalAlignmentMode = .center
        routeDisplay.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 88)
        trainRoot.addChild(routeDisplay)

        for x in [82.0, 308.0] {
            let wheel = makeWheel()
            wheel.position = CGPoint(x: x, y: trainBodyCenterY - 122)
            trainRoot.addChild(wheel)
        }

        let headlight = SKShapeNode(circleOfRadius: 8)
        headlight.position = CGPoint(x: 23, y: trainBodyCenterY - 62)
        headlight.fillColor = UIColor(hex: 0xFFF1A8)
        headlight.strokeColor = .white
        headlight.glowWidth = 8
        trainRoot.addChild(headlight)
    }

    private func makeDoorPanel() -> SKShapeNode {
        let panel = SKShapeNode(rectOf: CGSize(width: 31, height: 116), cornerRadius: 7)
        panel.fillColor = UIColor(hex: 0xB8C2CA)
        panel.strokeColor = UIColor(hex: 0xF5F7F8).withAlphaComponent(0.75)
        panel.lineWidth = 2

        let glass = SKShapeNode(rectOf: CGSize(width: 19, height: 48), cornerRadius: 6)
        glass.position.y = 18
        glass.fillColor = UIColor(hex: 0x18324A)
        glass.strokeColor = UIColor.white.withAlphaComponent(0.35)
        panel.addChild(glass)

        let arrow = SKLabelNode(text: "↔")
        arrow.fontName = "AvenirNext-Heavy"
        arrow.fontSize = 12
        arrow.fontColor = UIColor(hex: 0x536170)
        arrow.verticalAlignmentMode = .center
        arrow.position.y = -35
        panel.addChild(arrow)
        return panel
    }

    private func makeWheel() -> SKNode {
        let root = SKNode()
        let outer = SKShapeNode(circleOfRadius: 22)
        outer.fillColor = UIColor(hex: 0x1D2430)
        outer.strokeColor = UIColor(hex: 0x77889A)
        outer.lineWidth = 4
        root.addChild(outer)

        let hub = SKShapeNode(circleOfRadius: 7)
        hub.fillColor = UIColor(hex: 0xAAB6C1)
        hub.strokeColor = .clear
        root.addChild(hub)

        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3) {
            let spoke = SKShapeNode(rectOf: CGSize(width: 3, height: 29), cornerRadius: 1.5)
            spoke.position = CGPoint(x: cos(angle) * 5, y: sin(angle) * 5)
            spoke.zRotation = angle
            spoke.fillColor = UIColor(hex: 0x77889A)
            spoke.strokeColor = .clear
            root.addChild(spoke)
        }
        return root
    }

    private func buildOverlayLabels() {
        resultLabel.fontName = "AppleSDGothicNeo-Heavy"
        resultLabel.fontSize = 27
        resultLabel.fontColor = UIColor(hex: 0x36D6A0)
        resultLabel.verticalAlignmentMode = .center
        resultLabel.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 168)
        resultLabel.zPosition = 90
        resultLabel.alpha = 0
        addChild(resultLabel)

        transitPassengerLayer.zPosition = 70
        addChild(transitPassengerLayer)
        particleLayer.zPosition = 80
        addChild(particleLayer)
    }

    private func updateScenery(delta: TimeInterval, speedScale: Double) {
        guard !reduceMotion else { return }
        let nearSpeed = CGFloat(delta * 230 * speedScale)
        let farSpeed = CGFloat(delta * 72 * speedScale)

        for pillar in tunnelPillars {
            pillar.position.x -= nearSpeed
            if pillar.position.x < -30 { pillar.position.x += 564 }
        }
        for line in speedLines {
            line.position.x -= nearSpeed * 1.35
            if line.position.x < -50 { line.position.x += 590 }
        }
        for sleeper in sleepers {
            sleeper.position.x -= nearSpeed * 1.6
            if sleeper.position.x < -24 { sleeper.position.x += 456 }
        }
        farCityLayer.position.x -= farSpeed
        if farCityLayer.position.x < -152 { farCityLayer.position.x += 152 }
    }

    private func updateApproachVisuals(progress: Double) {
        let clamped = min(1.1, max(0, progress))
        let targetProgress = currentPlan.optimalBrakeTime / max(0.1, currentPlan.approachDuration)
        let platformTravel = size.width * 1.20
        platformRoot.position.x = size.width * 0.92 - CGFloat(clamped / max(0.01, targetProgress)) * platformTravel
        waitingPassengerLayer.isHidden = platformRoot.position.x > 155
    }

    private func animateBrake(_ resolution: BrakeResolution) {
        let gradeText: String
        let gradeColor: UIColor
        switch resolution.grade {
        case .perfect:
            gradeText = "정위치!  \(resolution.exitedCount)명 하차"
            gradeColor = UIColor(hex: 0x36D6A0)
        case .safe:
            gradeText = "안전 정차  \(resolution.exitedCount)명 하차"
            gradeColor = UIColor(hex: 0xFFD84D)
        case .near:
            gradeText = "조금 어긋났어요  \(resolution.exitedCount)명"
            gradeColor = UIColor(hex: 0xFFB34D)
        case .missed:
            gradeText = "역을 통과했어요"
            gradeColor = UIColor(hex: 0xFF665F)
        }

        resultLabel.text = gradeText
        resultLabel.fontColor = gradeColor
        resultLabel.removeAllActions()
        resultLabel.alpha = 0
        resultLabel.setScale(0.78)
        resultLabel.run(.sequence([
            .wait(forDuration: 0.42),
            .group([.fadeIn(withDuration: 0.15), .scale(to: 1, duration: 0.18)]),
            .wait(forDuration: 1.5),
            .fadeOut(withDuration: 0.25)
        ]))

        platformRoot.removeAllActions()
        platformRoot.run(eased(.moveTo(x: 0, duration: 0.72), mode: .easeOut))

        trainRoot.removeAction(forKey: "brake")
        let finalShift = CGFloat(max(-10, min(10, resolution.finalOffset * 18)))
        let brakeMove = eased(.moveBy(x: finalShift, y: resolution.grade == .missed ? -3 : -1, duration: 0.56), mode: .easeOut)
        let settle = eased(.moveBy(x: -finalShift, y: resolution.grade == .missed ? 3 : 1, duration: 0.38), mode: .easeInEaseOut)
        trainRoot.run(.sequence([brakeMove, settle]), withKey: "brake")

        if resolution.grade == .missed {
            shakeTrain()
        }

        guard resolution.grade != .missed else { return }
        let exchangeDelay = 0.88
        trainRoot.run(.sequence([
            .wait(forDuration: exchangeDelay),
            .run { [weak self] in
                self?.openDoors()
                self?.animatePassengerExchange(
                    exited: resolution.exitedCount,
                    boarded: self?.currentPlan.boardDemand ?? 0
                )
            },
            .wait(forDuration: 2.5),
            .run { [weak self] in self?.closeDoors(animated: true) }
        ]))

        if resolution.grade == .perfect {
            burstTickets()
        }
    }

    private func openDoors() {
        snapshot.doorsOpen = true
        cabinGlow.fillColor = UIColor(hex: 0xFFF0B8).withAlphaComponent(0.42)
        for pair in doorPanels {
            pair.left.removeAllActions()
            pair.right.removeAllActions()
            pair.left.run(eased(.moveBy(x: -18, y: 0, duration: 0.24), mode: .easeOut))
            pair.right.run(eased(.moveBy(x: 18, y: 0, duration: 0.24), mode: .easeOut))
        }
        emitSnapshot()
    }

    private func closeDoors(animated: Bool) {
        snapshot.doorsOpen = false
        cabinGlow.fillColor = UIColor(hex: 0xFFF0B8).withAlphaComponent(0.18)
        let centers: [CGFloat] = [96, 196, 296]
        for (index, pair) in doorPanels.enumerated() where centers.indices.contains(index) {
            pair.left.removeAllActions()
            pair.right.removeAllActions()
            let leftTarget = CGPoint(x: centers[index] - 17, y: trainBodyCenterY - 14)
            let rightTarget = CGPoint(x: centers[index] + 17, y: trainBodyCenterY - 14)
            if animated {
                pair.left.run(eased(.move(to: leftTarget, duration: 0.22), mode: .easeInEaseOut))
                pair.right.run(eased(.move(to: rightTarget, duration: 0.22), mode: .easeInEaseOut))
            } else {
                pair.left.position = leftTarget
                pair.right.position = rightTarget
            }
        }
        emitSnapshot()
    }

    private func refillOnboardPassengers() {
        onboardPassengerLayer.removeAllChildren()
        let positions: [CGPoint] = [
            CGPoint(x: 50, y: trainBodyCenterY + 10),
            CGPoint(x: 122, y: trainBodyCenterY + 6),
            CGPoint(x: 165, y: trainBodyCenterY + 13),
            CGPoint(x: 228, y: trainBodyCenterY + 4),
            CGPoint(x: 270, y: trainBodyCenterY + 12),
            CGPoint(x: 340, y: trainBodyCenterY + 7)
        ]
        for (index, position) in positions.enumerated() {
            let kind = PassengerKind.destinations[passengerRNG.int(in: 0...(PassengerKind.destinations.count - 1))]
            let passenger = makePassenger(kind: kind, index: index)
            passenger.position = position
            passenger.setScale(index.isMultiple(of: 2) ? 0.82 : 0.74)
            onboardPassengerLayer.addChild(passenger)
        }
    }

    private func rebuildWaitingPassengers(count: Int) {
        waitingPassengerLayer.removeAllChildren()
        for index in 0..<min(6, max(3, count)) {
            let kind = PassengerKind.destinations[passengerRNG.int(in: 0...(PassengerKind.destinations.count - 1))]
            let passenger = makePassenger(kind: kind, index: index + 10)
            passenger.position = CGPoint(
                x: 44 + CGFloat(index) * 54,
                y: trainBodyCenterY - 87 + CGFloat(index % 2) * 5
            )
            passenger.setScale(0.80)
            waitingPassengerLayer.addChild(passenger)
        }
    }

    private func animatePassengerExchange(exited: Int, boarded: Int) {
        transitPassengerLayer.removeAllChildren()
        let doorCenters: [CGFloat] = [96, 196, 296]
        for index in 0..<min(9, exited) {
            let kind = PassengerKind.destinations[index % PassengerKind.destinations.count]
            let passenger = makePassenger(kind: kind, index: index)
            let doorX = doorCenters[index % doorCenters.count]
            passenger.position = CGPoint(x: doorX, y: trainBodyCenterY - 10)
            passenger.setScale(0.76)
            passenger.alpha = 0
            transitPassengerLayer.addChild(passenger)

            let delay = TimeInterval(index) * 0.075
            let target = CGPoint(
                x: doorX + CGFloat((index % 3) - 1) * 34,
                y: trainBodyCenterY - 153 - CGFloat(index % 2) * 12
            )
            passenger.run(.sequence([
                .wait(forDuration: delay),
                .fadeIn(withDuration: 0.06),
                .group([
                    eased(.move(to: target, duration: reduceMotion ? 0.16 : 0.48), mode: .easeInEaseOut),
                    .sequence([.scale(to: 0.84, duration: 0.22), .scale(to: 0.72, duration: 0.24)])
                ]),
                .fadeOut(withDuration: 0.20),
                .removeFromParent()
            ]))
        }

        for index in 0..<min(5, boarded) {
            let kind = PassengerKind.destinations[(index + snapshot.stopIndex) % PassengerKind.destinations.count]
            let passenger = makePassenger(kind: kind, index: index + 20)
            let doorX = doorCenters[index % doorCenters.count]
            passenger.position = CGPoint(x: doorX + CGFloat(index - 2) * 22, y: trainBodyCenterY - 153)
            passenger.setScale(0.70)
            transitPassengerLayer.addChild(passenger)
            passenger.run(.sequence([
                .wait(forDuration: 0.55 + TimeInterval(index) * 0.10),
                eased(.move(to: CGPoint(x: doorX, y: trainBodyCenterY - 12), duration: reduceMotion ? 0.16 : 0.45), mode: .easeInEaseOut),
                .fadeOut(withDuration: 0.12),
                .removeFromParent()
            ]))
        }
    }

    private func makePassenger(kind: PassengerKind, index: Int) -> SKNode {
        let root = SKNode()
        root.name = "passenger"

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 24, height: 8))
        shadow.position.y = -24
        shadow.fillColor = UIColor.black.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        root.addChild(shadow)

        let body = SKShapeNode(rectOf: CGSize(width: 25, height: 30), cornerRadius: 8)
        body.position.y = -6
        body.fillColor = UIColor(hex: kind.tintHex)
        body.strokeColor = UIColor.white.withAlphaComponent(0.88)
        body.lineWidth = 2
        root.addChild(body)

        let head = SKShapeNode(circleOfRadius: 11)
        head.position.y = 18
        head.fillColor = UIColor(hex: [0xF2C7A5, 0xDDA77B, 0xB97952][index % 3])
        head.strokeColor = UIColor.white.withAlphaComponent(0.68)
        head.lineWidth = 1.5
        root.addChild(head)

        let hair = SKShapeNode(rectOf: CGSize(width: 20, height: 8), cornerRadius: 4)
        hair.position = CGPoint(x: 0, y: 24)
        hair.fillColor = UIColor(hex: [0x242027, 0x5A382B, 0x23364C][index % 3])
        hair.strokeColor = .clear
        root.addChild(hair)

        let badge = SKLabelNode(text: kind.badge)
        badge.fontName = "AvenirNext-Heavy"
        badge.fontSize = 16
        badge.fontColor = kind == .star ? UIColor(hex: 0x5A4510) : .white
        badge.verticalAlignmentMode = .center
        badge.position.y = -6
        root.addChild(badge)

        for x in [-6.0, 6.0] {
            let leg = SKShapeNode(rectOf: CGSize(width: 5, height: 13), cornerRadius: 2.5)
            leg.position = CGPoint(x: x, y: -25)
            leg.fillColor = UIColor(hex: 0x223149)
            leg.strokeColor = .clear
            root.addChild(leg)
        }
        return root
    }

    private func burstTickets() {
        guard !reduceMotion else { return }
        for index in 0..<20 {
            let ticket = SKShapeNode(rectOf: CGSize(width: 8, height: 14), cornerRadius: 2)
            ticket.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 82)
            ticket.fillColor = UIColor(hex: [0x36D6A0, 0xFFD84D, 0x7B9CFF, 0xFF665F][index % 4])
            ticket.strokeColor = .clear
            ticket.zRotation = effectsRNG.double(in: -1.4...1.4)
            particleLayer.addChild(ticket)

            let angle = Double(index) / 20 * .pi * 2
            let distance = effectsRNG.double(in: 62...148)
            ticket.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.62),
                    .rotate(byAngle: effectsRNG.double(in: -2.6...2.6), duration: 0.62),
                    .fadeOut(withDuration: 0.62)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func shakeTrain() {
        guard !reduceMotion else { return }
        let actions: [SKAction] = (0..<5).flatMap { _ in
            [SKAction.moveBy(x: 3, y: 0, duration: 0.04), SKAction.moveBy(x: -3, y: 0, duration: 0.04)]
        }
        trainRoot.run(.sequence(actions))

        for index in 0..<8 {
            let spark = SKShapeNode(circleOfRadius: 2.5)
            spark.position = CGPoint(x: 44 + CGFloat(index) * 38, y: trainBodyCenterY - 144)
            spark.fillColor = UIColor(hex: 0xFFB34D)
            spark.strokeColor = .clear
            particleLayer.addChild(spark)
            spark.run(.sequence([
                .group([
                    .moveBy(x: effectsRNG.double(in: -22...22), y: effectsRNG.double(in: 10...44), duration: 0.30),
                    .fadeOut(withDuration: 0.30)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func showFloatingText(_ text: String, color: UIColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "AppleSDGothicNeo-Heavy"
        label.fontSize = 22
        label.fontColor = color
        label.position = CGPoint(x: size.width / 2, y: trainBodyCenterY + 150)
        label.zPosition = 100
        addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 30, duration: 0.42), .fadeIn(withDuration: 0.12)]),
            .wait(forDuration: 0.65),
            .fadeOut(withDuration: 0.22),
            .removeFromParent()
        ]))
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
