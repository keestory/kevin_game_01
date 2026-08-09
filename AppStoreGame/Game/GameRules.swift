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
}
