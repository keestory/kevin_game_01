import Foundation

enum AppRoute: Equatable {
    case home
    case game
    case result(RunResult)
}

enum RunPhase: Equatable {
    case ready
    case playing
    case paused
    case awaitingRescue
    case finished
}

struct StageDifficulty: Equatable {
    let stage: Int
    let duration: TimeInterval
    let targetScore: Int
    let selectorPeriodScale: Double
    let destinationCount: Int
    let transferInterval: Int
    let safetyHandles: Int
    let assisted: Bool

    var title: String { "\(stage)역" }
}

enum PassengerKind: Int, CaseIterable, Codable, Equatable, Hashable {
    case circle
    case triangle
    case star
    case square
    case transfer

    static let destinations: [PassengerKind] = [.circle, .triangle, .star, .square]

    var badge: String {
        switch self {
        case .circle: "●"
        case .triangle: "▲"
        case .star: "★"
        case .square: "■"
        case .transfer: "↔"
        }
    }

    var name: String {
        switch self {
        case .circle: "동그라미역"
        case .triangle: "세모역"
        case .star: "별빛역"
        case .square: "네모역"
        case .transfer: "환승객"
        }
    }

    var tintHex: UInt {
        switch self {
        case .circle: 0xFF6B72
        case .triangle: 0x3FD4A2
        case .star: 0xFFD84D
        case .square: 0x7B9CFF
        case .transfer: 0xB993FF
        }
    }
}

struct GridPosition: Hashable, Equatable {
    let column: Int
    let row: Int
}

struct PlacementResolution: Equatable {
    let placed: Bool
    let overflowed: Bool
    let removedCount: Int
    let cascadeCount: Int
    let scoreGained: Int
}

struct RunSnapshot: Equatable {
    var phase: RunPhase = .ready
    var elapsed: TimeInterval = 0
    var duration: TimeInterval = 60
    var stage = 1
    var targetScore = 300
    var score = 0
    var boarded = 0
    var exited = 0
    var bestChain = 0
    var currentChain = 0
    var station = 1
    var nextPassenger: PassengerKind = .circle
    var upcoming: [PassengerKind] = [.triangle, .star]
    var selectedColumn = 2
    var lastWasPerfect = false
    var safetyHandles = 3
    var rescueUsed = false
    var assisted = false

    var remaining: TimeInterval { max(0, duration - elapsed) }

    var timeText: String {
        String(format: "%02d", max(0, Int(remaining.rounded(.up))))
    }

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, elapsed / duration))
    }

    var scoreProgress: Double {
        guard targetScore > 0 else { return 0 }
        return min(1, max(0, Double(score) / Double(targetScore)))
    }
}

struct RunResult: Equatable {
    let score: Int
    let boarded: Int
    let exited: Int
    let bestChain: Int
    let completed: Bool
    let dailySeed: UInt64
    let stage: Int
    let targetScore: Int
    let rescueUsed: Bool
    let assisted: Bool

    var grade: String {
        let ratio = Double(score) / Double(max(1, targetScore))
        return switch ratio {
        case 1.5...: "S"
        case 1.25...: "A"
        case 1.0...: "B"
        case 0.75...: "C"
        default: "D"
        }
    }

    var headline: String {
        completed ? "\(stage)역 통과!" : "한 칸만 비웠다면 출발!"
    }

    var shareText: String {
        "한 칸만! \(stage)역에서 \(exited)명이 무사히 내렸어요. 점수 \(score)점 · 최고 환승 ×\(max(1, bestChain))"
    }
}

enum GameEvent {
    case snapshot(RunSnapshot)
    case perfect
    case match(Int)
    case overflow
    case rescueRequested
    case finished(RunResult)
}

struct PlayerProfile: Codable, Equatable {
    var version = 2
    var bestScore = 0
    var totalRuns = 0
    var totalExited = 0
    var tutorialSeen = false
    var highestStage = 1
    var consecutiveFailures = 0
    var freeRescueUsed = false
    var rewardedContinuesUsedTotal = 0

    private enum CodingKeys: String, CodingKey {
        case version
        case bestScore
        case totalRuns
        case totalExited
        case tutorialSeen
        case highestStage
        case consecutiveFailures
        case freeRescueUsed
        case rewardedContinuesUsedTotal
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        version = 2
        bestScore = try values.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        totalRuns = try values.decodeIfPresent(Int.self, forKey: .totalRuns) ?? 0
        totalExited = try values.decodeIfPresent(Int.self, forKey: .totalExited) ?? 0
        tutorialSeen = try values.decodeIfPresent(Bool.self, forKey: .tutorialSeen) ?? false
        highestStage = max(1, try values.decodeIfPresent(Int.self, forKey: .highestStage) ?? 1)
        consecutiveFailures = max(0, try values.decodeIfPresent(Int.self, forKey: .consecutiveFailures) ?? 0)
        freeRescueUsed = try values.decodeIfPresent(Bool.self, forKey: .freeRescueUsed) ?? false
        rewardedContinuesUsedTotal = max(
            0,
            try values.decodeIfPresent(Int.self, forKey: .rewardedContinuesUsedTotal) ?? 0
        )
    }
}

struct SeededRandom {
    private(set) var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        let width = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % width)
    }
}

enum DailySeed {
    static func current(calendar: Calendar = .current, date: Date = .now) -> UInt64 {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let number = (parts.year ?? 2026) * 10_000
            + (parts.month ?? 1) * 100
            + (parts.day ?? 1)
        return UInt64(number)
    }
}
