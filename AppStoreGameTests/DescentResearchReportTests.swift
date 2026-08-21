import XCTest
@testable import AppStoreGame

@MainActor
final class DescentResearchReportTests: XCTestCase {
    func testCompleteCounterbalancedStudyProducesOnlyPlanPrimaryMetrics() throws {
        let report = DescentResearchReport.make(from: makeCompleteStudy())

        XCTAssertTrue(report.isDataQualityValid)
        XCTAssertTrue(report.violations.isEmpty)
        XCTAssertEqual(report.runs.count, 60)
        XCTAssertEqual(report.participants.count, 10)
        XCTAssertEqual(report.participants.first?.participantSlot, "P01")
        XCTAssertEqual(report.participants.first?.sequence, .ab)
        XCTAssertEqual(report.participants.first?.noArena.orderIndex, 1)
        XCTAssertEqual(report.participants.first?.choiceArena.orderIndex, 2)
        XCTAssertEqual(report.participants.last?.participantSlot, "P10")
        XCTAssertEqual(report.participants.last?.sequence, .ba)
        XCTAssertEqual(report.participants.last?.noArena.orderIndex, 2)
        XCTAssertEqual(report.participants.last?.choiceArena.orderIndex, 1)

        XCTAssertEqual(report.primary.dataQualityValidParticipantCount, 10)
        XCTAssertEqual(report.primary.noArenaVoluntaryThirdRunCompletions, 10)
        XCTAssertEqual(report.primary.choiceArenaVoluntaryThirdRunCompletions, 10)
        XCTAssertEqual(report.primary.voluntaryThirdRunPairedUpliftCount, 0)
        XCTAssertEqual(report.primary.noArenaRun1ToRun3GainCount, 10)
        XCTAssertEqual(report.primary.choiceArenaRun1ToRun3GainCount, 10)
        XCTAssertEqual(report.primary.run1ToRun3GainPairedUpliftCount, 0)
        XCTAssertEqual(
            try XCTUnwrap(report.primary.choiceArenaRequiredRunMedianActiveTouchRatio),
            0.6,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            try XCTUnwrap(report.primary.pairedRequiredRunActiveTouchDeltaMedian),
            0.1,
            accuracy: 0.000_001
        )
    }

    func testComparableScoreAndActiveTouchRatioUseDocumentedFormulas() throws {
        let report = DescentResearchReport.make(from: makeCompleteStudy())
        let run = try XCTUnwrap(report.runs.first {
            $0.participantSlot == "P01" && $0.variant == .choiceArena && $0.runIndex == 1
        })

        XCTAssertEqual(run.finishSummary?.score, 1_100)
        XCTAssertEqual(run.finishSummary?.redlineBonusScore, 100)
        XCTAssertEqual(run.comparableScore, 1_000)
        XCTAssertEqual(try XCTUnwrap(run.activeTouchRatio), 0.6, accuracy: 0.000_001)
    }

    func testVoluntaryThirdRunRequiresRunTwoRetryWithinInclusiveSixtySeconds() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .choiceArena,
            runIndex: 2,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .choiceArena,
                runIndex: 2,
                resultAction: .retry,
                resultLatencyMilliseconds: 60_001
            )
        )
        var report = DescentResearchReport.make(from: envelopes)
        var summary = try XCTUnwrap(report.participants.first?.choiceArena)
        XCTAssertFalse(summary.retryAfterRun2WithinSixtySeconds)
        XCTAssertFalse(summary.voluntaryThirdRunCompleted)
        XCTAssertNil(summary.run1ToRun3TwentyPercentGain)

        envelopes = replacing(
            participant: 1,
            variant: .choiceArena,
            runIndex: 2,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .choiceArena,
                runIndex: 2,
                resultAction: .retry,
                resultLatencyMilliseconds: 60_000
            )
        )
        report = DescentResearchReport.make(from: envelopes)
        summary = try XCTUnwrap(report.participants.first?.choiceArena)
        XCTAssertTrue(summary.retryAfterRun2WithinSixtySeconds)
        XCTAssertTrue(summary.voluntaryThirdRunCompleted)
        XCTAssertEqual(summary.run1ToRun3TwentyPercentGain, true)
    }

    func testThirdRunAbandonmentIsNotACompletedVoluntaryThirdRun() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .choiceArena,
            runIndex: 3,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .choiceArena,
                runIndex: 3,
                terminal: .abandoned
            )
        )

        let report = DescentResearchReport.make(from: envelopes)
        let summary = try XCTUnwrap(report.participants.first?.choiceArena)
        XCTAssertTrue(summary.isDataQualityValid)
        XCTAssertFalse(summary.voluntaryThirdRunCompleted)
        XCTAssertNil(summary.run1ToRun3TwentyPercentGain)
    }

    func testDuplicateRunIDAndDuplicateEventAreInvalidAndStable() throws {
        var envelopes = makeCompleteStudy()
        let duplicate = try XCTUnwrap(envelopes.first)
        envelopes.append(duplicate)
        let target = try XCTUnwrap(envelopes.firstIndex {
            $0.context.participantSlot == "P02"
                && $0.context.variant == .noArena
                && $0.context.runIndex == 1
        })
        let original = envelopes[target]
        var duplicateEvents = original.events
        duplicateEvents.append(DescentResearchSequencedEvent(
            sequence: duplicateEvents.count,
            event: .firstDestroy(tick: 200)
        ))
        duplicateEvents.append(DescentResearchSequencedEvent(
            sequence: duplicateEvents.count,
            event: .firstDestroy(tick: 201)
        ))
        envelopes[target] = DescentResearchRunEnvelope(
            context: original.context,
            events: duplicateEvents
        )

        let forward = DescentResearchReport.make(from: envelopes)
        let reverse = DescentResearchReport.make(from: envelopes.reversed())
        XCTAssertEqual(forward, reverse)
        XCTAssertTrue(forward.violations.contains { $0.code == .duplicateRunID })
        XCTAssertTrue(forward.violations.contains { $0.code == .duplicateEvent })
        XCTAssertFalse(forward.isDataQualityValid)
    }

    func testVariantChoiceOrderingAndTerminalCompletenessViolationsAreVisible() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .noArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .noArena,
                runIndex: 1,
                includeChoiceEvents: true
            )
        )
        envelopes = replacing(
            participant: 2,
            variant: .choiceArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 2,
                variant: .choiceArena,
                runIndex: 1,
                choiceSelectedBeforePresented: true
            )
        )
        envelopes = replacing(
            participant: 3,
            variant: .noArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 3,
                variant: .noArena,
                runIndex: 1,
                terminal: .missing
            )
        )
        envelopes = replacing(
            participant: 4,
            variant: .choiceArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 4,
                variant: .choiceArena,
                runIndex: 1,
                includeChoiceEvents: false
            )
        )

        let report = DescentResearchReport.make(from: envelopes)
        XCTAssertTrue(report.violations.contains { $0.code == .choiceEventInNoArena })
        XCTAssertTrue(report.violations.contains { $0.code == .choiceOrder })
        XCTAssertTrue(report.violations.contains { $0.code == .terminalCount })
        XCTAssertTrue(report.violations.contains { $0.code == .choicePresentedCount })
        XCTAssertTrue(report.violations.contains { $0.code == .choiceSelectedCount })
        XCTAssertEqual(report.primary.dataQualityValidParticipantCount, 6)
    }

    func testSeedShipAndCounterbalanceMismatchInvalidateParticipant() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .choiceArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .choiceArena,
                runIndex: 1,
                seed: 9_999,
                ship: .striker,
                orderIndex: 1
            )
        )

        let report = DescentResearchReport.make(from: envelopes)
        XCTAssertTrue(report.violations.contains { $0.code == .seedMismatch })
        XCTAssertTrue(report.violations.contains { $0.code == .shipMismatch })
        XCTAssertTrue(report.violations.contains { $0.code == .unexpectedVariantOrder })
        XCTAssertFalse(try XCTUnwrap(report.participants.first).isDataQualityValid)
    }

    func testInvalidParticipantValueIsNotReflectedIntoReportOrCSV() throws {
        var envelopes = makeCompleteStudy()
        let invalidRunID = try XCTUnwrap(
            UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")
        )
        envelopes.append(makeEnvelope(
            participantSlot: "real-person@example.com",
            participant: 99,
            variant: .noArena,
            runIndex: 1,
            runID: invalidRunID
        ))

        let report = DescentResearchReport.make(from: envelopes)
        let violation = try XCTUnwrap(report.violations.first { $0.code == .invalidParticipantSlot })
        XCTAssertNil(violation.participantSlot)
        XCTAssertFalse(String(decoding: report.csvData(), as: UTF8.self).contains("real-person"))
    }

    func testInvalidInputAndScoreBreakdownDoNotProduceDerivedMetrics() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .choiceArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .choiceArena,
                runIndex: 1,
                score: 100,
                redlineBonusScore: 101,
                activeTouchMilliseconds: 60_001,
                activePlayMilliseconds: 60_000
            )
        )

        let report = DescentResearchReport.make(from: envelopes)
        let run = try XCTUnwrap(report.runs.first {
            $0.participantSlot == "P01" && $0.variant == .choiceArena && $0.runIndex == 1
        })
        XCTAssertNil(run.comparableScore)
        XCTAssertNil(run.activeTouchRatio)
        XCTAssertTrue(run.violationCodes.contains(.invalidInputSummary))
        XCTAssertTrue(run.violationCodes.contains(.invalidScoreBreakdown))
    }

    func testInvalidFrenzyBreakdownFailsClosed() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .noArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .noArena,
                runIndex: 1,
                score: 100,
                frenzyBonusScore: 101,
                frenzyTriggerCount: 1,
                frenzyActiveTicks: 360,
                maxDirectChain: GameRules.descentFrenzyThreshold
            )
        )

        let report = DescentResearchReport.make(from: envelopes)
        let run = try XCTUnwrap(report.runs.first {
            $0.participantSlot == "P01" && $0.variant == .noArena && $0.runIndex == 1
        })
        XCTAssertTrue(run.violationCodes.contains(.invalidScoreBreakdown))
        XCTAssertFalse(report.isDataQualityValid)
    }

    func testCSVIsDeterministicOrderedEscapedAndContainsNoForbiddenPIIColumns() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .noArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .noArena,
                runIndex: 1,
                rulesVersion: "revision,\"quoted\"\nline"
            )
        )
        let forward = DescentResearchReport.make(from: envelopes).csvData()
        let reverse = DescentResearchReport.make(from: envelopes.reversed()).csvData()

        XCTAssertEqual(forward, reverse)
        let csv = String(decoding: forward, as: UTF8.self)
        XCTAssertTrue(csv.hasSuffix("\r\n"))
        XCTAssertTrue(csv.contains("\"revision,\"\"quoted\"\"\nline\""))
        let lines = csv.split(separator: "\n", omittingEmptySubsequences: false)
        XCTAssertTrue(csv.contains("\r\nP01,AB,DB_CA_A_R2_NO_ARENA,1,"))

        let headers = Set(lines[0].trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",").map(String.init))
        for required in [
            "frenzy_bonus_score", "frenzy_trigger_count",
            "frenzy_active_ticks", "max_direct_chain"
        ] {
            XCTAssertTrue(headers.contains(required), "Missing Revision 5 CSV field: \(required)")
        }
        for forbidden in [
            "name", "email", "phone", "apple_id", "advertising_id",
            "raw_touch_x", "raw_touch_y", "ip_address", "accessibility_setting"
        ] {
            XCTAssertFalse(headers.contains(forbidden), "Forbidden CSV field: \(forbidden)")
        }
    }

    func testOutdatedRulesVersionFailsClosedBeforeStudyAggregation() throws {
        var envelopes = makeCompleteStudy()
        envelopes = replacing(
            participant: 1,
            variant: .noArena,
            runIndex: 1,
            in: envelopes,
            with: makeEnvelope(
                participant: 1,
                variant: .noArena,
                runIndex: 1,
                rulesVersion: "descent-rev3-choice-arena-v1"
            )
        )

        let report = DescentResearchReport.make(from: envelopes)
        let run = try XCTUnwrap(report.runs.first {
            $0.participantSlot == "P01" && $0.variant == .noArena && $0.runIndex == 1
        })
        XCTAssertTrue(run.violationCodes.contains(.unsupportedRulesVersion))
        XCTAssertFalse(report.isDataQualityValid)
    }
}

private extension DescentResearchReportTests {
    enum TerminalFixture {
        case finished
        case abandoned
        case missing
    }

    func makeCompleteStudy() -> [DescentResearchRunEnvelope] {
        (1...10).flatMap { participant in
            [DescentResearchVariant.noArena, .choiceArena].flatMap { variant in
                (1...3).map { runIndex in
                    makeEnvelope(
                        participant: participant,
                        variant: variant,
                        runIndex: runIndex,
                        resultAction: runIndex == 2 ? .retry : nil,
                        resultLatencyMilliseconds: runIndex == 2 ? 60_000 : nil
                    )
                }
            }
        }
    }

    func makeEnvelope(
        participantSlot: String? = nil,
        participant: Int,
        variant: DescentResearchVariant,
        runIndex: Int,
        runID: UUID? = nil,
        seed: UInt64? = nil,
        ship: DescentShipKind = .interceptor,
        orderIndex: Int? = nil,
        terminal: TerminalFixture = .finished,
        includeChoiceEvents: Bool? = nil,
        choiceSelectedBeforePresented: Bool = false,
        score: Int? = nil,
        redlineBonusScore: Int? = nil,
        frenzyBonusScore: Int = 0,
        frenzyTriggerCount: Int = 0,
        frenzyActiveTicks: Int = 0,
        maxDirectChain: Int = 0,
        activeTouchMilliseconds: Int? = nil,
        activePlayMilliseconds: Int = 60_000,
        resultAction: DescentResearchResultAction? = nil,
        resultLatencyMilliseconds: Int? = nil,
        rulesVersion: String = DescentResearchRules.currentVersion
    ) -> DescentResearchRunEnvelope {
        let slot = participantSlot ?? String(format: "P%02d", participant)
        let resolvedOrder = orderIndex ?? expectedOrder(participant: participant, variant: variant)
        let resolvedRunID = runID ?? fixtureRunID(
            participant: participant,
            variant: variant,
            runIndex: runIndex
        )
        let bonus = redlineBonusScore
            ?? (variant == .choiceArena ? runIndex * 100 : 0)
        let comparable = score ?? [1_000, 1_100, 1_250][max(0, min(2, runIndex - 1))]
        let finalScore = score ?? comparable + bonus
        let previousComparable = [0, 1_000, 1_100][max(0, min(2, runIndex - 1))]
        let previousBonus = variant == .choiceArena && runIndex > 1
            ? (runIndex - 1) * 100
            : 0
        let bestScoreBefore = previousComparable + previousBonus
        let touchMilliseconds = activeTouchMilliseconds
            ?? (variant == .choiceArena ? 36_000 : 30_000)
        let shouldIncludeChoice = includeChoiceEvents ?? (variant == .choiceArena)

        var rawEvents: [DescentResearchEvent] = [.runStarted]
        if shouldIncludeChoice {
            if choiceSelectedBeforePresented {
                rawEvents.append(.choiceSelected(choice: .redline, activeLatencyMilliseconds: 1_200))
                rawEvents.append(.choicePresented(tick: 3_600, score: finalScore / 2))
            } else {
                rawEvents.append(.choicePresented(tick: 3_600, score: finalScore / 2))
                rawEvents.append(.choiceSelected(choice: .redline, activeLatencyMilliseconds: 1_200))
            }
        }
        switch terminal {
        case .finished:
            rawEvents.append(.inputSummary(DescentResearchInputSummary(
                firstMoveMilliseconds: 500,
                activeTouchMilliseconds: touchMilliseconds,
                activePlayMilliseconds: activePlayMilliseconds,
                meaningfulLaneChanges: 24
            )))
            if runIndex == 2 {
                rawEvents.append(.optionalRetryWindowOpened(durationMilliseconds: 60_000))
            }
            rawEvents.append(.runFinished(DescentResearchRunSummary(
                tick: 7_200,
                score: finalScore,
                previousBestScore: bestScoreBefore,
                maxCombo: 12,
                dangerSaves: 2,
                dropsCollected: 3,
                breaches: 0,
                redlineBonusScore: bonus,
                frenzyBonusScore: frenzyBonusScore,
                frenzyTriggerCount: frenzyTriggerCount,
                frenzyActiveTicks: frenzyActiveTicks,
                maxDirectChain: maxDirectChain,
                endReason: .survivedSixtySeconds
            )))
            if let resultAction {
                rawEvents.append(.resultAction(
                    action: resultAction,
                    latencyMilliseconds: resultLatencyMilliseconds ?? 0
                ))
            }
        case .abandoned:
            rawEvents.append(.runAbandoned(tick: 3_000, reason: .home))
        case .missing:
            break
        }
        let events = rawEvents.enumerated().map {
            DescentResearchSequencedEvent(sequence: $0.offset, event: $0.element)
        }
        return DescentResearchRunEnvelope(
            context: DescentResearchContext(
                researchSessionID: fixtureSessionID(participant: participant, variant: variant),
                runID: resolvedRunID,
                participantSlot: slot,
                orderIndex: resolvedOrder,
                variant: variant,
                seed: seed ?? UInt64(4_000 + participant),
                ship: ship,
                runIndex: runIndex,
                bestScoreBefore: bestScoreBefore,
                rulesVersion: rulesVersion
            ),
            events: events
        )
    }

    func replacing(
        participant: Int,
        variant: DescentResearchVariant,
        runIndex: Int,
        in envelopes: [DescentResearchRunEnvelope],
        with replacement: DescentResearchRunEnvelope
    ) -> [DescentResearchRunEnvelope] {
        let slot = String(format: "P%02d", participant)
        return envelopes.map {
            if $0.context.participantSlot == slot,
               $0.context.variant == variant,
               $0.context.runIndex == runIndex {
                replacement
            } else {
                $0
            }
        }
    }

    func expectedOrder(participant: Int, variant: DescentResearchVariant) -> Int {
        if participant <= 5 { return variant == .noArena ? 1 : 2 }
        return variant == .choiceArena ? 1 : 2
    }

    func fixtureSessionID(participant: Int, variant: DescentResearchVariant) -> UUID {
        let variantValue: UInt8 = variant == .noArena ? 10 : 11
        return UUID(uuid: (
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, UInt8(clamping: participant), variantValue, 0
        ))
    }

    func fixtureRunID(
        participant: Int,
        variant: DescentResearchVariant,
        runIndex: Int
    ) -> UUID {
        let variantValue: UInt8 = variant == .noArena ? 100 : 200
        return UUID(uuid: (
            0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0,
            UInt8(clamping: participant), variantValue, UInt8(clamping: runIndex), 1
        ))
    }
}
