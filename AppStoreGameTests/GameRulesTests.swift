import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
#else
import SpriteKit
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
        XCTAssertEqual(stages[0].title, "1단계")
        XCTAssertTrue(stages.allSatisfy { $0.duration == 60 })
        XCTAssertEqual(stages[0].destinationCount, 3)
        XCTAssertEqual(stages[5].safetyHandles, 1)
        XCTAssertEqual(stages[5].destinationCount, 4)
        XCTAssertTrue(zip(stages, stages.dropFirst()).allSatisfy {
            $0.targetScore <= $1.targetScore
        })
        XCTAssertTrue(stages.allSatisfy { $0.targetScore <= 1_500 })
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
    func testBrakingDifficultyTargetExitedRisesAndAssistanceLowersIt() {
        let stages = (1...12).map { GameRules.stageDifficulty(stage: $0) }
        let normal = GameRules.stageDifficulty(stage: 8, consecutiveFailures: 0)
        let assisted = GameRules.stageDifficulty(stage: 8, consecutiveFailures: 2)

        XCTAssertEqual(stages[0].targetExited, 22)
        XCTAssertTrue(stages.allSatisfy { $0.stationCount == 5 })
        XCTAssertTrue(zip(stages, stages.dropFirst()).allSatisfy {
            $0.targetExited <= $1.targetExited
        })
        XCTAssertLessThan(assisted.targetExited, normal.targetExited)
    }

    @MainActor
    func testFiveStationPlansMatchUXContract() {
        let difficulty = GameRules.stageDifficulty(stage: 1)
        let plans = (1...5).map { GameRules.stationPlan(index: $0, difficulty: difficulty) }

        XCTAssertEqual(plans.map(\.exitDemand), [5, 6, 6, 7, 8])
        XCTAssertEqual(plans.map(\.perfectWindow), [0.25, 0.22, 0.19, 0.17, 0.15])
        XCTAssertEqual(plans.map(\.safeWindow), [0.55, 0.48, 0.42, 0.36, 0.32])
        XCTAssertEqual(plans.map(\.nearWindow), [0.85, 0.75, 0.65, 0.56, 0.50])
        XCTAssertEqual(plans.map(\.speedScale), [1.0, 1.0, 1.10, 1.18, 1.25])
        XCTAssertTrue(plans.allSatisfy { !$0.name.isEmpty })
        XCTAssertEqual(GameRules.stationPlan(index: 0, difficulty: difficulty), plans[0])
        XCTAssertEqual(GameRules.stationPlan(index: 6, difficulty: difficulty), plans[4])
    }

    @MainActor
    func testResolveBrakeUsesInclusiveGradeBoundariesAndCeilRewards() {
        let plan = GameRules.stationPlan(
            index: 1,
            difficulty: GameRules.stageDifficulty(stage: 1)
        )

        let perfect = GameRules.resolveBrake(tappedAt: plan.optimalBrakeTime, plan: plan)
        let perfectBoundary = GameRules.resolveBrake(
            tappedAt: plan.optimalBrakeTime - plan.perfectWindow,
            plan: plan
        )
        let safeBoundary = GameRules.resolveBrake(
            tappedAt: plan.optimalBrakeTime + plan.safeWindow,
            plan: plan
        )
        let nearBoundary = GameRules.resolveBrake(
            tappedAt: plan.optimalBrakeTime + plan.nearWindow,
            plan: plan
        )
        let missed = GameRules.resolveBrake(
            tappedAt: plan.optimalBrakeTime + plan.nearWindow + 0.001,
            plan: plan
        )

        XCTAssertEqual(perfect.grade, .perfect)
        XCTAssertEqual(perfect.exitedCount, 5)
        XCTAssertEqual(perfect.scoreGained, 300)
        XCTAssertEqual(perfect.timingError ?? 1, 0, accuracy: 0.000_001)
        XCTAssertEqual(perfect.finalOffset, 0, accuracy: 0.000_001)
        XCTAssertEqual(perfectBoundary.grade, .perfect)
        XCTAssertEqual(safeBoundary.grade, .safe)
        XCTAssertEqual(safeBoundary.exitedCount, 4)
        XCTAssertEqual(safeBoundary.scoreGained, 200)
        XCTAssertEqual(nearBoundary.grade, .near)
        XCTAssertEqual(nearBoundary.exitedCount, 3)
        XCTAssertEqual(nearBoundary.scoreGained, 100)
        XCTAssertEqual(missed.grade, .missed)
        XCTAssertEqual(missed.exitedCount, 0)
        XCTAssertEqual(missed.scoreGained, 0)
    }

    @MainActor
    func testResolveBrakeNilAndOutOfRangeInputsAreMissed() {
        let plan = GameRules.stationPlan(
            index: 3,
            difficulty: GameRules.stageDifficulty(stage: 1)
        )

        let noTap = GameRules.resolveBrake(tappedAt: nil, plan: plan)
        let beforeApproach = GameRules.resolveBrake(tappedAt: -0.001, plan: plan)
        let afterApproach = GameRules.resolveBrake(
            tappedAt: plan.approachDuration + 0.001,
            plan: plan
        )

        XCTAssertEqual(noTap.grade, .missed)
        XCTAssertNil(noTap.timingError)
        XCTAssertEqual(noTap.finalOffset, 1)
        XCTAssertEqual(beforeApproach.grade, .missed)
        XCTAssertEqual(afterApproach.grade, .missed)
        XCTAssertEqual(beforeApproach.exitedCount, 0)
        XCTAssertEqual(afterApproach.exitedCount, 0)
    }

    @MainActor
    func testBrakeResolutionIsDeterministicForSameInput() {
        let plan = GameRules.stationPlan(
            index: 5,
            difficulty: GameRules.stageDifficulty(stage: 6, consecutiveFailures: 2)
        )
        let tap = plan.optimalBrakeTime + 0.3

        XCTAssertEqual(
            GameRules.resolveBrake(tappedAt: tap, plan: plan),
            GameRules.resolveBrake(tappedAt: tap, plan: plan)
        )
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

        XCTAssertEqual(profile.version, 3)
        XCTAssertEqual(profile.bestScore, 3210)
        XCTAssertEqual(profile.totalRuns, 4)
        XCTAssertEqual(profile.highestStage, 1)
        XCTAssertFalse(profile.freeRescueUsed)
        XCTAssertFalse(profile.tutorialSeen)
    }

    @MainActor
    func testVersionTwoProfileStartsNewBrakeRulesAtStageOne() throws {
        let json = #"{"version":2,"bestScore":1655,"highestStage":8,"consecutiveFailures":2,"freeRescueUsed":true}"#
        let profile = try JSONDecoder().decode(PlayerProfile.self, from: Data(json.utf8))

        XCTAssertEqual(profile.version, 3)
        XCTAssertEqual(profile.bestScore, 1655)
        XCTAssertEqual(profile.highestStage, 1)
        XCTAssertEqual(profile.consecutiveFailures, 0)
        XCTAssertFalse(profile.freeRescueUsed)
        XCTAssertFalse(profile.tutorialSeen)
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

        XCTAssertEqual(result.headline, "7단계 운행 성공!")
    }
}

#if !SWIFT_PACKAGE
@MainActor
private final class RecordingTrainSceneDelegate: TrainGameSceneDelegate {
    var latestSnapshot = RunSnapshot()
    var result: RunResult?
    var rescueRequested = false

    func gameScene(_ scene: GameScene, didEmit event: GameEvent) {
        switch event {
        case .snapshot(let snapshot):
            latestSnapshot = snapshot
        case .rescueRequested:
            rescueRequested = true
        case .finished(let result):
            self.result = result
        case .perfect, .match, .overflow:
            break
        }
    }
}

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
final class GameSceneIntegrationTests: XCTestCase {
    func testFivePerfectStopsFinishAtSixtySecondsWithoutRescue() {
        let difficulty = GameRules.stageDifficulty(stage: 1)
        let scene = GameScene(
            size: CGSize(width: 390, height: 844),
            seed: 20260809,
            difficulty: difficulty
        )
        let recorder = RecordingTrainSceneDelegate()
        scene.gameDelegate = recorder
        scene.didMove(to: SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844)))

        var time: TimeInterval = 0
        for stop in 1...5 {
            var frames = 0
            while recorder.latestSnapshot.stopIndex == stop,
                  recorder.latestSnapshot.approachProgress < 0.75,
                  frames < 600 {
                time += 1.0 / 60.0
                scene.update(time)
                frames += 1
            }
            scene.applyBrake()

            frames = 0
            while recorder.latestSnapshot.stopIndex == stop,
                  recorder.result == nil,
                  frames < 600 {
                time += 1.0 / 60.0
                scene.update(time)
                frames += 1
            }
        }

        let result = try! XCTUnwrap(recorder.result)
        XCTAssertTrue(result.completed)
        XCTAssertEqual(result.exited, 32)
        XCTAssertFalse(recorder.rescueRequested)
        XCTAssertEqual(recorder.latestSnapshot.elapsed, 60, accuracy: 0.001)
        XCTAssertEqual(recorder.latestSnapshot.phase, .finished)
    }
}

@MainActor
final class AppModelLifecycleTests: XCTestCase {
    func testEventsFromReplacedSceneCannotMutateCurrentRun() {
        let suiteName = "AppModelLifecycleTests.staleScene.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(
            persistence: PersistenceService(defaults: defaults),
            seed: 20260809,
            rewardedAdService: ControlledRewardedAdService()
        )
        model.startGame()
        let staleScene = try! XCTUnwrap(model.currentScene)
        model.goHome()
        model.startGame()
        let currentScene = try! XCTUnwrap(model.currentScene)

        var staleSnapshot = RunSnapshot()
        staleSnapshot.score = 99_999
        model.gameScene(staleScene, didEmit: .snapshot(staleSnapshot))

        XCTAssertTrue(model.currentScene === currentScene)
        XCTAssertNotEqual(model.snapshot.score, 99_999)
        XCTAssertEqual(model.route, .game)
    }

    func testFirstRunCoachmarkPersistsUntilFirstBrakeResult() {
        let suiteName = "AppModelLifecycleTests.tutorial.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let model = AppModel(
            persistence: PersistenceService(defaults: defaults),
            seed: 20260809,
            rewardedAdService: ControlledRewardedAdService()
        )

        model.startGame()
        XCTAssertTrue(model.showTutorial)

        let scene = try! XCTUnwrap(model.currentScene)
        model.gameScene(scene, didEmit: .match(5))

        XCTAssertFalse(model.showTutorial)
        XCTAssertTrue(model.profile.tutorialSeen)
    }

    func testRewardedContinueIsUnavailableBeforeThreeRuns() {
        let suiteName = "AppModelLifecycleTests.earlyAd.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(
            Data(#"{"version":3,"totalRuns":2,"freeRescueUsed":true}"#.utf8),
            forKey: "oneMoreCar.playerProfile.v1"
        )
        let model = AppModel(
            persistence: PersistenceService(defaults: defaults),
            seed: 20260809,
            rewardedAdService: ControlledRewardedAdService()
        )

        XCTAssertFalse(model.isRewardedAdAvailable)
    }

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

    func testDuplicateRewardImpressionIsCountedOnlyOnce() async {
        let context = makeAdTestContext()
        let model = context.model
        let service = context.service
        model.startGame()
        let scene = try! XCTUnwrap(model.currentScene)

        model.gameScene(scene, didEmit: .rescueRequested)
        let firstTask = Task { await model.acceptRescue() }
        while service.continuation == nil { await Task.yield() }
        service.complete(with: .rewarded(impressionID: "duplicate-impression"))
        await firstTask.value

        model.gameScene(scene, didEmit: .rescueRequested)
        let duplicateTask = Task { await model.acceptRescue() }
        while service.continuation == nil { await Task.yield() }
        service.complete(with: .rewarded(impressionID: "duplicate-impression"))
        await duplicateTask.value

        XCTAssertEqual(model.profile.rewardedContinuesUsedTotal, 1)
    }

    private func makeAdTestContext() -> (
        model: AppModel,
        service: ControlledRewardedAdService
    ) {
        let suiteName = "AppModelLifecycleTests.ad.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(
            Data(#"{"version":3,"totalRuns":3,"freeRescueUsed":true}"#.utf8),
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
