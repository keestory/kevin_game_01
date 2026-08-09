import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
#else
@testable import AppStoreGame
#endif

final class GameRulesTests: XCTestCase {
    @MainActor
    func testThreeConnectedPassengersExit() {
        var board = TrainBoard()

        XCTAssertTrue(board.place(.circle, in: 0).placed)
        XCTAssertTrue(board.place(.circle, in: 0).placed)
        let resolution = board.place(.circle, in: 0)

        XCTAssertEqual(resolution.removedCount, 3)
        XCTAssertEqual(resolution.cascadeCount, 1)
        XCTAssertEqual(resolution.scoreGained, 110)
        XCTAssertEqual(board.occupiedCount, 0)
    }

    @MainActor
    func testTransferPassengerConnectsMatchingDestinations() {
        var board = TrainBoard()
        _ = board.place(.circle, in: 0)
        _ = board.place(.transfer, in: 1)

        let resolution = board.place(.circle, in: 2)

        XCTAssertEqual(resolution.removedCount, 3)
        XCTAssertEqual(board.occupiedCount, 0)
    }

    @MainActor
    func testFullColumnOverflowsWithoutMutatingBoard() {
        var board = TrainBoard()
        let kinds: [PassengerKind] = [.circle, .triangle, .star, .square, .circle, .triangle, .star]
        kinds.forEach { _ = board.place($0, in: 0) }

        let resolution = board.place(.square, in: 0)

        XCTAssertTrue(resolution.overflowed)
        XCTAssertFalse(resolution.placed)
        XCTAssertEqual(board.occupiedCount, 7)
    }

    @MainActor
    func testDailySequenceIsDeterministic() {
        var first = SeededRandom(seed: 20260809)
        var second = SeededRandom(seed: 20260809)
        let firstSequence = (0..<20).map { index in
            GameRules.passengerKind(
                boarded: index,
                destinationCount: 4,
                transferInterval: 9,
                rng: &first
            )
        }
        let secondSequence = (0..<20).map { index in
            GameRules.passengerKind(
                boarded: index,
                destinationCount: 4,
                transferInterval: 9,
                rng: &second
            )
        }

        XCTAssertEqual(firstSequence, secondSequence)
        XCTAssertEqual(firstSequence[9], .transfer)
        XCTAssertEqual(firstSequence[18], .transfer)
    }

    @MainActor
    func testSelectorGetsFasterWithoutCrossingFloor() {
        let samples = stride(from: 0.0, through: 60.0, by: 1).map {
            GameRules.selectorPeriod(at: $0, duration: 60)
        }

        XCTAssertEqual(samples.first, 1.60)
        XCTAssertEqual(samples.last, 0.90)
        XCTAssertTrue(zip(samples, samples.dropFirst()).allSatisfy { $0 >= $1 })
        XCTAssertGreaterThanOrEqual(samples.min() ?? 0, 0.90)
    }

    @MainActor
    func testStageDifficultyStartsForgivingAndRisesMonotonically() {
        let stages = (1...12).map { GameRules.stageDifficulty(stage: $0) }

        XCTAssertEqual(stages[0].safetyHandles, 3)
        XCTAssertEqual(stages[0].title, "1역")
        XCTAssertEqual(stages[0].destinationCount, 3)
        XCTAssertEqual(stages[5].safetyHandles, 1)
        XCTAssertEqual(stages[5].destinationCount, 4)
        XCTAssertTrue(zip(stages, stages.dropFirst()).allSatisfy {
            $0.targetScore < $1.targetScore
        })
    }

    @MainActor
    func testRepeatedFailureAssistanceIsVisibleAndEasier() {
        let normal = GameRules.stageDifficulty(stage: 8, consecutiveFailures: 0)
        let assisted = GameRules.stageDifficulty(stage: 8, consecutiveFailures: 2)

        XCTAssertFalse(normal.assisted)
        XCTAssertTrue(assisted.assisted)
        XCTAssertLessThan(assisted.targetScore, normal.targetScore)
        XCTAssertGreaterThan(assisted.selectorPeriodScale, normal.selectorPeriodScale)
        XCTAssertLessThanOrEqual(assisted.transferInterval, normal.transferInterval)
    }

    @MainActor
    func testSafetyHandleAndRescueRemoveNoScorePassengers() {
        var board = TrainBoard()
        let kinds: [PassengerKind] = [.circle, .triangle, .star, .square, .circle, .triangle, .star]
        kinds.forEach { _ = board.place($0, in: 0) }
        kinds.prefix(5).forEach { _ = board.place($0, in: 1) }

        XCTAssertEqual(board.removeTopPassengers(from: 0, count: 3), 3)
        XCTAssertEqual(board.occupiedCount, 9)
        XCTAssertEqual(board.rescueTallestColumns(), 4)
        XCTAssertEqual(board.occupiedCount, 5)
    }

    @MainActor
    func testVersionOneProfileMigratesWithoutLosingScore() throws {
        let json = #"{"version":1,"bestScore":3210,"totalRuns":4,"totalExited":55,"tutorialSeen":true}"#
        let profile = try JSONDecoder().decode(PlayerProfile.self, from: Data(json.utf8))

        XCTAssertEqual(profile.version, 2)
        XCTAssertEqual(profile.bestScore, 3210)
        XCTAssertEqual(profile.totalRuns, 4)
        XCTAssertEqual(profile.highestStage, 1)
        XCTAssertFalse(profile.freeRescueUsed)
    }

    @MainActor
    func testFutureProfileVersionIsRejected() {
        let json = #"{"version":99,"bestScore":999999}"#

        XCTAssertThrowsError(
            try JSONDecoder().decode(PlayerProfile.self, from: Data(json.utf8))
        )
    }

    @MainActor
    func testCompletedResultHeadlineIncludesStageNumber() {
        let result = RunResult(
            score: 1_200,
            boarded: 20,
            exited: 12,
            bestChain: 2,
            completed: true,
            dailySeed: 20260809,
            stage: 7,
            targetScore: 1_100,
            rescueUsed: false,
            assisted: false
        )

        XCTAssertEqual(result.headline, "7역 통과!")
    }
}

#if !SWIFT_PACKAGE
@MainActor
private final class ControlledRewardedAdService: RewardedAdServing {
    var isReady: Bool { true }
    private(set) var continuation: CheckedContinuation<RewardedAdOutcome, Never>?

    func showRescueAd() async -> RewardedAdOutcome {
        await withCheckedContinuation { continuation = $0 }
    }

    func complete(with outcome: RewardedAdOutcome) {
        continuation?.resume(returning: outcome)
        continuation = nil
    }
}

@MainActor
final class AppModelLifecycleTests: XCTestCase {
    func testUnsupportedProfileIsBackedUpBeforeReset() {
        let suiteName = "AppModelLifecycleTests.profile.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let data = Data(#"{"version":99,"bestScore":999999}"#.utf8)
        defaults.set(data, forKey: "oneMoreCar.playerProfile.v1")

        let profile = PersistenceService(defaults: defaults).load()

        XCTAssertEqual(profile, PlayerProfile())
        XCTAssertEqual(defaults.data(forKey: "oneMoreCar.playerProfile.recovery"), data)
    }

    func testRewardFromReplacedRunIsIgnored() async {
        let context = makeAdTestContext()
        let model = context.model
        let service = context.service
        model.startGame()
        let staleScene = try! XCTUnwrap(model.currentScene)
        model.gameScene(staleScene, didEmit: .rescueRequested)

        let rewardTask = Task { await model.acceptRescue() }
        while service.continuation == nil { await Task.yield() }
        model.goHome()
        model.startGame()
        service.complete(with: .rewarded(impressionID: "stale-impression"))
        await rewardTask.value

        XCTAssertEqual(model.profile.rewardedContinuesUsedTotal, 0)
        XCTAssertFalse(model.hasPendingRescueReward)
    }

    func testRewardDoesNotResumeRunWhileAppIsInactive() async {
        let context = makeAdTestContext()
        let model = context.model
        let service = context.service
        model.startGame()
        let scene = try! XCTUnwrap(model.currentScene)
        model.gameScene(scene, didEmit: .rescueRequested)

        let rewardTask = Task { await model.acceptRescue() }
        while service.continuation == nil { await Task.yield() }
        model.setApplicationActive(false)
        service.complete(with: .rewarded(impressionID: "background-impression"))
        await rewardTask.value

        XCTAssertEqual(model.profile.rewardedContinuesUsedTotal, 1)
        XCTAssertTrue(model.showRescueOffer)
        XCTAssertTrue(model.hasPendingRescueReward)
    }

    private func makeAdTestContext() -> (
        model: AppModel,
        service: ControlledRewardedAdService
    ) {
        let suiteName = "AppModelLifecycleTests.ad.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(
            Data(#"{"version":2,"freeRescueUsed":true}"#.utf8),
            forKey: "oneMoreCar.playerProfile.v1"
        )
        let service = ControlledRewardedAdService()
        let model = AppModel(
            persistence: PersistenceService(defaults: defaults),
            seed: 20260809,
            rewardedAdService: service
        )
        addTeardownBlock { defaults.removePersistentDomain(forName: suiteName) }
        return (model, service)
    }
}
#endif
