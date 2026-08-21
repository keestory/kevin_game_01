import Foundation

enum DescentResearchSequence: String, CaseIterable, Equatable {
    case ab = "AB"
    case ba = "BA"
}

enum DescentResearchTerminalKind: String, Equatable {
    case finished
    case abandoned
    case missing
    case invalid
}

enum DescentResearchViolationCode: String, CaseIterable, Equatable, Comparable {
    case unsupportedSchemaVersion
    case invalidParticipantSlot
    case missingParticipant
    case invalidOrderIndex
    case unexpectedVariantOrder
    case missingVariant
    case duplicateRunID
    case invalidRunIndex
    case duplicateRunIndex
    case eventArrayOutOfOrder
    case nonContiguousEventSequence
    case duplicateEvent
    case runStartedCount
    case runStartedOrder
    case terminalCount
    case eventAfterTerminal
    case resultActionOrder
    case invalidResultActionLatency
    case optionalRetryWindowCount
    case optionalRetryWindowOrder
    case invalidOptionalRetryWindow
    case inputSummaryCount
    case invalidInputSummary
    case invalidBestScoreBaseline
    case summaryBaselineMismatch
    case invalidScoreBreakdown
    case choiceEventInNoArena
    case choicePresentedCount
    case choiceSelectedCount
    case choiceOrder
    case invalidChoicePresentedTick
    case invalidChoiceLatency
    case seedMismatch
    case shipMismatch
    case missingRulesVersion
    case unsupportedRulesVersion
    case missingRequiredRun
    case requiredRunNotFinished

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct DescentResearchViolation: Equatable {
    let code: DescentResearchViolationCode
    let participantSlot: String?
    let variant: DescentResearchVariant?
    let runID: UUID?
    let detail: String
}

struct DescentResearchRunReport: Equatable {
    let participantSlot: String?
    let sequence: DescentResearchSequence?
    let variant: DescentResearchVariant
    let orderIndex: Int?
    let runID: UUID
    let runIndex: Int
    let seed: UInt64
    let ship: DescentShipKind
    let rulesVersion: String
    let terminalKind: DescentResearchTerminalKind
    let finishSummary: DescentResearchRunSummary?
    let abandonReason: DescentResearchAbandonReason?
    let activeTouchMilliseconds: Int?
    let activePlayMilliseconds: Int?
    let meaningfulLaneChanges: Int?
    let selectedChoice: DescentArenaChoice?
    let choiceLatencyMilliseconds: Int?
    let resultAction: DescentResearchResultAction?
    let resultActionLatencyMilliseconds: Int?
    let optionalRetryWindowMilliseconds: Int?
    let violationCodes: [DescentResearchViolationCode]

    var comparableScore: Int? {
        guard let finishSummary,
              finishSummary.score >= 0,
              finishSummary.redlineBonusScore >= 0,
              finishSummary.redlineBonusScore <= finishSummary.score else { return nil }
        return finishSummary.score - finishSummary.redlineBonusScore
    }

    var activeTouchRatio: Double? {
        guard let activeTouchMilliseconds,
              let activePlayMilliseconds,
              activePlayMilliseconds > 0,
              activeTouchMilliseconds >= 0,
              activeTouchMilliseconds <= activePlayMilliseconds else { return nil }
        return Double(activeTouchMilliseconds) / Double(activePlayMilliseconds)
    }

    var isDataQualityValid: Bool { violationCodes.isEmpty }
    var didFinish: Bool { terminalKind == .finished && finishSummary != nil }
}

struct DescentResearchParticipantVariantSummary: Equatable {
    let participantSlot: String
    let sequence: DescentResearchSequence
    let variant: DescentResearchVariant
    let orderIndex: Int
    let seed: UInt64?
    let ship: DescentShipKind?
    let requiredRun1Finished: Bool
    let requiredRun2Finished: Bool
    let retryAfterRun2WithinSixtySeconds: Bool
    let voluntaryThirdRunCompleted: Bool
    let run1ComparableScore: Int?
    let run3ComparableScore: Int?
    let run1ToRun3TwentyPercentGain: Bool?
    let requiredRunMedianActiveTouchRatio: Double?
    let isDataQualityValid: Bool
}

struct DescentResearchParticipantSummary: Equatable {
    let participantSlot: String
    let sequence: DescentResearchSequence
    let noArena: DescentResearchParticipantVariantSummary
    let choiceArena: DescentResearchParticipantVariantSummary
    let pairedRequiredRunActiveTouchDelta: Double?
    let isDataQualityValid: Bool
}

/// The three Primary metrics from `docs/03-product/analytics-plan.md` only.
/// This value deliberately reports counts and medians; it does not infer retention
/// or manufacture a statistical significance claim from the ten-person study.
struct DescentResearchPrimarySummary: Equatable {
    let dataQualityValidParticipantCount: Int
    let noArenaVoluntaryThirdRunCompletions: Int
    let choiceArenaVoluntaryThirdRunCompletions: Int
    let voluntaryThirdRunPairedUpliftCount: Int
    let noArenaRun1ToRun3GainCount: Int
    let choiceArenaRun1ToRun3GainCount: Int
    let run1ToRun3GainPairedUpliftCount: Int
    let choiceArenaRequiredRunMedianActiveTouchRatio: Double?
    let pairedRequiredRunActiveTouchDeltaMedian: Double?
}

struct DescentResearchReport: Equatable {
    static let expectedParticipantSlots = (1...10).map {
        String(format: "P%02d", $0)
    }

    let runs: [DescentResearchRunReport]
    let participants: [DescentResearchParticipantSummary]
    let primary: DescentResearchPrimarySummary
    let violations: [DescentResearchViolation]

    var isDataQualityValid: Bool { violations.isEmpty }

    static func make(from envelopes: [DescentResearchRunEnvelope]) -> Self {
        let groupedByRunID = Dictionary(grouping: envelopes, by: { $0.context.runID })
        var runs: [DescentResearchRunReport] = []
        var violations: [DescentResearchViolation] = []

        for runID in groupedByRunID.keys.sorted(by: { $0.uuidString < $1.uuidString }) {
            guard let candidates = groupedByRunID[runID] else { continue }
            let sortedCandidates = candidates.sorted {
                stableEnvelopeSignature($0) < stableEnvelopeSignature($1)
            }
            guard let envelope = sortedCandidates.first else { continue }
            var result = validate(envelope)
            if sortedCandidates.count > 1 {
                let violation = DescentResearchViolation(
                    code: .duplicateRunID,
                    participantSlot: envelope.context.participantSlot,
                    variant: envelope.context.variant,
                    runID: runID,
                    detail: "run_id_count=\(sortedCandidates.count)"
                )
                result.violations.append(violation)
                result.run = replacingViolationCodes(
                    in: result.run,
                    with: result.violations.map(\.code)
                )
            }
            runs.append(result.run)
            violations.append(contentsOf: result.violations)
        }

        runs.sort(by: runSort)
        let participantResult = buildParticipantSummaries(from: runs)
        violations.append(contentsOf: participantResult.violations)
        let sortedViolations = violations.sorted(by: violationSort)
        let participants = participantResult.participants
        return Self(
            runs: runs.map { run in
                let codes = sortedViolations
                    .filter { $0.runID == run.runID }
                    .map(\.code)
                guard !codes.isEmpty else { return run }
                return replacingViolationCodes(
                    in: run,
                    with: Array(Set(codes)).sorted()
                )
            },
            participants: participants,
            primary: makePrimarySummary(participants),
            violations: sortedViolations
        )
    }

    func csvData() -> Data {
        let header = [
            "participant_slot", "sequence", "variant_id", "order_index",
            "run_id", "run_index", "seed_id", "ship_kind", "rules_version",
            "terminal", "end_reason", "score", "redline_bonus_score",
            "frenzy_bonus_score", "frenzy_trigger_count",
            "frenzy_active_ticks", "max_direct_chain",
            "comparable_score", "active_touch_ms", "active_play_ms",
            "active_touch_ratio", "meaningful_lane_changes", "arena_choice",
            "choice_latency_ms", "result_action", "result_action_latency_ms",
            "optional_retry_window_ms",
            "voluntary_third_run_completed", "run1_to_run3_20pct_gain",
            "is_data_quality_valid", "violation_codes"
        ]
        let summaries = Dictionary(uniqueKeysWithValues: participants.flatMap {
            [
                (Self.participantVariantKey($0.participantSlot, .noArena), $0.noArena),
                (Self.participantVariantKey($0.participantSlot, .choiceArena), $0.choiceArena)
            ]
        })
        var lines = [header.map(Self.escapeCSV).joined(separator: ",")]
        for run in runs {
            let variantSummary = run.participantSlot.flatMap {
                summaries[Self.participantVariantKey($0, run.variant)]
            }
            let score = run.finishSummary.map { String($0.score) } ?? ""
            let redlineBonus = run.finishSummary.map { String($0.redlineBonusScore) } ?? ""
            let frenzyBonus = run.finishSummary.map { String($0.frenzyBonusScore) } ?? ""
            let frenzyTriggerCount = run.finishSummary.map { String($0.frenzyTriggerCount) } ?? ""
            let frenzyActiveTicks = run.finishSummary.map { String($0.frenzyActiveTicks) } ?? ""
            let maxDirectChain = run.finishSummary.map { String($0.maxDirectChain) } ?? ""
            let voluntaryThird = variantSummary.map {
                Self.booleanString($0.voluntaryThirdRunCompleted)
            } ?? ""
            let twentyPercentGain = variantSummary?.run1ToRun3TwentyPercentGain.map {
                Self.booleanString($0)
            } ?? ""
            let row: [String] = [
                run.participantSlot ?? "",
                run.sequence?.rawValue ?? "",
                Self.variantID(run.variant),
                run.orderIndex.map(String.init) ?? "",
                run.runID.uuidString.lowercased(),
                String(run.runIndex),
                String(run.seed),
                Self.shipID(run.ship),
                run.rulesVersion,
                run.terminalKind.rawValue,
                Self.endReasonID(run),
                score,
                redlineBonus,
                frenzyBonus,
                frenzyTriggerCount,
                frenzyActiveTicks,
                maxDirectChain,
                run.comparableScore.map(String.init) ?? "",
                run.activeTouchMilliseconds.map(String.init) ?? "",
                run.activePlayMilliseconds.map(String.init) ?? "",
                run.activeTouchRatio.map(Self.decimalString) ?? "",
                run.meaningfulLaneChanges.map(String.init) ?? "",
                run.selectedChoice.map(Self.choiceID) ?? "",
                run.choiceLatencyMilliseconds.map(String.init) ?? "",
                run.resultAction?.rawValue ?? "",
                run.resultActionLatencyMilliseconds.map(String.init) ?? "",
                run.optionalRetryWindowMilliseconds.map(String.init) ?? "",
                voluntaryThird,
                twentyPercentGain,
                Self.booleanString(run.isDataQualityValid),
                run.violationCodes.map(\.rawValue).sorted().joined(separator: "|")
            ]
            lines.append(row.map(Self.escapeCSV).joined(separator: ","))
        }
        return Data((lines.joined(separator: "\r\n") + "\r\n").utf8)
    }
}

private extension DescentResearchReport {
    struct ValidationResult {
        var run: DescentResearchRunReport
        var violations: [DescentResearchViolation]
    }

    struct ParticipantBuildResult {
        let participants: [DescentResearchParticipantSummary]
        let violations: [DescentResearchViolation]
    }

    enum EventKind: String {
        case runStarted
        case firstInput
        case firstDestroy
        case firstDropCollected
        case choicePresented
        case choiceSelected
        case optionalRetryWindowOpened
        case inputSummary
        case runFinished
        case runAbandoned
        case resultAction
    }

    static func validate(_ envelope: DescentResearchRunEnvelope) -> ValidationResult {
        let context = envelope.context
        let participant = normalizedParticipantSlot(context.participantSlot)
        let sequence = participant.map(sequenceForParticipant)
        var violations: [DescentResearchViolation] = []

        func append(_ code: DescentResearchViolationCode, _ detail: String) {
            violations.append(DescentResearchViolation(
                code: code,
                participantSlot: participant,
                variant: context.variant,
                runID: context.runID,
                detail: detail
            ))
        }

        if envelope.schemaVersion != DescentResearchRunEnvelope.currentSchemaVersion {
            append(.unsupportedSchemaVersion, "schema_version=\(envelope.schemaVersion)")
        }
        if participant == nil {
            append(.invalidParticipantSlot, "participant_slot_invalid")
        }
        if context.orderIndex != 1 && context.orderIndex != 2 {
            append(.invalidOrderIndex, "order_index=\(context.orderIndex.map(String.init) ?? "nil")")
        }
        if context.runIndex < 1 {
            append(.invalidRunIndex, "run_index=\(context.runIndex)")
        }
        if (context.runIndex == 1 && context.bestScoreBefore != 0)
            || (context.runIndex > 1 && context.bestScoreBefore < 0) {
            append(
                .invalidBestScoreBaseline,
                "run_index=\(context.runIndex);best_score_before=\(context.bestScoreBefore)"
            )
        }
        if context.rulesVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            append(.missingRulesVersion, "rules_version_empty")
        } else if context.rulesVersion != DescentResearchRules.currentVersion {
            append(
                .unsupportedRulesVersion,
                "rules_version=\(context.rulesVersion)"
            )
        }

        let originalSequences = envelope.events.map(\.sequence)
        let sortedEvents = envelope.events.sorted {
            if $0.sequence != $1.sequence { return $0.sequence < $1.sequence }
            return eventSignature($0.event) < eventSignature($1.event)
        }
        let sortedSequences = sortedEvents.map(\.sequence)
        if originalSequences != sortedSequences {
            append(.eventArrayOutOfOrder, "event_sequence_array_not_ascending")
        }
        if sortedSequences != Array(0..<sortedSequences.count) {
            append(.nonContiguousEventSequence, "event_sequences=\(sortedSequences.map(String.init).joined(separator: "|"))")
        }

        let groupedEvents = Dictionary(grouping: sortedEvents, by: { eventKind($0.event) })
        for kind in groupedEvents.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            let count = groupedEvents[kind]?.count ?? 0
            if count > 1 {
                append(.duplicateEvent, "event=\(kind.rawValue);count=\(count)")
            }
        }

        let started = groupedEvents[.runStarted] ?? []
        if started.count != 1 {
            append(.runStartedCount, "run_started_count=\(started.count)")
        } else if started[0].sequence != 0 {
            append(.runStartedOrder, "run_started_sequence=\(started[0].sequence)")
        }

        let finishedEvents = groupedEvents[.runFinished] ?? []
        let abandonedEvents = groupedEvents[.runAbandoned] ?? []
        let terminalEvents = (finishedEvents + abandonedEvents).sorted { $0.sequence < $1.sequence }
        if terminalEvents.count != 1 {
            append(.terminalCount, "terminal_count=\(terminalEvents.count)")
        }
        if let terminalSequence = terminalEvents.first?.sequence {
            for event in sortedEvents where event.sequence > terminalSequence {
                if eventKind(event.event) != .resultAction {
                    append(.eventAfterTerminal, "event=\(eventKind(event.event).rawValue)")
                }
            }
        }

        let resultEvents = groupedEvents[.resultAction] ?? []
        if let result = resultEvents.first {
            if finishedEvents.count != 1 || result.sequence <= (finishedEvents.first?.sequence ?? .max) {
                append(.resultActionOrder, "result_action_without_prior_finished")
            }
            if case .resultAction(_, let latencyMilliseconds) = result.event,
               latencyMilliseconds < 0 {
                append(.invalidResultActionLatency, "result_latency_ms=\(latencyMilliseconds)")
            }
        }

        let retryWindowEvents = groupedEvents[.optionalRetryWindowOpened] ?? []
        if context.runIndex == 2, finishedEvents.count == 1 {
            if retryWindowEvents.count != 1 {
                append(
                    .optionalRetryWindowCount,
                    "optional_retry_window_count=\(retryWindowEvents.count)"
                )
            }
        } else if !retryWindowEvents.isEmpty {
            append(
                .optionalRetryWindowCount,
                "optional_retry_window_unexpected_for_run=\(context.runIndex)"
            )
        }
        var retryWindowMilliseconds: Int?
        if let event = retryWindowEvents.first,
           case .optionalRetryWindowOpened(let durationMilliseconds) = event.event {
            retryWindowMilliseconds = durationMilliseconds
            if durationMilliseconds != 60_000 {
                append(
                    .invalidOptionalRetryWindow,
                    "optional_retry_window_ms=\(durationMilliseconds)"
                )
            }
            if let finishedSequence = finishedEvents.first?.sequence,
               event.sequence >= finishedSequence {
                append(.optionalRetryWindowOrder, "optional_retry_window_not_before_finished")
            }
        }

        let inputEvents = groupedEvents[.inputSummary] ?? []
        if finishedEvents.count == 1 && inputEvents.count != 1 {
            append(.inputSummaryCount, "input_summary_count=\(inputEvents.count)")
        }
        var inputSummary: DescentResearchInputSummary?
        if let event = inputEvents.first, case .inputSummary(let value) = event.event {
            inputSummary = value
            if value.activePlayMilliseconds <= 0
                || value.activeTouchMilliseconds < 0
                || value.activeTouchMilliseconds > value.activePlayMilliseconds
                || value.meaningfulLaneChanges < 0
                || (value.firstMoveMilliseconds.map { $0 < 0 || $0 > value.activePlayMilliseconds } ?? false) {
                append(.invalidInputSummary, "input_summary_out_of_bounds")
            }
        }

        var finishSummary: DescentResearchRunSummary?
        if let event = finishedEvents.first, case .runFinished(let value) = event.event {
            finishSummary = value
            if value.previousBestScore != context.bestScoreBefore {
                append(.summaryBaselineMismatch, "summary_previous_best=\(value.previousBestScore)")
            }
            if value.score < 0
                || value.redlineBonusScore < 0
                || value.redlineBonusScore > value.score
                || value.frenzyBonusScore < 0
                || value.frenzyBonusScore > value.score
                || value.redlineBonusScore + value.frenzyBonusScore > value.score
                || value.frenzyTriggerCount < 0
                || value.frenzyActiveTicks < 0
                || value.frenzyActiveTicks > value.tick
                || value.maxDirectChain < 0
                || value.tick < 0 {
                append(.invalidScoreBreakdown, "score_or_bonus_out_of_bounds")
            }
        }

        var abandonReason: DescentResearchAbandonReason?
        var abandonedTick: Int?
        if let event = abandonedEvents.first,
           case .runAbandoned(let tick, let reason) = event.event {
            abandonReason = reason
            abandonedTick = tick
            if tick < 0 { append(.terminalCount, "abandoned_tick_negative") }
        }

        let presentedEvents = groupedEvents[.choicePresented] ?? []
        let selectedEvents = groupedEvents[.choiceSelected] ?? []
        var selectedChoice: DescentArenaChoice?
        var choiceLatency: Int?
        if let event = selectedEvents.first,
           case .choiceSelected(let choice, let activeLatencyMilliseconds) = event.event {
            selectedChoice = choice
            choiceLatency = activeLatencyMilliseconds
        }

        switch context.variant {
        case .noArena:
            if !presentedEvents.isEmpty || !selectedEvents.isEmpty {
                append(
                    .choiceEventInNoArena,
                    "presented=\(presentedEvents.count);selected=\(selectedEvents.count)"
                )
            }
            if (finishSummary?.redlineBonusScore ?? 0) != 0 {
                append(.invalidScoreBreakdown, "no_arena_redline_bonus_nonzero")
            }
        case .choiceArena:
            if presentedEvents.count > 1 {
                append(.choicePresentedCount, "choice_presented_count=\(presentedEvents.count)")
            }
            if selectedEvents.count > 1 {
                append(.choiceSelectedCount, "choice_selected_count=\(selectedEvents.count)")
            }
            let reachedArena = didReachArena(
                finishSummary: finishSummary,
                abandonedTick: abandonedTick,
                presentedCount: presentedEvents.count,
                selectedCount: selectedEvents.count
            )
            if reachedArena && presentedEvents.count != 1 {
                append(.choicePresentedCount, "reached_arena_presented_count=\(presentedEvents.count)")
            }
            if reachedArena && selectedEvents.count != 1 {
                append(.choiceSelectedCount, "reached_arena_selected_count=\(selectedEvents.count)")
            }
            if let presented = presentedEvents.first,
               case .choicePresented(let tick, _) = presented.event,
               tick != 3_600 {
                append(.invalidChoicePresentedTick, "choice_presented_tick=\(tick)")
            }
            if let presented = presentedEvents.first,
               let selected = selectedEvents.first,
               presented.sequence >= selected.sequence {
                append(.choiceOrder, "choice_selected_not_after_presented")
            }
            if !selectedEvents.isEmpty && presentedEvents.isEmpty {
                append(.choiceOrder, "choice_selected_without_presented")
            }
            if let choiceLatency, choiceLatency < 0 {
                append(.invalidChoiceLatency, "choice_latency_ms=\(choiceLatency)")
            }
            if selectedChoice != .redline, (finishSummary?.redlineBonusScore ?? 0) != 0 {
                append(.invalidScoreBreakdown, "redline_bonus_without_redline_choice")
            }
        }

        let terminalKind: DescentResearchTerminalKind
        if terminalEvents.count != 1 {
            terminalKind = terminalEvents.isEmpty ? .missing : .invalid
        } else if finishSummary != nil {
            terminalKind = .finished
        } else {
            terminalKind = .abandoned
        }

        let resultAction: DescentResearchResultAction?
        let resultLatency: Int?
        if let event = resultEvents.first,
           case .resultAction(let action, let latencyMilliseconds) = event.event {
            resultAction = action
            resultLatency = latencyMilliseconds
        } else {
            resultAction = nil
            resultLatency = nil
        }

        let codes = Array(Set(violations.map(\.code))).sorted()
        return ValidationResult(
            run: DescentResearchRunReport(
                participantSlot: participant,
                sequence: sequence,
                variant: context.variant,
                orderIndex: context.orderIndex,
                runID: context.runID,
                runIndex: context.runIndex,
                seed: context.seed,
                ship: context.ship,
                rulesVersion: context.rulesVersion,
                terminalKind: terminalKind,
                finishSummary: finishSummary,
                abandonReason: abandonReason,
                activeTouchMilliseconds: inputSummary?.activeTouchMilliseconds,
                activePlayMilliseconds: inputSummary?.activePlayMilliseconds,
                meaningfulLaneChanges: inputSummary?.meaningfulLaneChanges,
                selectedChoice: selectedChoice,
                choiceLatencyMilliseconds: choiceLatency,
                resultAction: resultAction,
                resultActionLatencyMilliseconds: resultLatency,
                optionalRetryWindowMilliseconds: retryWindowMilliseconds,
                violationCodes: codes
            ),
            violations: violations
        )
    }

    static func buildParticipantSummaries(
        from runs: [DescentResearchRunReport]
    ) -> ParticipantBuildResult {
        var violations: [DescentResearchViolation] = []
        var summaries: [DescentResearchParticipantSummary] = []

        for participant in expectedParticipantSlots {
            let sequence = sequenceForParticipant(participant)
            let participantRuns = runs.filter { $0.participantSlot == participant }
            if participantRuns.isEmpty {
                violations.append(DescentResearchViolation(
                    code: .missingParticipant,
                    participantSlot: participant,
                    variant: nil,
                    runID: nil,
                    detail: "participant_has_no_runs"
                ))
            }

            let seeds = Set(participantRuns.map(\.seed))
            if seeds.count > 1 {
                violations.append(DescentResearchViolation(
                    code: .seedMismatch,
                    participantSlot: participant,
                    variant: nil,
                    runID: nil,
                    detail: "participant_seed_count=\(seeds.count)"
                ))
            }
            let ships = Set(participantRuns.map(\.ship))
            if ships.count > 1 {
                violations.append(DescentResearchViolation(
                    code: .shipMismatch,
                    participantSlot: participant,
                    variant: nil,
                    runID: nil,
                    detail: "participant_ship_count=\(ships.count)"
                ))
            }

            let noArena = makeVariantSummary(
                participant: participant,
                sequence: sequence,
                variant: .noArena,
                runs: participantRuns,
                violations: &violations
            )
            let choiceArena = makeVariantSummary(
                participant: participant,
                sequence: sequence,
                variant: .choiceArena,
                runs: participantRuns,
                violations: &violations
            )
            let participantViolations = violations.filter { $0.participantSlot == participant }
            let pairedDelta: Double?
            if noArena.isDataQualityValid,
               choiceArena.isDataQualityValid,
               let a = noArena.requiredRunMedianActiveTouchRatio,
               let b = choiceArena.requiredRunMedianActiveTouchRatio {
                pairedDelta = b - a
            } else {
                pairedDelta = nil
            }
            summaries.append(DescentResearchParticipantSummary(
                participantSlot: participant,
                sequence: sequence,
                noArena: noArena,
                choiceArena: choiceArena,
                pairedRequiredRunActiveTouchDelta: pairedDelta,
                isDataQualityValid: participantViolations.isEmpty
                    && noArena.isDataQualityValid
                    && choiceArena.isDataQualityValid
            ))
        }
        return ParticipantBuildResult(participants: summaries, violations: violations)
    }

    static func makeVariantSummary(
        participant: String,
        sequence: DescentResearchSequence,
        variant: DescentResearchVariant,
        runs: [DescentResearchRunReport],
        violations: inout [DescentResearchViolation]
    ) -> DescentResearchParticipantVariantSummary {
        let variantRuns = runs.filter { $0.variant == variant }
        let expectedOrder = expectedOrderIndex(sequence: sequence, variant: variant)
        if variantRuns.isEmpty {
            violations.append(DescentResearchViolation(
                code: .missingVariant,
                participantSlot: participant,
                variant: variant,
                runID: nil,
                detail: "variant_has_no_runs"
            ))
        }

        for run in variantRuns where run.orderIndex != expectedOrder {
            violations.append(DescentResearchViolation(
                code: .unexpectedVariantOrder,
                participantSlot: participant,
                variant: variant,
                runID: run.runID,
                detail: "expected_order=\(expectedOrder);actual=\(run.orderIndex.map(String.init) ?? "nil")"
            ))
        }

        let groupedByIndex = Dictionary(grouping: variantRuns, by: { $0.runIndex })
        for index in groupedByIndex.keys.sorted() where (groupedByIndex[index]?.count ?? 0) > 1 {
            let duplicates = groupedByIndex[index] ?? []
            for run in duplicates {
                violations.append(DescentResearchViolation(
                    code: .duplicateRunIndex,
                    participantSlot: participant,
                    variant: variant,
                    runID: run.runID,
                    detail: "run_index=\(index);count=\(duplicates.count)"
                ))
            }
        }

        for requiredIndex in 1...2 where groupedByIndex[requiredIndex] == nil {
            violations.append(DescentResearchViolation(
                code: .missingRequiredRun,
                participantSlot: participant,
                variant: variant,
                runID: nil,
                detail: "run_index=\(requiredIndex)"
            ))
        }

        for requiredIndex in 1...2 {
            guard let run = groupedByIndex[requiredIndex]?.first,
                  !run.didFinish else { continue }
            violations.append(DescentResearchViolation(
                code: .requiredRunNotFinished,
                participantSlot: participant,
                variant: variant,
                runID: run.runID,
                detail: "run_index=\(requiredIndex)"
            ))
        }

        let run1 = groupedByIndex[1]?.first
        let run2 = groupedByIndex[2]?.first
        let run3 = groupedByIndex[3]?.first
        let participantVariantViolations = violations.filter {
            $0.participantSlot == participant && ($0.variant == variant || $0.variant == nil)
        }
        let allRunsValid = variantRuns.allSatisfy(\.isDataQualityValid)
        let isValid = !variantRuns.isEmpty
            && participantVariantViolations.isEmpty
            && allRunsValid
            && run1 != nil
            && run2 != nil

        let retryWithinWindow = run2?.didFinish == true
            && run2?.optionalRetryWindowMilliseconds == 60_000
            && run2?.resultAction == .retry
            && (run2?.resultActionLatencyMilliseconds.map { (0...60_000).contains($0) } ?? false)
        let samePattern = run2?.seed == run3?.seed && run2?.ship == run3?.ship
        let voluntaryThird = retryWithinWindow
            && samePattern
            && run1?.didFinish == true
            && run1?.isDataQualityValid == true
            && run3?.didFinish == true
            && run3?.isDataQualityValid == true

        let run1Score = run1?.comparableScore
        let run3Score = run3?.comparableScore
        let gain: Bool?
        if voluntaryThird,
           let run1Score,
           let run3Score,
           run1Score > 0 {
            let lhs = run3Score.multipliedReportingOverflow(by: 5)
            let rhs = run1Score.multipliedReportingOverflow(by: 6)
            gain = lhs.overflow || rhs.overflow ? nil : lhs.partialValue >= rhs.partialValue
        } else {
            gain = nil
        }

        let requiredRatios = [run1, run2].compactMap { run -> Double? in
            guard run?.didFinish == true,
                  run?.isDataQualityValid == true else { return nil }
            return run?.activeTouchRatio
        }
        let requiredMedian = requiredRatios.count == 2 ? median(requiredRatios) : nil

        return DescentResearchParticipantVariantSummary(
            participantSlot: participant,
            sequence: sequence,
            variant: variant,
            orderIndex: expectedOrder,
            seed: Set(variantRuns.map(\.seed)).count == 1 ? variantRuns.first?.seed : nil,
            ship: Set(variantRuns.map(\.ship)).count == 1 ? variantRuns.first?.ship : nil,
            requiredRun1Finished: run1?.didFinish == true,
            requiredRun2Finished: run2?.didFinish == true,
            retryAfterRun2WithinSixtySeconds: retryWithinWindow,
            voluntaryThirdRunCompleted: voluntaryThird,
            run1ComparableScore: run1Score,
            run3ComparableScore: run3Score,
            run1ToRun3TwentyPercentGain: gain,
            requiredRunMedianActiveTouchRatio: requiredMedian,
            isDataQualityValid: isValid
        )
    }

    static func makePrimarySummary(
        _ participants: [DescentResearchParticipantSummary]
    ) -> DescentResearchPrimarySummary {
        let valid = participants.filter(\.isDataQualityValid)
        let aThird = valid.filter { $0.noArena.voluntaryThirdRunCompleted }.count
        let bThird = valid.filter { $0.choiceArena.voluntaryThirdRunCompleted }.count
        let aGain = valid.filter { $0.noArena.run1ToRun3TwentyPercentGain == true }.count
        let bGain = valid.filter { $0.choiceArena.run1ToRun3TwentyPercentGain == true }.count
        return DescentResearchPrimarySummary(
            dataQualityValidParticipantCount: valid.count,
            noArenaVoluntaryThirdRunCompletions: aThird,
            choiceArenaVoluntaryThirdRunCompletions: bThird,
            voluntaryThirdRunPairedUpliftCount: bThird - aThird,
            noArenaRun1ToRun3GainCount: aGain,
            choiceArenaRun1ToRun3GainCount: bGain,
            run1ToRun3GainPairedUpliftCount: bGain - aGain,
            choiceArenaRequiredRunMedianActiveTouchRatio: median(
                valid.compactMap { $0.choiceArena.requiredRunMedianActiveTouchRatio }
            ),
            pairedRequiredRunActiveTouchDeltaMedian: median(
                valid.compactMap(\.pairedRequiredRunActiveTouchDelta)
            )
        )
    }

    static func didReachArena(
        finishSummary: DescentResearchRunSummary?,
        abandonedTick: Int?,
        presentedCount: Int,
        selectedCount: Int
    ) -> Bool {
        if presentedCount > 0 || selectedCount > 0 { return true }
        if let finishSummary {
            if finishSummary.endReason == .survivedSixtySeconds { return true }
            return finishSummary.tick > 3_600
        }
        return (abandonedTick ?? -1) >= 3_600
    }

    static func normalizedParticipantSlot(_ value: String?) -> String? {
        guard let value, expectedParticipantSlots.contains(value) else { return nil }
        return value
    }

    static func sequenceForParticipant(_ participant: String) -> DescentResearchSequence {
        let number = Int(participant.dropFirst()) ?? 0
        return number <= 5 ? .ab : .ba
    }

    static func expectedOrderIndex(
        sequence: DescentResearchSequence,
        variant: DescentResearchVariant
    ) -> Int {
        switch (sequence, variant) {
        case (.ab, .noArena), (.ba, .choiceArena): 1
        case (.ab, .choiceArena), (.ba, .noArena): 2
        }
    }

    static func replacingViolationCodes(
        in run: DescentResearchRunReport,
        with codes: [DescentResearchViolationCode]
    ) -> DescentResearchRunReport {
        DescentResearchRunReport(
            participantSlot: run.participantSlot,
            sequence: run.sequence,
            variant: run.variant,
            orderIndex: run.orderIndex,
            runID: run.runID,
            runIndex: run.runIndex,
            seed: run.seed,
            ship: run.ship,
            rulesVersion: run.rulesVersion,
            terminalKind: run.terminalKind,
            finishSummary: run.finishSummary,
            abandonReason: run.abandonReason,
            activeTouchMilliseconds: run.activeTouchMilliseconds,
            activePlayMilliseconds: run.activePlayMilliseconds,
            meaningfulLaneChanges: run.meaningfulLaneChanges,
            selectedChoice: run.selectedChoice,
            choiceLatencyMilliseconds: run.choiceLatencyMilliseconds,
            resultAction: run.resultAction,
            resultActionLatencyMilliseconds: run.resultActionLatencyMilliseconds,
            optionalRetryWindowMilliseconds: run.optionalRetryWindowMilliseconds,
            violationCodes: Array(Set(codes)).sorted()
        )
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    static func eventKind(_ event: DescentResearchEvent) -> EventKind {
        switch event {
        case .runStarted: .runStarted
        case .firstInput: .firstInput
        case .firstDestroy: .firstDestroy
        case .firstDropCollected: .firstDropCollected
        case .choicePresented: .choicePresented
        case .choiceSelected: .choiceSelected
        case .optionalRetryWindowOpened: .optionalRetryWindowOpened
        case .inputSummary: .inputSummary
        case .runFinished: .runFinished
        case .runAbandoned: .runAbandoned
        case .resultAction: .resultAction
        }
    }

    static func eventSignature(_ event: DescentResearchEvent) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: (try? encoder.encode(event)) ?? Data(), as: UTF8.self)
    }

    static func stableEnvelopeSignature(_ envelope: DescentResearchRunEnvelope) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return String(decoding: (try? encoder.encode(envelope)) ?? Data(), as: UTF8.self)
    }

    static func runSort(_ lhs: DescentResearchRunReport, _ rhs: DescentResearchRunReport) -> Bool {
        let left = (
            lhs.participantSlot ?? "~",
            lhs.variant == .noArena ? 0 : 1,
            lhs.runIndex,
            lhs.runID.uuidString
        )
        let right = (
            rhs.participantSlot ?? "~",
            rhs.variant == .noArena ? 0 : 1,
            rhs.runIndex,
            rhs.runID.uuidString
        )
        if left.0 != right.0 { return left.0 < right.0 }
        if left.1 != right.1 { return left.1 < right.1 }
        if left.2 != right.2 { return left.2 < right.2 }
        return left.3 < right.3
    }

    static func violationSort(
        _ lhs: DescentResearchViolation,
        _ rhs: DescentResearchViolation
    ) -> Bool {
        let left = (
            lhs.participantSlot ?? "~",
            lhs.variant.map { $0 == .noArena ? 0 : 1 } ?? 2,
            lhs.runID?.uuidString ?? "~",
            lhs.code.rawValue,
            lhs.detail
        )
        let right = (
            rhs.participantSlot ?? "~",
            rhs.variant.map { $0 == .noArena ? 0 : 1 } ?? 2,
            rhs.runID?.uuidString ?? "~",
            rhs.code.rawValue,
            rhs.detail
        )
        if left.0 != right.0 { return left.0 < right.0 }
        if left.1 != right.1 { return left.1 < right.1 }
        if left.2 != right.2 { return left.2 < right.2 }
        if left.3 != right.3 { return left.3 < right.3 }
        return left.4 < right.4
    }

    static func participantVariantKey(
        _ participant: String,
        _ variant: DescentResearchVariant
    ) -> String {
        "\(participant)|\(variant.rawValue)"
    }

    static func variantID(_ variant: DescentResearchVariant) -> String {
        switch variant {
        case .noArena: "DB_CA_A_R2_NO_ARENA"
        case .choiceArena: "DB_CA_B_R3_ARENA"
        }
    }

    static func shipID(_ ship: DescentShipKind) -> String {
        switch ship {
        case .interceptor: "interceptor"
        case .striker: "striker"
        case .guardian: "guardian"
        }
    }

    static func choiceID(_ choice: DescentArenaChoice) -> String {
        switch choice {
        case .steady: "steady"
        case .redline: "redline"
        }
    }

    static func endReasonID(_ run: DescentResearchRunReport) -> String {
        if let endReason = run.finishSummary?.endReason { return endReason.rawValue }
        return run.abandonReason?.rawValue ?? ""
    }

    static func decimalString(_ value: Double) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    static func booleanString(_ value: Bool) -> String {
        value ? "true" : "false"
    }

    static func escapeCSV(_ value: String) -> String {
        guard value.contains(",")
                || value.contains("\"")
                || value.contains("\r")
                || value.contains("\n") else { return value }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
