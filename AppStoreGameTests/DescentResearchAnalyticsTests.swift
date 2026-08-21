import XCTest
@testable import AppStoreGame

@MainActor
final class DescentResearchAnalyticsTests: XCTestCase {
    func testResearchConfigurationIsOptInAndVariantIsExplicit() {
        XCTAssertEqual(
            DescentResearchConfiguration.current(arguments: []),
            DescentResearchConfiguration(
                isEnabled: false,
                variant: .choiceArena,
                participantSlot: nil,
                orderIndex: nil
            )
        )
        XCTAssertEqual(
            DescentResearchConfiguration.current(arguments: ["-descentResearch"]),
            DescentResearchConfiguration(
                isEnabled: true,
                variant: .choiceArena,
                participantSlot: nil,
                orderIndex: nil
            )
        )
        XCTAssertEqual(
            DescentResearchConfiguration.current(arguments: [
                "-descentResearch", "-descentVariantNoArena",
                "-descentParticipant", "P03", "-descentOrderIndex", "1"
            ]),
            DescentResearchConfiguration(
                isEnabled: true,
                variant: .noArena,
                participantSlot: "P03",
                orderIndex: 1
            )
        )
    }

    func testResearchAssignmentFailsClosedAndKeepsParticipantSeedAcrossVariants() {
        let p03A = DescentResearchConfiguration.current(arguments: [
            "-descentResearch", "-descentVariantNoArena",
            "-descentParticipant", "P03", "-descentOrderIndex", "1"
        ])
        let p03B = DescentResearchConfiguration.current(arguments: [
            "-descentResearch",
            "-descentParticipant", "P03", "-descentOrderIndex", "2"
        ])
        let wrongOrder = DescentResearchConfiguration.current(arguments: [
            "-descentResearch",
            "-descentParticipant", "P03", "-descentOrderIndex", "1"
        ])
        let p08B = DescentResearchConfiguration.current(arguments: [
            "-descentResearch",
            "-descentParticipant", "P08", "-descentOrderIndex", "1"
        ])

        XCTAssertTrue(p03A.isDataCollectionEnabled)
        XCTAssertTrue(p03B.isDataCollectionEnabled)
        XCTAssertEqual(p03A.assignedSeed, p03B.assignedSeed)
        XCTAssertEqual(wrongOrder.assignmentIssue, .variantOrderMismatch)
        XCTAssertFalse(wrongOrder.isDataCollectionEnabled)
        XCTAssertTrue(p08B.isDataCollectionEnabled)
        XCTAssertEqual(
            DescentResearchConfiguration.current(arguments: ["-descentResearch"]).assignmentIssue,
            .missingParticipant
        )
    }

    func testSessionIsLogicallyExactlyOnceAndTerminalOrderingIsClosed() {
        let sink = InMemoryDescentResearchEventSink()
        let session = makeSession(sink: sink)

        session.record(.firstInput(tick: 8, elapsedMilliseconds: 66))
        session.record(.firstInput(tick: 9, elapsedMilliseconds: 75))
        session.record(.runFinished(makeSummary(score: 1_200)))
        session.record(.firstDestroy(tick: 12))
        session.record(.runAbandoned(tick: 12, reason: .home))
        session.recordResultAction(.retry)
        session.recordResultAction(.home)
        session.flush()

        XCTAssertTrue(session.hasTerminalEvent)
        XCTAssertEqual(sink.envelopes.count, 1)
        XCTAssertEqual(sink.envelopes[0].events.count, 4)
        XCTAssertEqual(sink.envelopes[0].events.map(\.sequence), [0, 1, 2, 3])
        XCTAssertEqual(sink.envelopes[0].events[0].event, .runStarted)
        XCTAssertEqual(sink.envelopes[0].events[1].event, .firstInput(tick: 8, elapsedMilliseconds: 66))
        XCTAssertEqual(sink.envelopes[0].events[2].event, .runFinished(makeSummary(score: 1_200)))
        guard case .resultAction(let action, _) = sink.envelopes[0].events[3].event else {
            return XCTFail("Expected one result action")
        }
        XCTAssertEqual(action, .retry)
    }

    func testAbandonedRunCannotRecordResultActionOrLaterGameplayEvent() {
        let sink = InMemoryDescentResearchEventSink()
        let session = makeSession(sink: sink)
        session.record(.runAbandoned(tick: 100, reason: .home))
        session.recordResultAction(.home)
        session.record(.firstDestroy(tick: 101))
        session.flush()

        XCTAssertEqual(sink.envelopes[0].events.count, 2)
        XCTAssertEqual(
            sink.envelopes[0].events.last?.event,
            .runAbandoned(tick: 100, reason: .home)
        )
    }

    func testLocalStoreRoundTripsUpsertsAndFailsClosedAtCapacityOrInvalidLines() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalResearchEventStore(
            directoryURL: directory,
            maximumBytes: 100_000,
            maximumRuns: 2
        )

        let first = makeEnvelope(runID: UUID(), runIndex: 1, score: 100)
        let second = makeEnvelope(runID: UUID(), runIndex: 2, score: 200)
        let third = makeEnvelope(runID: UUID(), runIndex: 3, score: 300)
        try store.persist(first)
        try store.persist(second)
        XCTAssertThrowsError(try store.persist(third)) { error in
            XCTAssertEqual(error as? LocalResearchEventStoreError, .capacityExceeded)
        }
        XCTAssertEqual(store.readAll().map(\.context.runID), [first.context.runID, second.context.runID])

        let updatedSecond = makeEnvelope(
            runID: second.context.runID,
            runIndex: 2,
            score: 450
        )
        try store.persist(updatedSecond)
        XCTAssertEqual(store.readAll().count, 2)
        XCTAssertEqual(finishedScore(in: store.readAll().last), 450)

        var data = try Data(contentsOf: store.fileURL)
        data.append(Data("not-json\n".utf8))
        try data.write(to: store.fileURL, options: .atomic)
        let audit = store.auditReadAll()
        XCTAssertEqual(audit.envelopes.count, 2)
        XCTAssertEqual(audit.invalidLineCount, 1)
        XCTAssertFalse(audit.isTrustworthy)
        XCTAssertThrowsError(try store.persist(makeEnvelope(
            runID: UUID(),
            runIndex: 4,
            score: 500
        ))) { error in
            XCTAssertEqual(error as? LocalResearchEventStoreError, .sourceContainsInvalidLines(1))
        }
        XCTAssertEqual(try Data(contentsOf: store.fileURL), data)

        try store.deleteAll()
        XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL.path))
    }

    func testLocalStoreFailsAtCapacityWithoutEvictingOldRuns() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalResearchEventStore(
            directoryURL: directory,
            maximumBytes: 100_000,
            maximumRuns: 2
        )
        let first = makeEnvelope(runID: UUID(), runIndex: 1, score: 100)
        let second = makeEnvelope(runID: UUID(), runIndex: 2, score: 200)
        try store.persist(first)
        try store.persist(second)

        XCTAssertThrowsError(try store.persist(
            makeEnvelope(runID: UUID(), runIndex: 3, score: 300)
        )) { error in
            XCTAssertEqual(error as? LocalResearchEventStoreError, .capacityExceeded)
        }
        XCTAssertEqual(store.readAll().map(\.context.runID), [first.context.runID, second.context.runID])
    }

    func testEncodedEnvelopeContainsNoRawTouchOrPersistentIdentityFields() throws {
        let envelope = makeEnvelope(runID: UUID(), runIndex: 1, score: 500)
        let encoded = try JSONEncoder().encode(envelope)
        let text = String(decoding: encoded, as: UTF8.self).lowercased()

        for forbidden in [
            "touchx", "touchy", "coordinate", "advertising", "appleid",
            "email", "name", "deviceid", "accessibility"
        ] {
            XCTAssertFalse(text.contains(forbidden), "Unexpected field: \(forbidden)")
        }
    }

    func testResearchRecordingDoesNotChangeAuthoritativeChecksum() {
        var baseline = GameRules.initialDescentState(seed: 42, shipKind: .interceptor)
        var observed = baseline
        let session = makeSession(sink: InMemoryDescentResearchEventSink())

        for tick in 0..<1_000 {
            let target = Double(GameRules.descentLaneXPoints[(tick / 120) % 5])
            _ = GameRules.stepDescent(state: &baseline, input: DescentInput(targetX: target))
            _ = GameRules.stepDescent(state: &observed, input: DescentInput(targetX: target))
            if tick == 100 { session.record(.firstInput(tick: tick, elapsedMilliseconds: 833)) }
            if tick == 500 { session.record(.firstDestroy(tick: tick)) }
        }

        XCTAssertEqual(GameRules.descentChecksum(baseline), GameRules.descentChecksum(observed))
    }

    func testSessionSurfacesPersistenceFailureForFailClosedResearchUI() {
        let session = makeSession(sink: ThrowingDescentResearchEventSink())

        session.flush()

        XCTAssertNotNil(session.lastPersistenceError)
        XCTAssertTrue(session.lastPersistenceError?.contains("sourceReadFailed") == true)
    }

    func testResearchConsoleBlocksSummaryExportWhenSourceDataQualityFails() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LocalResearchEventStore(directoryURL: directory)
        try store.persist(makeEnvelope(runID: UUID(), runIndex: 1, score: 500))
        var data = try Data(contentsOf: store.fileURL)
        data.append(Data("corrupt-line\n".utf8))
        try data.write(to: store.fileURL, options: .atomic)

        let model = DescentResearchConsoleModel(store: store)

        XCTAssertFalse(model.canExportSummary)
        XCTAssertNil(model.exportURL)
        XCTAssertEqual(model.audit.invalidLineCount, 1)
        XCTAssertTrue(model.operationMessage?.contains("DQ가 정상") == true)
    }

    private func makeSession(
        sink: any DescentResearchEventSink,
        runID: UUID = UUID(),
        runIndex: Int = 1
    ) -> DescentResearchSession {
        DescentResearchSession(
            context: DescentResearchContext(
                researchSessionID: UUID(),
                runID: runID,
                participantSlot: "P01",
                orderIndex: 1,
                variant: .choiceArena,
                seed: 42,
                ship: .interceptor,
                runIndex: runIndex,
                bestScoreBefore: 0,
                rulesVersion: "test"
            ),
            sink: sink
        )
    }

    private func makeEnvelope(
        runID: UUID,
        runIndex: Int,
        score: Int
    ) -> DescentResearchRunEnvelope {
        let sink = InMemoryDescentResearchEventSink()
        let session = makeSession(sink: sink, runID: runID, runIndex: runIndex)
        session.record(.runFinished(makeSummary(score: score)))
        return DescentResearchRunEnvelope(context: session.context, events: session.events)
    }

    private func makeSummary(score: Int) -> DescentResearchRunSummary {
        DescentResearchRunSummary(
            tick: 7_200,
            score: score,
            previousBestScore: 0,
            maxCombo: 12,
            dangerSaves: 2,
            dropsCollected: 3,
            breaches: 0,
            redlineBonusScore: 0,
            endReason: .survivedSixtySeconds
        )
    }

    private func finishedScore(in envelope: DescentResearchRunEnvelope?) -> Int? {
        envelope?.events.compactMap { sequenced -> Int? in
            guard case .runFinished(let summary) = sequenced.event else { return nil }
            return summary.score
        }.last
    }
}

@MainActor
private final class ThrowingDescentResearchEventSink: DescentResearchEventSink {
    func persist(_ envelope: DescentResearchRunEnvelope) throws {
        throw LocalResearchEventStoreError.sourceReadFailed
    }

    func deleteAll() throws {}
}
