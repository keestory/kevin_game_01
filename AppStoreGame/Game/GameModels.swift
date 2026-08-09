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

enum BrakeGrade: String, CaseIterable, Codable, Equatable {
    case perfect
    case safe
    case near
    case missed
}

struct StationPlan: Equatable {
    let name: String
    let exitDemand: Int
    let boardDemand: Int
    let approachDuration: TimeInterval
    let optimalBrakeTime: TimeInterval
    let perfectWindow: TimeInterval
    let safeWindow: TimeInterval
    let nearWindow: TimeInterval
    let speedScale: Double
}

struct BrakeResolution: Equatable {
    let timingError: TimeInterval?
    let grade: BrakeGrade
    let exitedCount: Int
    let scoreGained: Int
    /// 정차선 기준 위치를 -1(이른 제동)...0(정위치)...1(늦은 제동)로 정규화한 값.
    let finalOffset: Double
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
    let targetExited: Int
    let stationCount: Int

    var title: String { "\(stage)단계" }
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

/// ProductSpec revision 2에서 한 번의 문 열기 입력으로 처리하는 승객 대기열이다.
/// 오답에서는 같은 큐를 다시 시도할 수 있도록 값 자체는 변경하지 않는다.
struct RoutingQueue: Equatable, Hashable {
    let id: Int
    let stationIndex: Int
    let positionInStation: Int
    let destination: PassengerKind
    let passengerCount: Int
}

/// 한 역에서 사용할 네 문의 목적지 순서와 두 개의 복구 가능한 큐다.
struct RoutingStationPlan: Equatable {
    let index: Int
    let doorOrder: [PassengerKind]
    let queues: [RoutingQueue]
}

/// 하나의 seed에서 결정되는 5역·10큐 목적지 라우팅 계획이다.
struct RoutingRunPlan: Equatable {
    let seed: UInt64
    let stations: [RoutingStationPlan]

    var queues: [RoutingQueue] {
        stations.flatMap(\.queues)
    }

    func passengerTotal(for destination: PassengerKind) -> Int {
        queues
            .filter { $0.destination == destination }
            .reduce(0) { $0 + $1.passengerCount }
    }
}

enum DoorSelectionMove: Equatable {
    case left
    case right
}

enum RoutingOutcome: Equatable {
    case correct
    case wrong
}

/// 문을 열었을 때의 순수 판정값이다. 오답은 승객을 완료시키지 않고 큐를 보존한다.
struct RoutingResolution: Equatable {
    let outcome: RoutingOutcome
    let queueID: Int
    let selectedDoorIndex: Int
    let selectedDestination: PassengerKind?
    let expectedDestination: PassengerKind
    let completedPassengerCount: Int

    var shouldAdvanceQueue: Bool { outcome == .correct }
    var queueRemainsAvailable: Bool { !shouldAdvanceQueue }
}

/// 인원 맞추기 루프의 논리 단계다. 자동 하차가 끝난 뒤에만 문 닫기 입력을 받는다.
enum PassengerFlowPhase: Equatable {
    case automaticExit
    case boarding
    case doorsClosed
    case timedOut
}

enum PassengerFlowDirection: Equatable {
    case exit
    case board
}

/// 한 명 이상의 승객이 문턱을 지나는 논리 이벤트다.
/// 인원 수는 이 이벤트를 reducer가 적용할 때만 바뀌며 SpriteKit action은 값을 바꾸지 않는다.
struct PassengerFlowEvent: Equatable {
    let id: Int
    let offsetMilliseconds: Int
    let direction: PassengerFlowDirection
    let passengerCount: Int
    let visualSeed: UInt64
}

struct StationCountPlan: Equatable {
    let index: Int
    let initialOnboard: Int
    let targetOnboard: Int
    let capacity: Int
    let deadlineMilliseconds: Int
    let minimumTargetHoldMilliseconds: Int
    let events: [PassengerFlowEvent]

    var exitEvents: [PassengerFlowEvent] {
        events.filter { $0.direction == .exit }
    }

    var boardingEvents: [PassengerFlowEvent] {
        events.filter { $0.direction == .board }
    }
}

struct CountRunPlan: Equatable {
    let seed: UInt64
    let stations: [StationCountPlan]
}

/// 프레임 시간과 무관하게 재생할 수 있는 한 역의 권위 상태다.
struct CountFlowState: Equatable {
    let stationIndex: Int
    let elapsedMilliseconds: Int
    let onboardCount: Int
    let nextEventIndex: Int
    let countRevision: Int
    let phase: PassengerFlowPhase
}

struct FlowAdvance: Equatable {
    let state: CountFlowState
    let appliedEvents: [PassengerFlowEvent]
}

enum CloseDoorResult: Equatable {
    case exact
    case under(by: Int)
    case over(by: Int)
    case stale
}

struct DoorCloseResolution: Equatable {
    let result: CloseDoorResult
    let onboardCount: Int
    let targetOnboardCount: Int
    let observedRevision: Int
    let actualRevision: Int

    var shouldCloseDoors: Bool { result != .stale }

    /// 목표보다 적으면 음수, 많으면 양수다. stale 입력은 판정하지 않는다.
    var signedDelta: Int? {
        shouldCloseDoors ? onboardCount - targetOnboardCount : nil
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
    var targetExited = 22
    var stopIndex = 1
    var stationCount = 5
    var approachProgress: Double = 0
    var canBrake = false
    var doorsOpen = false
    var lastBrakeGrade: BrakeGrade?
    var destinationProgress: [PassengerKind: Int] = [
        .circle: 0,
        .triangle: 0,
        .star: 0,
        .square: 0
    ]
    var doorDestinations: [PassengerKind] = PassengerKind.destinations
    var currentQueueSize = 0
    var selectedDoor = 0
    var routingQueueIndex = 0
    var routingQueueCount = 10
    var lastRoutingCorrect: Bool?
    var clockStarted = false
    var onboardCount = 0
    var targetOnboardCount = 0
    var countRevision = 0
    var canCloseDoors = false
    var lastCloseDelta: Int?
    var flowProgress: Double = 0
    var flowPhase: PassengerFlowPhase = .automaticExit

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
        completed ? "\(stage)단계 운행 성공!" : "목표 인원에 다시 도전!"
    }

    var shareText: String {
        "문 닫습니다! 지옥철 \(stage)단계에서 목표 인원을 연속 \(bestChain)번 맞췄어요. 점수 \(score)점"
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
    var version = 3
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
        let storedVersion = try values.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard (1...3).contains(storedVersion) else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: values,
                debugDescription: "Unsupported player profile version \(storedVersion)"
            )
        }
        version = 3
        bestScore = try values.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        totalRuns = try values.decodeIfPresent(Int.self, forKey: .totalRuns) ?? 0
        totalExited = try values.decodeIfPresent(Int.self, forKey: .totalExited) ?? 0
        let storedTutorialSeen = try values.decodeIfPresent(Bool.self, forKey: .tutorialSeen) ?? false
        tutorialSeen = storedVersion < 3 ? false : storedTutorialSeen
        let storedHighestStage = max(1, try values.decodeIfPresent(Int.self, forKey: .highestStage) ?? 1)
        highestStage = storedVersion < 3 ? 1 : storedHighestStage
        consecutiveFailures = storedVersion < 3
            ? 0
            : max(0, try values.decodeIfPresent(Int.self, forKey: .consecutiveFailures) ?? 0)
        freeRescueUsed = storedVersion < 3
            ? false
            : (try values.decodeIfPresent(Bool.self, forKey: .freeRescueUsed) ?? false)
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
