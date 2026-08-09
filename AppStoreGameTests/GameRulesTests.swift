import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
#else
import SpriteKit
@testable import AppStoreGame
#endif

final class GameRulesTests: XCTestCase {
    @MainActor
    func testCountSnapshotDefaultsExposeAuthoritativeDoorState() {
        let snapshot = RunSnapshot()

        XCTAssertEqual(snapshot.onboardCount, 0)
        XCTAssertEqual(snapshot.targetOnboardCount, 0)
        XCTAssertEqual(snapshot.countRevision, 0)
        XCTAssertFalse(snapshot.canCloseDoors)
        XCTAssertNil(snapshot.lastCloseDelta)
        XCTAssertEqual(snapshot.flowProgress, 0)
        XCTAssertEqual(snapshot.flowPhase, .automaticExit)
    }

    @MainActor
    func testCountRunPlanIsSeededAndChainsFiveStations() {
        let difficulty = GameRules.stageDifficulty(stage: 1)
        let first = GameRules.countRunPlan(seed: 20260809, difficulty: difficulty)
        let replay = GameRules.countRunPlan(seed: 20260809, difficulty: difficulty)
        let different = GameRules.countRunPlan(seed: 20260810, difficulty: difficulty)

        XCTAssertEqual(first, replay)
        XCTAssertNotEqual(first, different)
        XCTAssertEqual(first.stations.count, 5)
        XCTAssertEqual(first.stations.map(\.index), [1, 2, 3, 4, 5])
        for index in 1..<first.stations.count {
            XCTAssertEqual(
                first.stations[index].initialOnboard,
                first.stations[index - 1].targetOnboard
            )
        }
    }

    @MainActor
    func testCountPlansAreSolvableAndWithinCapacityAcrossTenThousandSeeds() {
        let difficulty = GameRules.stageDifficulty(stage: 1)

        for seed in UInt64(0)..<10_000 {
            let plan = GameRules.countRunPlan(seed: seed, difficulty: difficulty)
            XCTAssertEqual(plan.stations.count, 5, "seed \(seed)")

            for station in plan.stations {
                XCTAssertFalse(station.exitEvents.isEmpty, "seed \(seed), station \(station.index)")
                XCTAssertFalse(station.boardingEvents.isEmpty, "seed \(seed), station \(station.index)")
                XCTAssertTrue(
                    station.boardingEvents.allSatisfy { $0.passengerCount == 1 },
                    "seed \(seed), station \(station.index)"
                )
                XCTAssertTrue(
                    zip(station.events, station.events.dropFirst()).allSatisfy {
                        $0.offsetMilliseconds < $1.offsetMilliseconds
                    },
                    "seed \(seed), station \(station.index)"
                )
                XCTAssertLessThanOrEqual(
                    station.deadlineMilliseconds,
                    12_000,
                    "seed \(seed), station \(station.index)"
                )

                var onboard = station.initialOnboard
                var boardingBegan = false
                var targetReachedAt: Int?
                var targetPassedAt: Int?
                for event in station.events {
                    switch event.direction {
                    case .exit:
                        XCTAssertFalse(boardingBegan, "exit after boarding: seed \(seed)")
                        onboard -= event.passengerCount
                    case .board:
                        boardingBegan = true
                        let previous = onboard
                        onboard += event.passengerCount
                        XCTAssertEqual(onboard, previous + 1, "seed \(seed)")
                        if onboard == station.targetOnboard, targetReachedAt == nil {
                            targetReachedAt = event.offsetMilliseconds
                        } else if let targetReachedAt,
                                  onboard == station.targetOnboard + 1,
                                  targetPassedAt == nil {
                            targetPassedAt = event.offsetMilliseconds
                            XCTAssertGreaterThanOrEqual(
                                targetPassedAt! - targetReachedAt,
                                station.minimumTargetHoldMilliseconds,
                                "seed \(seed), station \(station.index)"
                            )
                        }
                    }
                    XCTAssertTrue((0...station.capacity).contains(onboard), "seed \(seed)")
                }

                let exactTime = try! XCTUnwrap(targetReachedAt, "seed \(seed)")
                XCTAssertNotNil(targetPassedAt, "seed \(seed), station \(station.index)")
                let exactState = GameRules.advanceFlow(
                    state: GameRules.initialCountFlowState(for: station),
                    throughMilliseconds: exactTime,
                    plan: station
                ).state
                XCTAssertEqual(
                    GameRules.resolveDoorClose(
                        state: exactState,
                        plan: station,
                        observedCountRevision: exactState.countRevision
                    ).result,
                    .exact,
                    "seed \(seed), station \(station.index)"
                )
            }
        }
    }

    @MainActor
    func testAutomaticExitPrecedesMonotonicInteractiveBoarding() {
        let station = GameRules.countRunPlan(
            seed: 7,
            difficulty: GameRules.stageDifficulty(stage: 1)
        ).stations[0]
        let lastExitTime = try! XCTUnwrap(station.exitEvents.last?.offsetMilliseconds)

        let beforeLastExit = GameRules.advanceFlow(
            state: GameRules.initialCountFlowState(for: station),
            throughMilliseconds: lastExitTime - 1,
            plan: station
        )
        let afterLastExit = GameRules.advanceFlow(
            state: beforeLastExit.state,
            throughMilliseconds: lastExitTime,
            plan: station
        )

        XCTAssertEqual(beforeLastExit.state.phase, .automaticExit)
        XCTAssertEqual(afterLastExit.state.phase, .boarding)
        XCTAssertEqual(afterLastExit.appliedEvents, [station.exitEvents.last!])

        var state = afterLastExit.state
        var previousOnboard = state.onboardCount
        for event in station.boardingEvents {
            let advance = GameRules.advanceFlow(
                state: state,
                throughMilliseconds: event.offsetMilliseconds,
                plan: station
            )
            state = advance.state
            XCTAssertEqual(advance.appliedEvents, [event])
            XCTAssertEqual(state.onboardCount, previousOnboard + 1)
            previousOnboard = state.onboardCount
        }
    }

    @MainActor
    func testFlowAdvanceIsIndependentOfFrameCadenceAndLargeDelta() {
        let station = GameRules.countRunPlan(
            seed: 42,
            difficulty: GameRules.stageDifficulty(stage: 1)
        ).stations[3]
        let at30FPS = simulateFlow(station: station, frameMilliseconds: 33)
        let at60FPS = simulateFlow(station: station, frameMilliseconds: 16)
        let at120FPS = simulateFlow(station: station, frameMilliseconds: 8)
        let oneLargeDelta = GameRules.advanceFlow(
            state: GameRules.initialCountFlowState(for: station),
            throughMilliseconds: station.deadlineMilliseconds,
            plan: station
        )

        XCTAssertEqual(at30FPS.state, at60FPS.state)
        XCTAssertEqual(at60FPS.state, at120FPS.state)
        XCTAssertEqual(at120FPS.state, oneLargeDelta.state)
        XCTAssertEqual(at30FPS.eventIDs, station.events.map(\.id))
        XCTAssertEqual(at60FPS.eventIDs, at30FPS.eventIDs)
        XCTAssertEqual(at120FPS.eventIDs, at30FPS.eventIDs)
        XCTAssertEqual(oneLargeDelta.appliedEvents.map(\.id), at30FPS.eventIDs)
    }

    @MainActor
    func testFlowEventAppliesAtInclusiveThresholdExactlyOnce() {
        let station = GameRules.countRunPlan(
            seed: 99,
            difficulty: GameRules.stageDifficulty(stage: 1)
        ).stations[0]
        let firstEvent = station.events[0]
        let initial = GameRules.initialCountFlowState(for: station)
        let before = GameRules.advanceFlow(
            state: initial,
            throughMilliseconds: firstEvent.offsetMilliseconds - 1,
            plan: station
        )
        let threshold = GameRules.advanceFlow(
            state: before.state,
            throughMilliseconds: firstEvent.offsetMilliseconds,
            plan: station
        )
        let repeated = GameRules.advanceFlow(
            state: threshold.state,
            throughMilliseconds: firstEvent.offsetMilliseconds,
            plan: station
        )

        XCTAssertTrue(before.appliedEvents.isEmpty)
        XCTAssertEqual(before.state.countRevision, 0)
        XCTAssertEqual(threshold.appliedEvents, [firstEvent])
        XCTAssertEqual(threshold.state.countRevision, 1)
        XCTAssertTrue(repeated.appliedEvents.isEmpty)
        XCTAssertEqual(repeated.state, threshold.state)
    }

    @MainActor
    func testDoorCloseResolvesExactUnderOverAndRejectsStaleRevision() {
        let station = GameRules.countRunPlan(
            seed: 20260809,
            difficulty: GameRules.stageDifficulty(stage: 1)
        ).stations[0]
        let exitedCount = station.exitEvents.reduce(0) { $0 + $1.passengerCount }
        let boardingCountToTarget = station.targetOnboard
            - (station.initialOnboard - exitedCount)
        let targetEventIndex = station.exitEvents.count + boardingCountToTarget - 1
        let underEvent = station.events[targetEventIndex - 1]
        let targetEvent = station.events[targetEventIndex]
        let overEvent = station.events[targetEventIndex + 1]
        let initial = GameRules.initialCountFlowState(for: station)
        let underState = GameRules.advanceFlow(
            state: initial,
            throughMilliseconds: underEvent.offsetMilliseconds,
            plan: station
        ).state
        let exactState = GameRules.advanceFlow(
            state: underState,
            throughMilliseconds: targetEvent.offsetMilliseconds,
            plan: station
        ).state
        let overState = GameRules.advanceFlow(
            state: exactState,
            throughMilliseconds: overEvent.offsetMilliseconds,
            plan: station
        ).state

        let under = GameRules.resolveDoorClose(
            state: underState,
            plan: station,
            observedCountRevision: underState.countRevision
        )
        let exact = GameRules.resolveDoorClose(
            state: exactState,
            plan: station,
            observedCountRevision: exactState.countRevision
        )
        let over = GameRules.resolveDoorClose(
            state: overState,
            plan: station,
            observedCountRevision: overState.countRevision
        )
        let stale = GameRules.resolveDoorClose(
            state: exactState,
            plan: station,
            observedCountRevision: exactState.countRevision - 1
        )

        XCTAssertEqual(under.result, .under(by: 1))
        XCTAssertEqual(under.signedDelta, -1)
        XCTAssertEqual(exact.result, .exact)
        XCTAssertEqual(exact.signedDelta, 0)
        XCTAssertEqual(over.result, .over(by: 1))
        XCTAssertEqual(over.signedDelta, 1)
        XCTAssertEqual(stale.result, .stale)
        XCTAssertFalse(stale.shouldCloseDoors)
        XCTAssertNil(stale.signedDelta)
    }

    @MainActor
    func testDoorCloseIsUnavailableDuringAutomaticExitAndAutoResolvesAtDeadline() {
        let station = GameRules.countRunPlan(
            seed: 1,
            difficulty: GameRules.stageDifficulty(stage: 1)
        ).stations[0]
        let initial = GameRules.initialCountFlowState(for: station)
        let timedOut = GameRules.advanceFlow(
            state: initial,
            throughMilliseconds: station.deadlineMilliseconds,
            plan: station
        ).state

        XCTAssertEqual(
            GameRules.resolveDoorClose(
                state: initial,
                plan: station,
                observedCountRevision: initial.countRevision
            ).result,
            .stale
        )
        XCTAssertEqual(timedOut.phase, .timedOut)
        let timedOutResolution = GameRules.resolveDoorClose(
            state: timedOut,
            plan: station,
            observedCountRevision: timedOut.countRevision
        )
        XCTAssertTrue(timedOutResolution.shouldCloseDoors)
        XCTAssertNotEqual(timedOutResolution.result, .stale)
    }

    @MainActor
    func testRunSnapshotRoutingDefaultsMatchFourDoorContract() {
        let snapshot = RunSnapshot()

        XCTAssertEqual(snapshot.destinationProgress.count, 4)
        XCTAssertTrue(PassengerKind.destinations.allSatisfy {
            snapshot.destinationProgress[$0] == 0
        })
        XCTAssertEqual(snapshot.doorDestinations, PassengerKind.destinations)
        XCTAssertEqual(snapshot.currentQueueSize, 0)
        XCTAssertEqual(snapshot.selectedDoor, 0)
        XCTAssertEqual(snapshot.routingQueueIndex, 0)
        XCTAssertEqual(snapshot.routingQueueCount, 10)
        XCTAssertNil(snapshot.lastRoutingCorrect)
        XCTAssertFalse(snapshot.clockStarted)
    }

    @MainActor
    func testRoutingPlanHasFourDoorsTenQueuesAcrossFiveStations() {
        let plan = GameRules.routingRunPlan(seed: 20260809)

        XCTAssertEqual(plan.stations.count, 5)
        XCTAssertEqual(plan.queues.count, 10)
        XCTAssertEqual(Set(plan.queues.map(\.id)).count, 10)
        XCTAssertEqual(plan.stations.map(\.index), [1, 2, 3, 4, 5])
        for station in plan.stations {
            XCTAssertEqual(station.queues.count, 2)
            XCTAssertEqual(station.queues.map(\.positionInStation), [0, 1])
            XCTAssertEqual(Set(station.queues.map(\.destination)).count, 2)
            XCTAssertEqual(station.doorOrder.count, 4)
            XCTAssertEqual(Set(station.doorOrder), Set(PassengerKind.destinations))
            XCTAssertTrue(station.queues.allSatisfy { $0.stationIndex == station.index })
        }
    }

    @MainActor
    func testRoutingPlanCompletesExactlyThreePassengersPerDestination() {
        let plan = GameRules.routingRunPlan(seed: 7)

        XCTAssertEqual(plan.queues.reduce(0) { $0 + $1.passengerCount }, 12)
        for destination in PassengerKind.destinations {
            XCTAssertEqual(plan.passengerTotal(for: destination), 3)
        }
    }

    @MainActor
    func testRoutingDoorOrdersAndQueuesAreDeterministicForSeed() {
        let first = GameRules.routingRunPlan(seed: 42)
        let second = GameRules.routingRunPlan(seed: 42)
        let different = GameRules.routingRunPlan(seed: 43)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, different)
        XCTAssertGreaterThan(Set(first.stations.map(\.doorOrder)).count, 1)
    }

    @MainActor
    func testDoorSelectionMovesOneStepAndClampsAtBounds() {
        XCTAssertEqual(GameRules.moveDoorSelection(current: 0, move: .left), 0)
        XCTAssertEqual(GameRules.moveDoorSelection(current: 0, move: .right), 1)
        XCTAssertEqual(GameRules.moveDoorSelection(current: 2, move: .left), 1)
        XCTAssertEqual(GameRules.moveDoorSelection(current: 2, move: .right), 3)
        XCTAssertEqual(GameRules.moveDoorSelection(current: 3, move: .right), 3)
        XCTAssertEqual(GameRules.moveDoorSelection(current: -10, move: .right), 1)
        XCTAssertEqual(GameRules.moveDoorSelection(current: 99, move: .left), 2)
        XCTAssertEqual(GameRules.moveDoorSelection(current: 0, move: .right, doorCount: 0), 0)
    }

    @MainActor
    func testRoutingResolutionAdvancesOnlyForCorrectDoor() {
        let plan = GameRules.routingRunPlan(seed: 20260809)
        let station = plan.stations[0]
        let queue = station.queues[0]
        let correctDoor = try! XCTUnwrap(station.doorOrder.firstIndex(of: queue.destination))
        let wrongDoor = station.doorOrder.indices.first { $0 != correctDoor }!

        let correct = GameRules.resolveRouting(
            queue: queue,
            selectedDoorIndex: correctDoor,
            doorOrder: station.doorOrder
        )
        let wrong = GameRules.resolveRouting(
            queue: queue,
            selectedDoorIndex: wrongDoor,
            doorOrder: station.doorOrder
        )
        let invalid = GameRules.resolveRouting(
            queue: queue,
            selectedDoorIndex: 99,
            doorOrder: station.doorOrder
        )

        XCTAssertEqual(correct.outcome, .correct)
        XCTAssertEqual(correct.completedPassengerCount, queue.passengerCount)
        XCTAssertTrue(correct.shouldAdvanceQueue)
        XCTAssertFalse(correct.queueRemainsAvailable)

        XCTAssertEqual(wrong.outcome, .wrong)
        XCTAssertEqual(wrong.completedPassengerCount, 0)
        XCTAssertFalse(wrong.shouldAdvanceQueue)
        XCTAssertTrue(wrong.queueRemainsAvailable)
        XCTAssertEqual(wrong.expectedDestination, queue.destination)

        XCTAssertEqual(invalid.outcome, .wrong)
        XCTAssertNil(invalid.selectedDestination)
        XCTAssertTrue(invalid.queueRemainsAvailable)
    }

    @MainActor
    func testRoutingPlansRemainSolvableAcrossSeeds() {
        for seed in UInt64(0)..<512 {
            let plan = GameRules.routingRunPlan(seed: seed)
            var completedByDestination: [PassengerKind: Int] = [:]

            for station in plan.stations {
                for queue in station.queues {
                    let door = try! XCTUnwrap(station.doorOrder.firstIndex(of: queue.destination))
                    let resolution = GameRules.resolveRouting(
                        queue: queue,
                        selectedDoorIndex: door,
                        doorOrder: station.doorOrder
                    )
                    XCTAssertEqual(resolution.outcome, .correct, "seed \(seed), queue \(queue.id)")
                    completedByDestination[queue.destination, default: 0] += resolution.completedPassengerCount
                }
            }

            XCTAssertEqual(plan.queues.count, 10, "seed \(seed)")
            for destination in PassengerKind.destinations {
                XCTAssertEqual(completedByDestination[destination], 3, "seed \(seed), \(destination)")
            }
        }
    }

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

    @MainActor
    private func simulateFlow(
        station: StationCountPlan,
        frameMilliseconds: Int
    ) -> (state: CountFlowState, eventIDs: [Int]) {
        var state = GameRules.initialCountFlowState(for: station)
        var eventIDs: [Int] = []
        var time = 0
        while time < station.deadlineMilliseconds {
            time = min(station.deadlineMilliseconds, time + frameMilliseconds)
            let advance = GameRules.advanceFlow(
                state: state,
                throughMilliseconds: time,
                plan: station
            )
            state = advance.state
            eventIDs.append(contentsOf: advance.appliedEvents.map(\.id))
        }
        return (state, eventIDs)
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
    func testFiveExactCountClosesCompleteRun() {
        let difficulty = GameRules.stageDifficulty(stage: 1)
        let scene = GameScene(
            size: CGSize(width: 390, height: 844),
            seed: 20260809,
            difficulty: difficulty
        )
        let recorder = RecordingTrainSceneDelegate()
        scene.gameDelegate = recorder
        scene.didMove(to: SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844)))

        var time: TimeInterval = 1
        scene.update(time)
        for stationNumber in 1...5 {
            var frames = 0
            while (!recorder.latestSnapshot.canCloseDoors
                    || recorder.latestSnapshot.onboardCount != recorder.latestSnapshot.targetOnboardCount),
                  recorder.result == nil,
                  frames < 1_200 {
                time += 1.0 / 60.0
                scene.update(time)
                frames += 1
            }
            XCTAssertLessThan(frames, 1_200, "station \(stationNumber) never reached target")
            let observedRevision = recorder.latestSnapshot.countRevision
            scene.closeDoors(observedRevision: observedRevision)

            frames = 0
            while recorder.latestSnapshot.stopIndex == stationNumber,
                  recorder.result == nil,
                  frames < 240 {
                time += 1.0 / 60.0
                scene.update(time)
                frames += 1
            }
        }

        let result = try! XCTUnwrap(recorder.result)
        XCTAssertTrue(result.completed)
        XCTAssertGreaterThan(result.exited, 0)
        XCTAssertGreaterThan(result.boarded, 0)
        XCTAssertFalse(recorder.rescueRequested)
        XCTAssertEqual(recorder.latestSnapshot.lastCloseDelta, 0)
        XCTAssertGreaterThan(recorder.latestSnapshot.elapsed, 0)
        XCTAssertLessThan(recorder.latestSnapshot.elapsed, 60)
        XCTAssertEqual(recorder.latestSnapshot.phase, .finished)
    }

    func testStaleCountRevisionDoesNotCloseDoorsOrResolveStation() {
        let scene = GameScene(
            size: CGSize(width: 390, height: 844),
            seed: 42,
            difficulty: GameRules.stageDifficulty(stage: 1)
        )
        let recorder = RecordingTrainSceneDelegate()
        scene.gameDelegate = recorder
        scene.didMove(to: SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844)))

        var time: TimeInterval = 1
        scene.update(time)
        var frames = 0
        while (!recorder.latestSnapshot.canCloseDoors
                || recorder.latestSnapshot.onboardCount != recorder.latestSnapshot.targetOnboardCount),
              frames < 1_200 {
            time += 1.0 / 60.0
            scene.update(time)
            frames += 1
        }
        let currentRevision = recorder.latestSnapshot.countRevision
        scene.closeDoors(observedRevision: currentRevision - 1)

        XCTAssertEqual(recorder.latestSnapshot.stopIndex, 1)
        XCTAssertTrue(recorder.latestSnapshot.doorsOpen)
        XCTAssertTrue(recorder.latestSnapshot.canCloseDoors)
        XCTAssertNil(recorder.latestSnapshot.lastCloseDelta)
        XCTAssertNil(recorder.result)
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
