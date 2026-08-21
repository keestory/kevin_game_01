import Foundation

enum DescentResearchRules {
    /// Increment this whenever a gameplay-rule change would make research runs
    /// incomparable. Both Choice Arena variants must use the same value.
    static let currentVersion = "descent-rev5-break-flow-frenzy-r1"
}

/// Research-only variant assignment. This never enters `DescentState`, so the
/// authoritative fixed-tick simulation and checksum stay independent of analytics.
enum DescentResearchVariant: String, CaseIterable, Codable, Equatable {
    case noArena
    case choiceArena
}

enum DescentResearchAbandonReason: String, Codable, Equatable {
    case home
    case replacedRun
}

enum DescentResearchResultAction: String, Codable, Equatable {
    case retry
    case home
}

enum DescentResearchAssignmentIssue: String, Equatable {
    case missingParticipant
    case missingOrderIndex
    case variantOrderMismatch

    var operatorMessage: String {
        switch self {
        case .missingParticipant:
            "참가자 번호 P01–P10이 필요합니다."
        case .missingOrderIndex:
            "블록 순서 1 또는 2가 필요합니다."
        case .variantOrderMismatch:
            "P01–P05는 A→B, P06–P10은 B→A 순서만 허용됩니다."
        }
    }
}

struct DescentResearchContext: Codable, Equatable {
    let researchSessionID: UUID
    let runID: UUID
    let participantSlot: String?
    let orderIndex: Int?
    let variant: DescentResearchVariant
    let seed: UInt64
    let ship: DescentShipKind
    let runIndex: Int
    let bestScoreBefore: Int
    let rulesVersion: String
}

struct DescentResearchInputSummary: Codable, Equatable {
    let firstMoveMilliseconds: Int?
    let activeTouchMilliseconds: Int
    let activePlayMilliseconds: Int
    let meaningfulLaneChanges: Int
}

struct DescentResearchRunSummary: Codable, Equatable {
    let tick: Int
    let score: Int
    let previousBestScore: Int
    let maxCombo: Int
    let dangerSaves: Int
    let dropsCollected: Int
    let breaches: Int
    let redlineBonusScore: Int
    let frenzyBonusScore: Int
    let frenzyTriggerCount: Int
    let frenzyActiveTicks: Int
    let maxDirectChain: Int
    let endReason: DescentEndReason

    init(
        tick: Int,
        score: Int,
        previousBestScore: Int,
        maxCombo: Int,
        dangerSaves: Int,
        dropsCollected: Int,
        breaches: Int,
        redlineBonusScore: Int,
        frenzyBonusScore: Int = 0,
        frenzyTriggerCount: Int = 0,
        frenzyActiveTicks: Int = 0,
        maxDirectChain: Int = 0,
        endReason: DescentEndReason
    ) {
        self.tick = tick
        self.score = score
        self.previousBestScore = previousBestScore
        self.maxCombo = maxCombo
        self.dangerSaves = dangerSaves
        self.dropsCollected = dropsCollected
        self.breaches = breaches
        self.redlineBonusScore = redlineBonusScore
        self.frenzyBonusScore = frenzyBonusScore
        self.frenzyTriggerCount = frenzyTriggerCount
        self.frenzyActiveTicks = frenzyActiveTicks
        self.maxDirectChain = maxDirectChain
        self.endReason = endReason
    }

    var personalBestDelta: Int { score - previousBestScore }
}

enum DescentResearchEvent: Codable, Equatable {
    case runStarted
    case firstInput(tick: Int, elapsedMilliseconds: Int)
    case firstDestroy(tick: Int)
    case firstDropCollected(tick: Int, kind: DescentSkillKind)
    case choicePresented(tick: Int, score: Int)
    case choiceSelected(choice: DescentArenaChoice, activeLatencyMilliseconds: Int)
    case optionalRetryWindowOpened(durationMilliseconds: Int)
    case inputSummary(DescentResearchInputSummary)
    case runFinished(DescentResearchRunSummary)
    case runAbandoned(tick: Int, reason: DescentResearchAbandonReason)
    case resultAction(action: DescentResearchResultAction, latencyMilliseconds: Int)

    fileprivate var uniquenessKey: String {
        switch self {
        case .runStarted: "runStarted"
        case .firstInput: "firstInput"
        case .firstDestroy: "firstDestroy"
        case .firstDropCollected: "firstDropCollected"
        case .choicePresented: "choicePresented"
        case .choiceSelected: "choiceSelected"
        case .optionalRetryWindowOpened: "optionalRetryWindowOpened"
        case .inputSummary: "inputSummary"
        case .runFinished: "runFinished"
        case .runAbandoned: "runAbandoned"
        case .resultAction: "resultAction"
        }
    }
}

struct DescentResearchSequencedEvent: Codable, Equatable {
    let sequence: Int
    let event: DescentResearchEvent
}

struct DescentResearchRunEnvelope: Codable, Equatable {
    static let currentSchemaVersion = 2

    let schemaVersion: Int
    let context: DescentResearchContext
    let events: [DescentResearchSequencedEvent]

    init(
        schemaVersion: Int = currentSchemaVersion,
        context: DescentResearchContext,
        events: [DescentResearchSequencedEvent]
    ) {
        self.schemaVersion = schemaVersion
        self.context = context
        self.events = events
    }
}

@MainActor
protocol DescentResearchEventSink: AnyObject {
    func persist(_ envelope: DescentResearchRunEnvelope) throws
    func deleteAll() throws
}

@MainActor
final class NoopDescentResearchEventSink: DescentResearchEventSink {
    func persist(_ envelope: DescentResearchRunEnvelope) throws {}
    func deleteAll() throws {}
}

@MainActor
final class InMemoryDescentResearchEventSink: DescentResearchEventSink {
    private(set) var envelopes: [DescentResearchRunEnvelope] = []

    func persist(_ envelope: DescentResearchRunEnvelope) throws {
        if let index = envelopes.firstIndex(where: {
            $0.context.runID == envelope.context.runID
        }) {
            envelopes[index] = envelope
        } else {
            envelopes.append(envelope)
        }
    }

    func deleteAll() throws {
        envelopes.removeAll(keepingCapacity: false)
    }
}

/// Bounded, non-authoritative in-memory recorder for one run. It deliberately
/// has no raw touch coordinates, install identifier, accessibility flags, network
/// transport, or gameplay mutation API.
@MainActor
final class DescentResearchSession {
    static let maximumEventsPerRun = 64

    let context: DescentResearchContext
    private let sink: any DescentResearchEventSink
    private(set) var events: [DescentResearchSequencedEvent] = []
    private(set) var lastPersistenceError: String?
    private var uniquenessKeys: Set<String> = []
    private var nextSequence = 0
    private var finishedUptime: TimeInterval?
    private var resultInactiveUptime: TimeInterval?
    private var resultInactiveDuration: TimeInterval = 0

    var hasTerminalEvent: Bool {
        uniquenessKeys.contains("runFinished") || uniquenessKeys.contains("runAbandoned")
    }

    init(context: DescentResearchContext, sink: any DescentResearchEventSink) {
        self.context = context
        self.sink = sink
        record(.runStarted)
    }

    func record(_ event: DescentResearchEvent) {
        guard events.count < Self.maximumEventsPerRun else { return }
        let key = event.uniquenessKey
        guard !uniquenessKeys.contains(key) else { return }
        guard terminalTransitionIsValid(for: event) else { return }
        uniquenessKeys.insert(key)
        events.append(DescentResearchSequencedEvent(sequence: nextSequence, event: event))
        nextSequence += 1
        if case .runFinished = event {
            finishedUptime = ProcessInfo.processInfo.systemUptime
        }
    }

    func recordResultAction(_ action: DescentResearchResultAction) {
        guard uniquenessKeys.contains("runFinished") else { return }
        let elapsed: Int
        if let finishedUptime {
            let now = ProcessInfo.processInfo.systemUptime
            if let inactive = resultInactiveUptime {
                resultInactiveDuration += max(0, now - inactive)
                resultInactiveUptime = nil
            }
            elapsed = max(0, Int(((now - finishedUptime - resultInactiveDuration) * 1_000).rounded()))
        } else {
            elapsed = 0
        }
        record(.resultAction(action: action, latencyMilliseconds: elapsed))
    }

    func setApplicationActive(_ isActive: Bool) {
        guard uniquenessKeys.contains("runFinished"),
              !uniquenessKeys.contains("resultAction") else { return }
        let now = ProcessInfo.processInfo.systemUptime
        if isActive, let inactive = resultInactiveUptime {
            resultInactiveDuration += max(0, now - inactive)
            resultInactiveUptime = nil
        } else if !isActive, resultInactiveUptime == nil {
            resultInactiveUptime = now
        }
    }

    func flush() {
        do {
            try sink.persist(
                DescentResearchRunEnvelope(context: context, events: events)
            )
            lastPersistenceError = nil
        } catch {
            // Research telemetry must never interrupt or change gameplay.
            lastPersistenceError = String(describing: error)
        }
    }

    private func terminalTransitionIsValid(for event: DescentResearchEvent) -> Bool {
        switch event {
        case .runFinished, .runAbandoned:
            return !hasTerminalEvent
        case .resultAction:
            return uniquenessKeys.contains("runFinished")
        default:
            return !hasTerminalEvent
        }
    }
}

struct DescentResearchConfiguration: Equatable {
    let isEnabled: Bool
    let variant: DescentResearchVariant
    let participantSlot: String?
    let orderIndex: Int?

    var assignmentIssue: DescentResearchAssignmentIssue? {
        guard participantSlot != nil else { return .missingParticipant }
        guard let orderIndex else { return .missingOrderIndex }
        guard variant == expectedVariant(for: participantNumber, orderIndex: orderIndex) else {
            return .variantOrderMismatch
        }
        return nil
    }

    var isDataCollectionEnabled: Bool {
        isEnabled && assignmentIssue == nil
    }

    /// Fixed per-participant seed so A/B parity survives a date change.
    var assignedSeed: UInt64? {
        guard let participantNumber else { return nil }
        return 0xD35C_EA71_2026_0000 ^ UInt64(participantNumber)
    }

    static func current(arguments: [String]) -> Self {
#if DEBUG
        guard arguments.contains("-descentResearch") else {
            return Self(
                isEnabled: false,
                variant: .choiceArena,
                participantSlot: nil,
                orderIndex: nil
            )
        }
        return Self(
            isEnabled: true,
            variant: arguments.contains("-descentVariantNoArena") ? .noArena : .choiceArena,
            participantSlot: participantSlot(in: arguments),
            orderIndex: boundedInteger(after: "-descentOrderIndex", in: arguments, range: 1...2)
        )
#else
        return Self(
            isEnabled: false,
            variant: .choiceArena,
            participantSlot: nil,
            orderIndex: nil
        )
#endif
    }

    private static func participantSlot(in arguments: [String]) -> String? {
        guard let value = value(after: "-descentParticipant", in: arguments),
              value.count == 3,
              value.first == "P",
              let number = Int(value.dropFirst()),
              (1...10).contains(number) else { return nil }
        return String(format: "P%02d", number)
    }

    private var participantNumber: Int? {
        participantSlot.flatMap { Int($0.dropFirst()) }
    }

    private func expectedVariant(
        for participantNumber: Int?,
        orderIndex: Int
    ) -> DescentResearchVariant? {
        guard let participantNumber else { return nil }
        if participantNumber <= 5 {
            return orderIndex == 1 ? .noArena : .choiceArena
        }
        return orderIndex == 1 ? .choiceArena : .noArena
    }

    private static func boundedInteger(
        after flag: String,
        in arguments: [String],
        range: ClosedRange<Int>
    ) -> Int? {
        guard let value = value(after: flag, in: arguments),
              let integer = Int(value),
              range.contains(integer) else { return nil }
        return integer
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
