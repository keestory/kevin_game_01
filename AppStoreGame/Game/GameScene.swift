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
    private var rng: SeededRandom
    private var snapshot = RunSnapshot()
    private var board = TrainBoard()
    private var lastUpdateTime: TimeInterval = 0
    private var selectorPhase: Double = 0.5
    private var selectorPosition: Double = 2
    private var inputLock: TimeInterval = 0
    private var slowdownRemaining: TimeInterval = 0
    private var runFinished = false
    private var rescuePending = false
    private var stationCelebration = SKLabelNode()
    private var selector = SKNode()
    private var selectorBadge = SKLabelNode()
    private var columnHighlights: [SKShapeNode] = []
    private var queue: [PassengerKind] = []

    private var horizontalMargin: CGFloat { 20 }
    private var boardOriginY: CGFloat { max(94, size.height * 0.115) }
    private var cellWidth: CGFloat { (size.width - horizontalMargin * 2) / 5 }
    private var cellHeight: CGFloat { min(62, (size.height - boardOriginY - 230) / 7) }
    private var boardTopY: CGFloat { boardOriginY + cellHeight * 7 }

    init(size: CGSize, seed: UInt64, difficulty: StageDifficulty) {
        self.seed = seed
        self.difficulty = difficulty
        self.rng = SeededRandom(seed: seed)
        self.snapshot.duration = difficulty.duration
        self.snapshot.stage = difficulty.stage
        self.snapshot.targetScore = difficulty.targetScore
        self.snapshot.safetyHandles = difficulty.safetyHandles
        self.snapshot.assisted = difficulty.assisted
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = UIColor(hex: 0x10182C)
        anchorPoint = .zero
        queue = (0..<3).map { index in
            GameRules.passengerKind(
                boarded: index,
                destinationCount: difficulty.destinationCount,
                transferInterval: difficulty.transferInterval,
                rng: &rng
            )
        }
        snapshot.nextPassenger = queue[0]
        snapshot.upcoming = Array(queue.dropFirst())
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = false
        buildTrainInterior()
        buildSelector()
        rebuildBoard(animated: false)
        snapshot.phase = .playing
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
    }

    override func update(_ currentTime: TimeInterval) {
        guard snapshot.phase == .playing, !runFinished else { return }
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }

        let delta = min(max(0, currentTime - lastUpdateTime), 1.0 / 30.0)
        lastUpdateTime = currentTime
        snapshot.elapsed = min(snapshot.duration, snapshot.elapsed + delta)
        inputLock = max(0, inputLock - delta)
        slowdownRemaining = max(0, slowdownRemaining - delta)
        updateSelector(delta: delta)
        updateStation()

        if snapshot.score >= snapshot.targetScore {
            finish(completed: true)
            return
        }
        if snapshot.remaining <= 0 {
            requestRescueOrFinish()
            return
        }
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
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
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
    }

    func acceptRescue() {
        guard rescuePending, !snapshot.rescueUsed, !runFinished else { return }
        rescuePending = false
        snapshot.rescueUsed = true
        snapshot.duration += 15
        snapshot.phase = .playing
        slowdownRemaining = 3
        inputLock = 0.65
        _ = board.rescueTallestColumns()
        rebuildBoard(animated: true)
        showFloatingText(
            "구조 완료! +15초",
            at: CGPoint(x: size.width / 2, y: boardOriginY + cellHeight * 4.5),
            color: UIColor(hex: 0x36D6A0)
        )
        lastUpdateTime = 0
        isPaused = false
        isUserInteractionEnabled = true
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
    }

    func declineRescue() {
        guard rescuePending, !runFinished else { return }
        rescuePending = false
        isPaused = false
        finish(completed: false)
    }

    private func buildTrainInterior() {
        let window = SKShapeNode(rectOf: CGSize(width: size.width - 38, height: size.height * 0.20), cornerRadius: 28)
        window.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.135)
        window.fillColor = UIColor(hex: 0x182541)
        window.strokeColor = UIColor.white.withAlphaComponent(0.10)
        window.lineWidth = 2
        window.zPosition = -20
        addChild(window)

        for index in 0..<9 {
            let light = SKShapeNode(rectOf: CGSize(width: 3, height: 24), cornerRadius: 1.5)
            light.position = CGPoint(x: 34 + CGFloat(index) * (size.width - 68) / 8, y: window.position.y)
            light.fillColor = UIColor(hex: index.isMultiple(of: 3) ? 0xFFD84D : 0x7B9CFF).withAlphaComponent(0.34)
            light.strokeColor = .clear
            light.zPosition = -18
            light.name = "windowLight"
            addChild(light)
            light.run(.repeatForever(.sequence([
                .moveBy(x: -16, y: 0, duration: 0.34),
                .moveBy(x: 16, y: 0, duration: 0)
            ])))
        }

        let cabin = SKShapeNode(rectOf: CGSize(width: size.width - 22, height: cellHeight * 7 + 66), cornerRadius: 30)
        cabin.position = CGPoint(x: size.width / 2, y: boardOriginY + cellHeight * 3.5)
        cabin.fillColor = UIColor(hex: 0xF7F3E8)
        cabin.strokeColor = UIColor(hex: 0xFFD84D).withAlphaComponent(0.55)
        cabin.lineWidth = 3
        cabin.zPosition = -12
        addChild(cabin)

        for column in 0..<TrainBoard.columnCount {
            let highlight = SKShapeNode(
                rectOf: CGSize(width: cellWidth - 8, height: cellHeight * 7 - 8),
                cornerRadius: 17
            )
            highlight.position = CGPoint(
                x: columnCenter(column),
                y: boardOriginY + cellHeight * 3.5
            )
            highlight.fillColor = UIColor(hex: 0xFFD84D).withAlphaComponent(0.03)
            highlight.strokeColor = UIColor(hex: 0x1A2842).withAlphaComponent(0.10)
            highlight.lineWidth = 1
            highlight.zPosition = -10
            addChild(highlight)
            columnHighlights.append(highlight)
        }

        for row in 1..<TrainBoard.rowCount {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: horizontalMargin + 8, y: boardOriginY + CGFloat(row) * cellHeight))
            path.addLine(to: CGPoint(x: size.width - horizontalMargin - 8, y: boardOriginY + CGFloat(row) * cellHeight))
            let line = SKShapeNode(path: path)
            line.strokeColor = UIColor(hex: 0x1A2842).withAlphaComponent(0.07)
            line.lineWidth = 1
            line.zPosition = -9
            addChild(line)
        }

        stationCelebration = SKLabelNode(text: "")
        stationCelebration.fontName = "AppleSDGothicNeo-Heavy"
        stationCelebration.fontSize = 22
        stationCelebration.fontColor = UIColor(hex: 0xFFD84D)
        stationCelebration.position = CGPoint(x: size.width / 2, y: boardTopY + 94)
        stationCelebration.zPosition = 60
        addChild(stationCelebration)
    }

    private func buildSelector() {
        selector.removeFromParent()
        let root = SKNode()
        root.position = CGPoint(x: columnCenter(snapshot.selectedColumn), y: boardTopY + 37)
        root.zPosition = 40

        let door = SKShapeNode(rectOf: CGSize(width: cellWidth - 9, height: 58), cornerRadius: 17)
        door.fillColor = UIColor(hex: 0xFFD84D)
        door.strokeColor = UIColor.white.withAlphaComponent(0.85)
        door.lineWidth = 3
        door.glowWidth = 4
        root.addChild(door)

        let arrow = SKLabelNode(text: "▼")
        arrow.fontName = "AvenirNext-Heavy"
        arrow.fontSize = 13
        arrow.fontColor = UIColor(hex: 0x10182C)
        arrow.position.y = -18
        root.addChild(arrow)

        selectorBadge = SKLabelNode(text: snapshot.nextPassenger.badge)
        selectorBadge.fontName = "AvenirNext-Heavy"
        selectorBadge.fontSize = 27
        selectorBadge.fontColor = UIColor(hex: snapshot.nextPassenger.tintHex)
        selectorBadge.verticalAlignmentMode = .center
        selectorBadge.position.y = 4
        root.addChild(selectorBadge)

        addChild(root)
        selector = root
    }

    private func updateSelector(delta: TimeInterval) {
        var period = GameRules.selectorPeriod(
            at: snapshot.elapsed,
            duration: snapshot.duration
        ) * difficulty.selectorPeriodScale
        if slowdownRemaining > 0 { period *= 1.25 }
        selectorPhase += delta * 2 / period
        let wrapped = selectorPhase.truncatingRemainder(dividingBy: 2)
        let progress = wrapped <= 1 ? wrapped : 2 - wrapped
        selectorPosition = progress * 4
        selector.position.x = horizontalMargin + cellWidth * 0.5 + CGFloat(selectorPosition) * cellWidth
        let selected = min(4, max(0, Int(selectorPosition.rounded())))
        if selected != snapshot.selectedColumn {
            snapshot.selectedColumn = selected
            updateColumnHighlights()
        }
    }

    private func updateColumnHighlights() {
        for (index, highlight) in columnHighlights.enumerated() {
            let active = index == snapshot.selectedColumn
            highlight.fillColor = UIColor(hex: active ? 0xFFD84D : 0x1A2842).withAlphaComponent(active ? 0.15 : 0.02)
            highlight.strokeColor = UIColor(hex: active ? 0xFFD84D : 0x1A2842).withAlphaComponent(active ? 0.58 : 0.10)
        }
    }

    private func updateStation() {
        let bonus = GameRules.stationBonus(
            at: snapshot.elapsed,
            duration: snapshot.duration,
            previousStation: snapshot.station
        )
        guard bonus > 0 else { return }
        snapshot.station = min(4, Int(snapshot.elapsed / max(1, snapshot.duration / 4)) + 1)
        snapshot.score += bonus
        stationCelebration.removeAllActions()
        stationCelebration.text = "\(snapshot.station)번째 역  +\(bonus)"
        stationCelebration.alpha = 0
        stationCelebration.setScale(0.75)
        stationCelebration.run(.sequence([
            .group([.fadeIn(withDuration: 0.12), .scale(to: 1, duration: 0.18)]),
            .wait(forDuration: 0.75),
            .fadeOut(withDuration: 0.25)
        ]))
    }

    private func placePassenger() {
        guard snapshot.phase == .playing, inputLock <= 0, !runFinished else { return }
        inputLock = 0.18
        let column = snapshot.selectedColumn
        let oldRow = board.columns[column].count
        let kind = snapshot.nextPassenger
        let perfect = abs(selectorPosition - Double(column)) <= 0.20
        let resolution = board.place(kind, in: column)

        guard resolution.placed else {
            gameDelegate?.gameScene(self, didEmit: .overflow)
            handleOverflow(in: column)
            return
        }

        snapshot.boarded += 1
        snapshot.score += resolution.scoreGained + (perfect ? 15 : 0)
        snapshot.lastWasPerfect = perfect
        if perfect {
            gameDelegate?.gameScene(self, didEmit: .perfect)
            showFloatingText("PERFECT +15", at: selector.position, color: UIColor(hex: 0xFFD84D))
        }

        if resolution.removedCount > 0 {
            snapshot.exited += resolution.removedCount
            snapshot.currentChain = resolution.cascadeCount
            snapshot.bestChain = max(snapshot.bestChain, resolution.cascadeCount)
            gameDelegate?.gameScene(self, didEmit: .match(resolution.removedCount))
        } else {
            snapshot.currentChain = 0
        }

        let landingRow = min(oldRow, TrainBoard.rowCount - 1)
        animateDrop(kind: kind, column: column, row: landingRow) { [weak self] in
            guard let self else { return }
            self.rebuildBoard(animated: resolution.removedCount > 0)
            if resolution.removedCount > 0 {
                self.showMatch(count: resolution.removedCount, chain: resolution.cascadeCount)
            }
        }
        advanceQueue()
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
    }

    private func handleOverflow(in column: Int) {
        guard snapshot.safetyHandles > 0 else {
            requestRescueOrFinish()
            return
        }

        snapshot.safetyHandles -= 1
        snapshot.currentChain = 0
        slowdownRemaining = 3
        inputLock = 0.65
        _ = board.removeTopPassengers(from: column, count: 3)
        rebuildBoard(animated: true)
        showFloatingText(
            "안전 손잡이 사용  ×\(snapshot.safetyHandles)",
            at: CGPoint(x: columnCenter(column), y: boardTopY - cellHeight),
            color: UIColor(hex: 0xFF665F)
        )
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
    }

    private func requestRescueOrFinish() {
        guard !snapshot.rescueUsed else {
            finish(completed: false)
            return
        }
        rescuePending = true
        snapshot.phase = .awaitingRescue
        isPaused = true
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
        gameDelegate?.gameScene(self, didEmit: .rescueRequested)
    }

    private func advanceQueue() {
        queue.removeFirst()
        let newKind = GameRules.passengerKind(
            boarded: snapshot.boarded + queue.count,
            destinationCount: difficulty.destinationCount,
            transferInterval: difficulty.transferInterval,
            rng: &rng
        )
        queue.append(newKind)
        snapshot.nextPassenger = queue[0]
        snapshot.upcoming = Array(queue.dropFirst())
        selectorBadge.text = snapshot.nextPassenger.badge
        selectorBadge.fontColor = UIColor(hex: snapshot.nextPassenger.tintHex)
    }

    private func animateDrop(kind: PassengerKind, column: Int, row: Int, completion: @escaping @MainActor () -> Void) {
        let node = passengerNode(kind: kind, compact: false)
        node.name = "fallingPassenger"
        node.position = CGPoint(x: selector.position.x, y: selector.position.y)
        node.zPosition = 50
        addChild(node)
        let target = CGPoint(x: columnCenter(column), y: rowCenter(row))
        node.run(.sequence([
            .group([
                .move(to: target, duration: 0.15),
                .scale(to: 0.92, duration: 0.15)
            ]),
            .run(completion),
            .removeFromParent()
        ]))
    }

    private func rebuildBoard(animated: Bool) {
        enumerateChildNodes(withName: "seatPassenger") { node, _ in node.removeFromParent() }
        for column in board.columns.indices {
            for row in board.columns[column].indices {
                let node = passengerNode(kind: board.columns[column][row], compact: false)
                node.name = "seatPassenger"
                node.position = CGPoint(x: columnCenter(column), y: rowCenter(row))
                node.zPosition = 20
                if animated {
                    node.alpha = 0
                    node.setScale(0.65)
                    node.run(.group([.fadeIn(withDuration: 0.16), .scale(to: 1, duration: 0.18)]))
                }
                addChild(node)
            }
        }
    }

    private func passengerNode(kind: PassengerKind, compact: Bool) -> SKNode {
        let root = SKNode()
        let radius = min(cellWidth * 0.34, cellHeight * 0.36)
        let body = SKShapeNode(circleOfRadius: radius)
        body.fillColor = UIColor(hex: kind.tintHex)
        body.strokeColor = UIColor.white.withAlphaComponent(0.92)
        body.lineWidth = 2.5
        root.addChild(body)

        let shine = SKShapeNode(circleOfRadius: radius * 0.26)
        shine.position = CGPoint(x: -radius * 0.33, y: radius * 0.34)
        shine.fillColor = UIColor.white.withAlphaComponent(0.32)
        shine.strokeColor = .clear
        body.addChild(shine)

        let badge = SKLabelNode(text: kind.badge)
        badge.fontName = "AvenirNext-Heavy"
        badge.fontSize = radius * 0.95
        badge.fontColor = kind == .star ? UIColor(hex: 0x5A4510) : .white
        badge.verticalAlignmentMode = .center
        badge.horizontalAlignmentMode = .center
        badge.position.y = -1
        root.addChild(badge)
        return root
    }

    private func showMatch(count: Int, chain: Int) {
        let text = chain > 1 ? "환승 ×\(chain)!  \(count)명 하차" : "\(count)명 하차!"
        showFloatingText(text, at: CGPoint(x: size.width / 2, y: boardOriginY + cellHeight * 3.5), color: UIColor(hex: 0x36D6A0))
        for index in 0..<min(14, count * 3) {
            let spark = SKShapeNode(circleOfRadius: 3)
            spark.fillColor = UIColor(hex: [0x36D6A0, 0xFFD84D, 0x7B9CFF][index % 3])
            spark.strokeColor = .clear
            spark.position = CGPoint(x: size.width / 2, y: boardOriginY + cellHeight * 3.5)
            spark.zPosition = 70
            addChild(spark)
            let angle = Double(index) / Double(max(1, min(14, count * 3))) * .pi * 2
            let distance = rng.double(in: 48...116)
            spark.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.36),
                    .fadeOut(withDuration: 0.36),
                    .scale(to: 0.2, duration: 0.36)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func showFloatingText(_ text: String, at point: CGPoint, color: UIColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "AppleSDGothicNeo-Heavy"
        label.fontSize = 19
        label.fontColor = color
        label.position = point
        label.zPosition = 80
        label.setScale(0.72)
        addChild(label)
        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 38, duration: 0.48),
                .sequence([.scale(to: 1.08, duration: 0.12), .scale(to: 1, duration: 0.12)])
            ]),
            .fadeOut(withDuration: 0.22),
            .removeFromParent()
        ]))
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
        gameDelegate?.gameScene(self, didEmit: .snapshot(snapshot))
        gameDelegate?.gameScene(self, didEmit: .finished(result))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard touches.first != nil else { return }
        placePassenger()
    }

    private func columnCenter(_ column: Int) -> CGFloat {
        horizontalMargin + cellWidth * (CGFloat(column) + 0.5)
    }

    private func rowCenter(_ row: Int) -> CGFloat {
        boardOriginY + cellHeight * (CGFloat(row) + 0.5)
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
