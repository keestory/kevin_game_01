import Foundation

enum AppRoute: Equatable {
    case home
    case game
    case result(RunResult)
}

enum RunPhase: String, Codable, Equatable {
    case ready
    case playing
    case paused
    case finished
}

enum VisualVariant: String, Equatable {
    case precisionNeon
    case impactPop

    static var current: VisualVariant {
        ProcessInfo.processInfo.arguments.contains("-visualB") ? .impactPop : .precisionNeon
    }
}

enum BrickColor: Int, CaseIterable, Codable, Equatable, Hashable {
    case mint
    case coral
    case blue

    var name: String {
        switch self {
        case .mint: "민트"
        case .coral: "코랄"
        case .blue: "블루"
        }
    }

    var tintHex: UInt {
        switch self {
        case .mint: 0x49E2B4
        case .coral: 0xFF6B72
        case .blue: 0x6AA8FF
        }
    }
}

enum BrickPattern: Int, CaseIterable, Codable, Equatable, Hashable {
    case stripe
    case dot
    case grid

    var name: String {
        switch self {
        case .stripe: "줄무늬"
        case .dot: "점무늬"
        case .grid: "격자"
        }
    }

    var badge: String {
        switch self {
        case .stripe: "≡"
        case .dot: "⠿"
        case .grid: "▦"
        }
    }
}

enum BrickMark: Int, CaseIterable, Codable, Equatable, Hashable {
    case circle
    case triangle
    case star

    var name: String {
        switch self {
        case .circle: "원"
        case .triangle: "삼각"
        case .star: "별"
        }
    }

    var badge: String {
        switch self {
        case .circle: "●"
        case .triangle: "▲"
        case .star: "★"
        }
    }
}

struct BrickSignature: Codable, Equatable, Hashable {
    let color: BrickColor
    let pattern: BrickPattern
    let mark: BrickMark
}

enum ShotBrickRole: String, Codable, Equatable {
    case normal
    case support
    case prism
    case negative
}

struct ShotVector: Codable, Equatable {
    var x: Double
    var y: Double

    static let zero = ShotVector(x: 0, y: 0)

    var length: Double { hypot(x, y) }

    func scaled(by scale: Double) -> ShotVector {
        ShotVector(x: x * scale, y: y * scale)
    }

    func normalized(or fallback: ShotVector = ShotVector(x: 0, y: 1)) -> ShotVector {
        let magnitude = length
        guard magnitude > 0.000_001 else { return fallback }
        return scaled(by: 1 / magnitude)
    }
}

struct ShotRect: Codable, Equatable {
    var center: ShotVector
    var width: Double
    var height: Double

    var minX: Double { center.x - width / 2 }
    var maxX: Double { center.x + width / 2 }
    var minY: Double { center.y - height / 2 }
    var maxY: Double { center.y + height / 2 }

    func expanded(by amount: Double) -> ShotRect {
        ShotRect(
            center: center,
            width: width + amount * 2,
            height: height + amount * 2
        )
    }
}

struct ShotBrick: Codable, Equatable, Identifiable {
    let id: Int
    var rect: ShotRect
    let signature: BrickSignature?
    let role: ShotBrickRole
    let maximumHitPoints: Int
    var hitPoints: Int
    let supportIDs: [Int]
    let anchored: Bool
    var isRemoved = false
    var penaltyHits = 0
    var lastPenaltyTick = -10_000
    var eligibleContactRecorded = false
}

struct ShotBall: Codable, Equatable {
    var position: ShotVector
    var velocity: ShotVector
    let radius: Double
}

struct AttributeLinkState: Codable, Equatable {
    var previousSignature: BrickSignature?
    var colorCount = 0
    var patternCount = 0
    var markCount = 0

    var highestCount: Int { max(colorCount, patternCount, markCount) }

    var leadingText: String {
        guard let signature = previousSignature else { return "LINK 준비" }
        if colorCount >= patternCount, colorCount >= markCount {
            return "\(signature.color.name) LINK \(colorCount)/5"
        }
        if patternCount >= markCount {
            return "\(signature.pattern.name) LINK \(patternCount)/5"
        }
        return "\(signature.mark.name) LINK \(markCount)/5"
    }
}

enum ShotRemovalCause: Equatable {
    case direct
    case shockwave
    case unsupportedFall
}

enum ShotSimulationEvent: Equatable {
    case paddleReturn(edgeShot: Bool)
    case brickHit(id: Int, remainingHitPoints: Int)
    case brickRemoved(id: Int, cause: ShotRemovalCause, points: Int)
    case comboChanged(Int)
    case linkChanged(AttributeLinkState)
    case powerActivated
    case powerExpired
    case negativeHit(id: Int, penalty: Int)
    case cleanDrop(id: Int, points: Int)
    case segmentAdvanced(Int)
    case missed
}

struct ReturnShotState: Codable, Equatable {
    let seed: UInt64
    var tick = 0
    var ball: ShotBall
    var paddleX: Double
    var paddleTargetX: Double
    var paddleVelocity = 0.0
    var score: Int64 = 0
    var height = 0
    var combo = 0
    var maxCombo = 0
    var comboGraceTicks = 0
    var link = AttributeLinkState()
    var maxLink = 0
    var powerTicks = 0
    var powerActivations = 0
    var returnShotTicks = 0
    var segment = 0
    var bricks: [ShotBrick]
    var phase: RunPhase = .playing
    var feedback = "같은 속성을 이어 공명 폭주를 만드세요"
    var destroyedBrickCount = 0

    var isPowerActive: Bool { powerTicks > 0 }
}

struct RunSnapshot: Equatable {
    var phase: RunPhase = .ready
    var elapsed: TimeInterval = 0
    var score = 0
    var height = 0
    var combo = 0
    var maxCombo = 0
    var link = AttributeLinkState()
    var maxLink = 0
    var powerProgress: Double = 0
    var powerSeconds: Double = 0
    var powerActivations = 0
    var segment = 1
    var feedback = "끌어서 받아치세요"
    var isReturnShot = false
    var destroyedBrickCount = 0
    var bestScore = 0
    var bestHeight = 0

    var scoreText: String { score.formatted() }
    var heightText: String { "\(height)m" }
}

struct RunResult: Equatable {
    let score: Int
    let height: Int
    let maxCombo: Int
    let maxLink: Int
    let powerActivations: Int
    let destroyedBrickCount: Int
    let dailySeed: UInt64
    let previousBestScore: Int
    let previousBestHeight: Int

    var scoreDeltaFromPreviousBest: Int { score - previousBestScore }
    var heightDeltaFromPreviousBest: Int { height - previousBestHeight }
    var isNewBest: Bool { score > previousBestScore }

    var headline: String {
        height > 0 ? "\(height)m까지 연쇄 돌파!" : "첫 리턴에 다시 도전!"
    }

    var grade: String {
        switch score {
        case 20_000...: "S"
        case 12_000...: "A"
        case 7_000...: "B"
        case 3_000...: "C"
        default: "D"
        }
    }

    var shareText: String {
        "연쇄파괴: 리턴 샷에서 \(score.formatted())점 · \(height)m · 최대 콤보 ×\(maxCombo)!"
    }
}

enum GameEvent {
    case snapshot(RunSnapshot)
    case paddleReturn(edgeShot: Bool)
    case brickDestroyed(points: Int)
    case powerActivated
    case negativeHit
    case cleanDrop
    case finished(RunResult)
}

struct PlayerProfile: Codable, Equatable {
    var version = 1
    var bestScore = 0
    var bestHeight = 0
    var bestCombo = 0
    var bestLink = 0
    var totalRuns = 0
    var tutorialSeen = false

    private enum CodingKeys: String, CodingKey {
        case version
        case bestScore
        case bestHeight
        case bestCombo
        case bestLink
        case totalRuns
        case tutorialSeen
    }

    init() {}

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let storedVersion = try values.decodeIfPresent(Int.self, forKey: .version) ?? 1
        guard storedVersion == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .version,
                in: values,
                debugDescription: "Unsupported Return Shot profile version \(storedVersion)"
            )
        }
        version = 1
        bestScore = max(0, try values.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0)
        bestHeight = max(0, try values.decodeIfPresent(Int.self, forKey: .bestHeight) ?? 0)
        bestCombo = max(0, try values.decodeIfPresent(Int.self, forKey: .bestCombo) ?? 0)
        bestLink = max(0, try values.decodeIfPresent(Int.self, forKey: .bestLink) ?? 0)
        totalRuns = max(0, try values.decodeIfPresent(Int.self, forKey: .totalRuns) ?? 0)
        tutorialSeen = try values.decodeIfPresent(Bool.self, forKey: .tutorialSeen) ?? false
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
