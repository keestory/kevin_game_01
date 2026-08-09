import Foundation

struct TrainBoard: Equatable {
    static let columnCount = 5
    static let rowCount = 7

    private(set) var columns: [[PassengerKind]] = Array(
        repeating: [],
        count: TrainBoard.columnCount
    )

    subscript(_ position: GridPosition) -> PassengerKind? {
        guard columns.indices.contains(position.column),
              columns[position.column].indices.contains(position.row) else { return nil }
        return columns[position.column][position.row]
    }

    var occupiedCount: Int { columns.reduce(0) { $0 + $1.count } }

    func isFull(column: Int) -> Bool {
        guard columns.indices.contains(column) else { return true }
        return columns[column].count >= Self.rowCount
    }

    mutating func place(_ kind: PassengerKind, in column: Int) -> PlacementResolution {
        guard columns.indices.contains(column), !isFull(column: column) else {
            return PlacementResolution(
                placed: false,
                overflowed: true,
                removedCount: 0,
                cascadeCount: 0,
                scoreGained: 0
            )
        }

        columns[column].append(kind)
        var totalRemoved = 0
        var cascade = 0
        var score = 10

        while let group = firstMatch() {
            cascade += 1
            totalRemoved += group.count
            let base = 100 + max(0, group.count - 3) * 60
            let multiplier = min(3.0, 1.0 + Double(cascade - 1) * 0.25)
            score += Int(Double(base) * multiplier)
            remove(group)
        }

        return PlacementResolution(
            placed: true,
            overflowed: false,
            removedCount: totalRemoved,
            cascadeCount: cascade,
            scoreGained: score
        )
    }

    @discardableResult
    mutating func removeTopPassengers(from column: Int, count: Int) -> Int {
        guard columns.indices.contains(column), count > 0 else { return 0 }
        let removed = min(count, columns[column].count)
        guard removed > 0 else { return 0 }
        columns[column].removeLast(removed)
        return removed
    }

    @discardableResult
    mutating func rescueTallestColumns(columnCount: Int = 2, removeEach: Int = 2) -> Int {
        let targets = columns.indices
            .filter { !columns[$0].isEmpty }
            .sorted {
                if columns[$0].count == columns[$1].count { return $0 < $1 }
                return columns[$0].count > columns[$1].count
            }
            .prefix(max(0, columnCount))

        return targets.reduce(into: 0) { removed, column in
            removed += removeTopPassengers(from: column, count: removeEach)
        }
    }

    private func firstMatch() -> Set<GridPosition>? {
        for destination in PassengerKind.destinations {
            var visited = Set<GridPosition>()
            for column in columns.indices {
                for row in columns[column].indices {
                    let start = GridPosition(column: column, row: row)
                    guard !visited.contains(start), isCompatible(start, destination: destination) else { continue }
                    let group = connectedGroup(from: start, destination: destination, visited: &visited)
                    let hasDestination = group.contains { self[$0] == destination }
                    if group.count >= 3, hasDestination {
                        return group
                    }
                }
            }
        }
        return nil
    }

    private func connectedGroup(
        from start: GridPosition,
        destination: PassengerKind,
        visited: inout Set<GridPosition>
    ) -> Set<GridPosition> {
        var queue = [start]
        var group = Set<GridPosition>()
        visited.insert(start)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            group.insert(current)
            let neighbors = [
                GridPosition(column: current.column - 1, row: current.row),
                GridPosition(column: current.column + 1, row: current.row),
                GridPosition(column: current.column, row: current.row - 1),
                GridPosition(column: current.column, row: current.row + 1)
            ]
            for neighbor in neighbors where !visited.contains(neighbor) {
                guard isCompatible(neighbor, destination: destination) else { continue }
                visited.insert(neighbor)
                queue.append(neighbor)
            }
        }
        return group
    }

    private func isCompatible(_ position: GridPosition, destination: PassengerKind) -> Bool {
        guard let kind = self[position] else { return false }
        return kind == destination || kind == .transfer
    }

    private mutating func remove(_ positions: Set<GridPosition>) {
        for column in columns.indices {
            let rows = positions
                .filter { $0.column == column }
                .map(\.row)
                .sorted(by: >)
            for row in rows where columns[column].indices.contains(row) {
                columns[column].remove(at: row)
            }
        }
    }
}

enum GameRules {
    static let routingStationCount = 5
    static let routingQueueCount = 10
    static let routingDoorCount = 4
    static let routingPassengerTargetPerDestination = 3
    static let countStationCount = 5
    static let countPassengerCapacity = 24

    /// 자동 하차 후 한 명씩 탑승하는 5역 인원 맞추기 계획을 seed로 재현한다.
    /// 성공 경로에서는 다음 역의 시작 인원이 이전 역 목표 인원과 같다.
    static func countRunPlan(seed: UInt64, difficulty: StageDifficulty) -> CountRunPlan {
        let difficultySalt = UInt64(truncatingIfNeeded: max(1, difficulty.stage))
            &* 0xD1B5_4A32_D192_ED03
        var rng = SeededRandom(seed: seed ^ difficultySalt)
        var nextInitialOnboard = rng.int(in: 10...14)
        var nextEventID = 0

        let stations = (1...countStationCount).map { stationIndex in
            let initialOnboard = nextInitialOnboard
            let maximumExit = min(6, initialOnboard - 2)
            let exitCount = rng.int(in: 3...maximumExit)
            let onboardAfterExit = initialOnboard - exitCount
            let maximumBoardToTarget = min(
                5,
                countPassengerCapacity - 1 - onboardAfterExit
            )
            let boardToTarget = rng.int(in: 3...maximumBoardToTarget)
            let targetOnboard = onboardAfterExit + boardToTarget
            let passengersAfterTarget = min(
                rng.int(in: 1...2),
                countPassengerCapacity - targetOnboard
            )
            let totalBoarding = boardToTarget + passengersAfterTarget
            let minimumTargetHold = stationIndex == 1 ? 1_200 : 600

            var events: [PassengerFlowEvent] = []
            var eventTime = rng.int(in: 180...300)
            var remainingExit = exitCount
            while remainingExit > 0 {
                let burstSize = min(remainingExit, rng.int(in: 1...3))
                events.append(
                    PassengerFlowEvent(
                        id: nextEventID,
                        offsetMilliseconds: eventTime,
                        direction: .exit,
                        passengerCount: burstSize,
                        visualSeed: rng.next()
                    )
                )
                nextEventID += 1
                remainingExit -= burstSize
                eventTime += rng.int(in: 180...390)
            }

            eventTime += rng.int(in: 260...460)
            for boardingIndex in 1...totalBoarding {
                events.append(
                    PassengerFlowEvent(
                        id: nextEventID,
                        offsetMilliseconds: eventTime,
                        direction: .board,
                        passengerCount: 1,
                        visualSeed: rng.next()
                    )
                )
                nextEventID += 1
                if boardingIndex == boardToTarget {
                    eventTime += minimumTargetHold + rng.int(in: 0...260)
                } else {
                    eventTime += rng.int(in: 230...510)
                }
            }

            let plan = StationCountPlan(
                index: stationIndex,
                initialOnboard: initialOnboard,
                targetOnboard: targetOnboard,
                capacity: countPassengerCapacity,
                deadlineMilliseconds: eventTime + 700,
                minimumTargetHoldMilliseconds: minimumTargetHold,
                events: events
            )
            nextInitialOnboard = targetOnboard
            return plan
        }

        return CountRunPlan(seed: seed, stations: stations)
    }

    static func initialCountFlowState(for plan: StationCountPlan) -> CountFlowState {
        CountFlowState(
            stationIndex: plan.index,
            elapsedMilliseconds: 0,
            onboardCount: plan.initialOnboard,
            nextEventIndex: 0,
            countRevision: 0,
            phase: plan.exitEvents.isEmpty ? .boarding : .automaticExit
        )
    }

    /// 절대 역 경과 시간까지 모든 임계 이벤트를 순서대로 정확히 한 번 적용한다.
    /// 같은 시간이나 과거 시간으로 반복 호출해도 이미 적용한 이벤트는 다시 적용하지 않는다.
    static func advanceFlow(
        state: CountFlowState,
        throughMilliseconds requestedMilliseconds: Int,
        plan: StationCountPlan
    ) -> FlowAdvance {
        guard state.phase != .doorsClosed, state.phase != .timedOut else {
            return FlowAdvance(state: state, appliedEvents: [])
        }

        let targetMilliseconds = min(
            plan.deadlineMilliseconds,
            max(state.elapsedMilliseconds, requestedMilliseconds)
        )
        var onboardCount = state.onboardCount
        var nextEventIndex = state.nextEventIndex
        var countRevision = state.countRevision
        var appliedEvents: [PassengerFlowEvent] = []

        while plan.events.indices.contains(nextEventIndex) {
            let event = plan.events[nextEventIndex]
            guard event.offsetMilliseconds <= targetMilliseconds else { break }
            let delta = event.direction == .exit
                ? -event.passengerCount
                : event.passengerCount
            onboardCount += delta
            countRevision += 1
            nextEventIndex += 1
            appliedEvents.append(event)
        }

        let phase: PassengerFlowPhase
        if targetMilliseconds >= plan.deadlineMilliseconds {
            phase = .timedOut
        } else if plan.events.dropFirst(nextEventIndex).contains(where: { $0.direction == .exit }) {
            phase = .automaticExit
        } else {
            phase = .boarding
        }

        return FlowAdvance(
            state: CountFlowState(
                stationIndex: state.stationIndex,
                elapsedMilliseconds: targetMilliseconds,
                onboardCount: onboardCount,
                nextEventIndex: nextEventIndex,
                countRevision: countRevision,
                phase: phase
            ),
            appliedEvents: appliedEvents
        )
    }

    /// UI가 관찰한 revision과 현재 revision이 같을 때만 닫힘을 판정한다.
    /// stale 또는 자동 하차 중 입력은 문을 닫지 않으며 점수 판정도 하지 않는다.
    static func resolveDoorClose(
        state: CountFlowState,
        plan: StationCountPlan,
        observedCountRevision: Int
    ) -> DoorCloseResolution {
        let isCurrent = observedCountRevision == state.countRevision
        let canResolve = (state.phase == .boarding || state.phase == .timedOut) && isCurrent
        let delta = state.onboardCount - plan.targetOnboard
        let result: CloseDoorResult
        if !canResolve {
            result = .stale
        } else if delta == 0 {
            result = .exact
        } else if delta < 0 {
            result = .under(by: -delta)
        } else {
            result = .over(by: delta)
        }

        return DoorCloseResolution(
            result: result,
            onboardCount: state.onboardCount,
            targetOnboardCount: plan.targetOnboard,
            observedRevision: observedCountRevision,
            actualRevision: state.countRevision
        )
    }

    /// ProductSpec revision 2의 5역·10큐 계획을 seed만으로 재현한다.
    ///
    /// 두 목적지는 2명+1명 큐, 나머지 두 목적지는 1명 큐 세 개로 구성한다.
    /// 다섯 역의 두 큐는 서로 다른 목적지를 가지며 모든 역의 네 문에는 네 목적지가
    /// 정확히 한 번씩 배치되므로 광고나 구매 없이 항상 해결할 수 있다.
    static func routingRunPlan(seed: UInt64) -> RoutingRunPlan {
        var rng = SeededRandom(seed: seed)
        let shuffledDestinations = shuffled(PassengerKind.destinations, using: &rng)
        let twoQueueDestinations = Array(shuffledDestinations.prefix(2))
        let threeQueueDestinations = Array(shuffledDestinations.suffix(2))

        let first = twoQueueDestinations[0]
        let second = twoQueueDestinations[1]
        let third = threeQueueDestinations[0]
        let fourth = threeQueueDestinations[1]

        var stationPairs: [[PassengerKind]] = [
            [first, third],
            [first, fourth],
            [second, third],
            [second, fourth],
            [third, fourth]
        ]
        stationPairs = shuffled(stationPairs, using: &rng)

        var doubledOccurrence: [PassengerKind: Int] = [:]
        for destination in twoQueueDestinations {
            doubledOccurrence[destination] = rng.int(in: 0...1)
        }
        var occurrence: [PassengerKind: Int] = [:]
        var nextQueueID = 0

        let stations = stationPairs.enumerated().map { stationOffset, pair in
            var stationQueues = pair.map { destination in
                let destinationOccurrence = occurrence[destination, default: 0]
                occurrence[destination] = destinationOccurrence + 1
                let passengerCount = doubledOccurrence[destination] == destinationOccurrence ? 2 : 1
                defer { nextQueueID += 1 }
                return RoutingQueue(
                    id: nextQueueID,
                    stationIndex: stationOffset + 1,
                    positionInStation: 0,
                    destination: destination,
                    passengerCount: passengerCount
                )
            }
            if rng.int(in: 0...1) == 1 {
                stationQueues.reverse()
            }
            stationQueues = stationQueues.enumerated().map { position, queue in
                RoutingQueue(
                    id: queue.id,
                    stationIndex: queue.stationIndex,
                    positionInStation: position,
                    destination: queue.destination,
                    passengerCount: queue.passengerCount
                )
            }

            return RoutingStationPlan(
                index: stationOffset + 1,
                doorOrder: shuffled(PassengerKind.destinations, using: &rng),
                queues: stationQueues
            )
        }

        return RoutingRunPlan(seed: seed, stations: stations)
    }

    /// 좌우 한 칸 이동을 네 문 범위 안에서 clamp한다.
    static func moveDoorSelection(
        current: Int,
        move: DoorSelectionMove,
        doorCount: Int = routingDoorCount
    ) -> Int {
        guard doorCount > 0 else { return 0 }
        let clampedCurrent = min(doorCount - 1, max(0, current))
        let offset = move == .left ? -1 : 1
        return min(doorCount - 1, max(0, clampedCurrent + offset))
    }

    /// 선택 문과 현재 큐의 목적지를 비교한다. 잘못된 문이나 범위 밖 선택은 큐를 소비하지 않는다.
    static func resolveRouting(
        queue: RoutingQueue,
        selectedDoorIndex: Int,
        doorOrder: [PassengerKind]
    ) -> RoutingResolution {
        let selectedDestination = doorOrder.indices.contains(selectedDoorIndex)
            ? doorOrder[selectedDoorIndex]
            : nil
        let isCorrect = selectedDestination == queue.destination
        return RoutingResolution(
            outcome: isCorrect ? .correct : .wrong,
            queueID: queue.id,
            selectedDoorIndex: selectedDoorIndex,
            selectedDestination: selectedDestination,
            expectedDestination: queue.destination,
            completedPassengerCount: isCorrect ? queue.passengerCount : 0
        )
    }

    static func stageDifficulty(stage: Int, consecutiveFailures: Int = 0) -> StageDifficulty {
        let level = max(1, stage)
        let base: (TimeInterval, Int, Double, Int, Int, Int)

        switch level {
        case 1:
            base = (32, 250, 1.35, 3, 6, 3)
        case 2:
            base = (35, 420, 1.28, 3, 7, 3)
        case 3:
            base = (38, 620, 1.20, 3, 7, 3)
        case 4:
            base = (42, 850, 1.12, 3, 8, 2)
        case 5:
            base = (45, 1_100, 1.05, 3, 8, 2)
        case 6:
            base = (48, 1_350, 1.00, 4, 9, 1)
        case 7...10:
            base = (
                min(60, 48 + TimeInterval(level - 6) * 3),
                1_350 + (level - 6) * 300,
                max(0.82, 1.0 - Double(level - 6) * 0.045),
                4,
                min(11, 9 + (level - 6) / 2),
                1
            )
        default:
            base = (
                60,
                2_550 + (level - 10) * 340,
                max(0.70, 0.82 - Double(level - 10) * 0.018),
                4,
                11,
                level < 20 ? 1 : 0
            )
        }

        let assisted = consecutiveFailures >= 2
        let baseTargetExited = min(32, 22 + level - 1)
        return StageDifficulty(
            stage: level,
            duration: 60,
            targetScore: assisted
                ? Int(Double(min(1_500, 900 + (level - 1) * 100)) * 0.90)
                : min(1_500, 900 + (level - 1) * 100),
            selectorPeriodScale: base.2 * (assisted ? 1.10 : 1),
            destinationCount: base.3,
            transferInterval: assisted ? min(base.4, 7) : base.4,
            safetyHandles: base.5,
            assisted: assisted,
            targetExited: assisted ? Int(ceil(Double(baseTargetExited) * 0.90)) : baseTargetExited,
            stationCount: 5
        )
    }

    static func stationPlan(index: Int, difficulty: StageDifficulty) -> StationPlan {
        let clampedIndex = min(5, max(1, index))
        let arrayIndex = clampedIndex - 1
        let names = ["첫빛역", "구름역", "노을역", "별빛역", "달빛역"]
        let exitDemands = [5, 6, 6, 7, 8]
        let perfectWindows: [TimeInterval] = [0.25, 0.22, 0.19, 0.17, 0.15]
        let safeWindows: [TimeInterval] = [0.55, 0.48, 0.42, 0.36, 0.32]
        let nearWindows: [TimeInterval] = [0.85, 0.75, 0.65, 0.56, 0.50]
        let speedScales = [1.0, 1.0, 1.10, 1.18, 1.25]

        let exitDemand = exitDemands[arrayIndex]
        let speedScale = speedScales[arrayIndex]
        let assistanceScale = difficulty.assisted ? 1.10 : 1.0
        let approachDuration = 8.0 / speedScale * assistanceScale

        return StationPlan(
            name: names[arrayIndex],
            exitDemand: exitDemand,
            boardDemand: Int(ceil(Double(exitDemand) * (difficulty.assisted ? 0.50 : 0.60))),
            approachDuration: approachDuration,
            optimalBrakeTime: approachDuration * 0.75,
            perfectWindow: perfectWindows[arrayIndex],
            safeWindow: safeWindows[arrayIndex],
            nearWindow: nearWindows[arrayIndex],
            speedScale: speedScale
        )
    }

    static func resolveBrake(tappedAt: TimeInterval?, plan: StationPlan) -> BrakeResolution {
        guard let tappedAt, tappedAt.isFinite else {
            return BrakeResolution(
                timingError: nil,
                grade: .missed,
                exitedCount: 0,
                scoreGained: 0,
                finalOffset: 1
            )
        }

        let timingError = tappedAt - plan.optimalBrakeTime
        let finalOffset = min(
            1,
            max(-1, timingError / max(plan.nearWindow, .leastNonzeroMagnitude))
        )
        guard (0...plan.approachDuration).contains(tappedAt) else {
            return BrakeResolution(
                timingError: timingError,
                grade: .missed,
                exitedCount: 0,
                scoreGained: 0,
                finalOffset: finalOffset
            )
        }

        let timingMagnitude = abs(timingError)
        let grade: BrakeGrade
        let exitRatio: Double
        let score: Int
        if timingMagnitude <= plan.perfectWindow {
            grade = .perfect
            exitRatio = 1
            score = 300
        } else if timingMagnitude <= plan.safeWindow {
            grade = .safe
            exitRatio = 0.80
            score = 200
        } else if timingMagnitude <= plan.nearWindow {
            grade = .near
            exitRatio = 0.50
            score = 100
        } else {
            grade = .missed
            exitRatio = 0
            score = 0
        }

        return BrakeResolution(
            timingError: timingError,
            grade: grade,
            exitedCount: Int(ceil(Double(plan.exitDemand) * exitRatio)),
            scoreGained: score,
            finalOffset: finalOffset
        )
    }

    static func selectorPeriod(at elapsed: TimeInterval, duration: TimeInterval) -> TimeInterval {
        let progress = min(1, max(0, elapsed / max(1, duration)))
        let eased = progress * progress * (3 - 2 * progress)
        return 1.60 + (0.90 - 1.60) * eased
    }

    static func passengerKind(
        boarded: Int,
        destinationCount: Int,
        transferInterval: Int,
        rng: inout SeededRandom
    ) -> PassengerKind {
        if boarded > 0, boarded % max(1, transferInterval) == 0 { return .transfer }
        let available = Array(
            PassengerKind.destinations.prefix(min(4, max(1, destinationCount)))
        )
        return available[rng.int(in: 0...(available.count - 1))]
    }

    static func stationBonus(
        at elapsed: TimeInterval,
        duration: TimeInterval,
        previousStation: Int
    ) -> Int {
        let station = min(4, Int(elapsed / max(1, duration / 4)) + 1)
        return station > previousStation ? 150 : 0
    }

    private static func shuffled<Element>(
        _ values: [Element],
        using rng: inout SeededRandom
    ) -> [Element] {
        guard values.count > 1 else { return values }
        var result = values
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            let swapIndex = rng.int(in: 0...index)
            if index != swapIndex {
                result.swapAt(index, swapIndex)
            }
        }
        return result
    }
}
