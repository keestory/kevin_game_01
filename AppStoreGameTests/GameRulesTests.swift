import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
#else
@testable import AppStoreGame
#endif

@MainActor
final class GameRulesTests: XCTestCase {
    func testInitialStateAndStructureAreDeterministic() {
        let first = GameRules.initialReturnShotState(seed: 20_260_817)
        let replay = GameRules.initialReturnShotState(seed: 20_260_817)
        let different = GameRules.initialReturnShotState(seed: 20_260_818)

        XCTAssertEqual(first, replay)
        XCTAssertNotEqual(first.bricks, different.bricks)
        XCTAssertEqual(first.bricks.count, 30)
        XCTAssertEqual(first.bricks.filter { $0.role == .support }.count, 6)
        XCTAssertEqual(first.bricks.filter { $0.role == .prism }.count, 0)
        XCTAssertEqual(first.bricks.filter { $0.role == .negative }.count, 0)
        XCTAssertTrue(first.bricks.filter { $0.anchored }.allSatisfy { $0.role == .support })
    }

    func testDifficultyProfileIsMonotonicCappedAndUnlocksRolesByLevel() {
        let expectedSpeeds = [370.0, 388.0, 407.0, 425.0, 444.0]
        for (segment, speed) in expectedSpeeds.enumerated() {
            XCTAssertEqual(
                GameRules.difficultyProfile(segment: segment).entryBallSpeed,
                speed,
                accuracy: 0.001
            )
        }

        let expectedRoles = [
            (segment: 0, armor: 0, prism: 0, negative: 0),
            (segment: 1, armor: 0, prism: 1, negative: 0),
            (segment: 2, armor: 0, prism: 1, negative: 1),
            (segment: 3, armor: 1, prism: 2, negative: 2),
            (segment: 5, armor: 1, prism: 2, negative: 2),
            (segment: 6, armor: 2, prism: 2, negative: 2)
        ]
        for expected in expectedRoles {
            let profile = GameRules.difficultyProfile(segment: expected.segment)
            let bricks = GameRules.returnShotBricks(seed: 7, segment: expected.segment)
            XCTAssertEqual(profile.level, expected.segment + 1)
            XCTAssertEqual(profile.armorLayers, expected.armor)
            XCTAssertEqual(profile.prismCount, expected.prism)
            XCTAssertEqual(profile.negativeCount, expected.negative)
            XCTAssertEqual(bricks.filter { $0.role == .prism }.count, expected.prism)
            XCTAssertEqual(bricks.filter { $0.role == .negative }.count, expected.negative)
        }

        var previous = GameRules.difficultyProfile(segment: 0)
        for segment in 1...100 {
            let current = GameRules.difficultyProfile(segment: segment)
            XCTAssertGreaterThanOrEqual(current.entryBallSpeed, previous.entryBallSpeed)
            XCTAssertGreaterThanOrEqual(current.armorLayers, previous.armorLayers)
            XCTAssertGreaterThanOrEqual(current.prismCount, previous.prismCount)
            XCTAssertGreaterThanOrEqual(current.negativeCount, previous.negativeCount)
            XCTAssertLessThanOrEqual(current.entryBallSpeed, 518)
            XCTAssertLessThanOrEqual(current.armorLayers, 2)
            previous = current
        }
        XCTAssertEqual(GameRules.difficultyProfile(segment: 100).entryBallSpeed, 518)
    }

    func testTenThousandSeedStructuresRemainDeterministicValidAndClearableWithoutItems() {
        for seed in UInt64(0)..<10_000 {
            let segment = Int(seed % 12)
            let first = GameRules.returnShotBricks(seed: seed, segment: segment)
            let replay = GameRules.returnShotBricks(seed: seed, segment: segment)
            let ids = Set(first.map(\.id))
            let carriers = first.filter { $0.embeddedItem != nil }

            XCTAssertEqual(first, replay)
            XCTAssertEqual(Set(first.map(\.id)).count, first.count)
            XCTAssertEqual(carriers.count, 1)
            XCTAssertEqual(carriers.first?.role, .normal)
            XCTAssertTrue(first.allSatisfy { brick in
                brick.supportIDs.allSatisfy { supportID in
                    ids.contains(supportID) && supportID < brick.id
                }
            })
            XCTAssertTrue(first.filter { !$0.anchored }.allSatisfy { !$0.supportIDs.isEmpty })
            XCTAssertTrue(first.filter { $0.role == .normal }.allSatisfy {
                $0.maximumHitPoints + $0.maximumArmor <= 3
            })

            var clearState = stateWith(bricks: first)
            for index in clearState.bricks.indices where clearState.bricks[index].role != .negative {
                clearState.bricks[index].isRemoved = true
                clearState.bricks[index].hitPoints = 0
            }
            _ = GameRules.collapseUnsupported(state: &clearState)
            XCTAssertTrue(clearState.bricks.allSatisfy(\.isRemoved))
        }
    }

    func testEverySupportReferenceExistsAndStructureStaysInsidePlayfield() {
        for seed in UInt64(0)..<512 {
            let bricks = GameRules.returnShotBricks(seed: seed, segment: 3)
            let ids = Set(bricks.map(\.id))

            for brick in bricks {
                XCTAssertTrue(brick.supportIDs.allSatisfy(ids.contains))
                XCTAssertGreaterThanOrEqual(brick.rect.minX, GameRules.sideWall)
                XCTAssertLessThanOrEqual(brick.rect.maxX, GameRules.fieldWidth - GameRules.sideWall)
                XCTAssertGreaterThan(brick.rect.minY, GameRules.paddleY)
                XCTAssertLessThan(brick.rect.maxY, GameRules.topWall)
            }
        }
    }

    func testPaddleOffsetAndVelocityChangeReturnAngle() {
        let center = GameRules.reflectionVelocity(contactOffset: 0, paddleVelocity: 0, speed: 400)
        let rightEdge = GameRules.reflectionVelocity(contactOffset: 1, paddleVelocity: 0, speed: 400)
        let movingLeft = GameRules.reflectionVelocity(contactOffset: 0, paddleVelocity: -720, speed: 400)

        XCTAssertEqual(center.x, 0, accuracy: 0.001)
        XCTAssertGreaterThan(center.y, 390)
        XCTAssertGreaterThan(rightEdge.x, 0)
        XCTAssertLessThan(movingLeft.x, 0)
        XCTAssertEqual(rightEdge.length, 400, accuracy: 0.001)
        XCTAssertEqual(movingLeft.length, 400, accuracy: 0.001)
    }

    func testIndependentAttributeLinksTriggerOneSixSecondPowerAtFive() {
        var state = GameRules.initialReturnShotState(seed: 1)
        let signature = BrickSignature(color: .mint, pattern: .stripe, mark: .star)

        for expected in 1...5 {
            _ = GameRules.updateAttributeLink(state: &state, signature: signature)
            XCTAssertEqual(state.link.colorCount, expected)
            XCTAssertEqual(state.link.patternCount, expected)
            XCTAssertEqual(state.link.markCount, expected)
        }

        XCTAssertEqual(state.powerTicks, GameRules.powerDurationTicks)
        XCTAssertEqual(state.powerActivations, 1)
        XCTAssertEqual(state.maxLink, 5)

        _ = GameRules.updateAttributeLink(
            state: &state,
            signature: BrickSignature(color: .coral, pattern: .stripe, mark: .circle)
        )
        XCTAssertEqual(state.link.colorCount, 1)
        XCTAssertEqual(state.link.patternCount, 6)
        XCTAssertEqual(state.link.markCount, 1)
        XCTAssertEqual(state.powerActivations, 1)
    }

    func testPrismNeedsThreeDirectHitsAndAdvancesLinkOnlyOnce() {
        let signature = BrickSignature(color: .blue, pattern: .grid, mark: .triangle)
        var state = stateWith(
            bricks: [brick(id: 1, role: .prism, hitPoints: 3, signature: signature, anchored: true)]
        )

        let first = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertEqual(state.bricks[0].hitPoints, 2)
        XCTAssertEqual(state.link.highestCount, 1)
        XCTAssertFalse(state.bricks[0].isRemoved)
        XCTAssertTrue(first.shouldReflect)

        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertEqual(state.bricks[0].hitPoints, 1)
        XCTAssertEqual(state.link.highestCount, 1)

        let third = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertTrue(state.bricks[0].isRemoved)
        XCTAssertEqual(state.link.highestCount, 1)
        XCTAssertEqual(state.destroyedBrickCount, 1)
        XCTAssertTrue(third.events.contains { event in
            if case .brickRemoved(id: 1, cause: .direct, points: _) = event { return true }
            return false
        })
    }

    func testNegativeBrickPenalizesTwiceWithCooldownAndNeverBreaksDirectly() {
        var state = stateWith(
            bricks: [brick(id: 9, role: .negative, hitPoints: Int.max, signature: nil, anchored: true)]
        )
        state.tick = 100
        state.score = 1_000
        state.combo = 4
        state.link = AttributeLinkState(
            previousSignature: BrickSignature(color: .mint, pattern: .dot, mark: .circle),
            colorCount: 4,
            patternCount: 2,
            markCount: 1
        )
        state.powerTicks = 4 * GameRules.tickRate

        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 9)
        XCTAssertEqual(state.score, 750)
        XCTAssertEqual(state.combo, 0)
        XCTAssertEqual(state.link, AttributeLinkState())
        XCTAssertEqual(state.powerTicks, 2 * GameRules.tickRate)
        XCTAssertEqual(state.bricks[0].penaltyHits, 1)
        XCTAssertFalse(state.bricks[0].isRemoved)

        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 9)
        XCTAssertEqual(state.score, 750)

        state.tick += 90
        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 9)
        XCTAssertEqual(state.score, 500)
        XCTAssertEqual(state.bricks[0].penaltyHits, 2)

        state.tick += 90
        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 9)
        XCTAssertEqual(state.score, 500)
        XCTAssertFalse(state.bricks[0].isRemoved)
    }

    func testSupportCollapseRemovesPositiveAndPaysCleanDropForNegative() {
        let support = brick(id: 1, role: .support, hitPoints: 0, signature: nil, anchored: true, removed: true)
        let normal = brick(
            id: 2,
            role: .normal,
            hitPoints: 1,
            signature: BrickSignature(color: .coral, pattern: .stripe, mark: .circle),
            supportIDs: [1]
        )
        let negative = brick(id: 3, role: .negative, hitPoints: Int.max, signature: nil, supportIDs: [1])
        var state = stateWith(bricks: [support, normal, negative])

        let events = GameRules.collapseUnsupported(state: &state)

        XCTAssertTrue(state.bricks[1].isRemoved)
        XCTAssertTrue(state.bricks[2].isRemoved)
        XCTAssertEqual(state.score, 165)
        XCTAssertEqual(state.destroyedBrickCount, 2)
        XCTAssertEqual(state.combo, 1)
        XCTAssertTrue(events.contains(.cleanDrop(id: 3, points: 120)))
    }

    func testSweptCollisionPreventsFastBallTunnelingThroughBrick() {
        let target = brick(
            id: 4,
            role: .normal,
            hitPoints: 1,
            signature: BrickSignature(color: .mint, pattern: .grid, mark: .star),
            anchored: true,
            center: ShotVector(x: 195, y: 250)
        )
        var state = stateWith(bricks: [target])
        state.ball.position = ShotVector(x: 195, y: 160)
        state.ball.velocity = ShotVector(x: 0, y: 12_000)

        let events = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)

        XCTAssertTrue(events.contains { event in
            if case .brickRemoved(id: 4, cause: .direct, points: _) = event { return true }
            return false
        })
    }

    func testAuthoritativeBallNeverEntersReservedUIBand() {
        var state = GameRules.initialReturnShotState(seed: 20_260_817)

        for _ in 0..<600 where state.phase == .playing {
            _ = GameRules.stepReturnShot(
                state: &state,
                paddleTargetX: state.ball.position.x
            )
            XCTAssertLessThanOrEqual(
                state.ball.position.y + state.ball.radius,
                GameRules.topWall + 0.001
            )
        }
    }

    func testFixedTickChecksumMatchesThirtySixtyAndOneTwentyHertzScheduling() {
        let thirty = simulatedChecksum(framesPerSecond: 30, seconds: 4)
        let sixty = simulatedChecksum(framesPerSecond: 60, seconds: 4)
        let oneTwenty = simulatedChecksum(framesPerSecond: 120, seconds: 4)

        XCTAssertEqual(thirty, sixty)
        XCTAssertEqual(sixty, oneTwenty)
    }

    func testOverdriveChecksumMatchesThirtySixtyOneTwentyAndLargeDeltaTickBatches() {
        let oneTwenty = simulatedOverdriveChecksum(ticksPerBatch: 1, totalTicks: 120)
        let sixty = simulatedOverdriveChecksum(ticksPerBatch: 2, totalTicks: 120)
        let thirty = simulatedOverdriveChecksum(ticksPerBatch: 4, totalTicks: 120)
        let largeDelta = simulatedOverdriveChecksum(ticksPerBatch: 30, totalTicks: 120)

        XCTAssertEqual(oneTwenty, sixty)
        XCTAssertEqual(sixty, thirty)
        XCTAssertEqual(thirty, largeDelta)
    }

    func testProfileDecodingClampsNegativeValuesAndRejectsFutureVersion() throws {
        let clamped = try JSONDecoder().decode(
            PlayerProfile.self,
            from: Data("{\"version\":1,\"bestScore\":-8,\"bestHeight\":-2,\"bestCombo\":-1,\"bestLink\":-4,\"totalRuns\":-3}".utf8)
        )
        XCTAssertEqual(clamped.bestScore, 0)
        XCTAssertEqual(clamped.bestHeight, 0)
        XCTAssertEqual(clamped.bestCombo, 0)
        XCTAssertEqual(clamped.bestLink, 0)
        XCTAssertEqual(clamped.totalRuns, 0)

        XCTAssertThrowsError(
            try JSONDecoder().decode(PlayerProfile.self, from: Data("{\"version\":2}".utf8))
        )
    }

    func testSnapshotAndResultExposeRecordChasingContract() {
        let snapshot = RunSnapshot()
        XCTAssertEqual(snapshot.phase, .ready)
        XCTAssertEqual(snapshot.scoreText, "0")
        XCTAssertEqual(snapshot.heightText, "0m")
        XCTAssertEqual(snapshot.link.leadingText, "LINK 준비")

        let result = RunResult(
            score: 12_500,
            height: 87,
            maxCombo: 14,
            maxLink: 5,
            powerActivations: 2,
            destroyedBrickCount: 31,
            dailySeed: 20_260_817,
            previousBestScore: 10_000,
            previousBestHeight: 70
        )
        XCTAssertEqual(result.grade, "A")
        XCTAssertTrue(result.headline.contains("87m"))
        XCTAssertTrue(result.shareText.contains("12,500"))
        XCTAssertTrue(result.shareText.contains("×14"))
        XCTAssertTrue(result.isNewBest)
        XCTAssertEqual(result.scoreDeltaFromPreviousBest, 2_500)
    }

    func testEverySegmentHasOneDeterministicCyclingNormalCarrierAndStageArmor() {
        for segment in 0..<12 {
            let expectedKind = AttackItemKind(rawValue: segment % AttackItemKind.allCases.count)
            let profile = GameRules.difficultyProfile(segment: segment)
            let expectedArmor = profile.armorLayers

            for seed in UInt64(0)..<64 {
                let first = GameRules.returnShotBricks(seed: seed, segment: segment)
                let replay = GameRules.returnShotBricks(seed: seed, segment: segment)
                let carriers = first.filter { $0.embeddedItem != nil }

                XCTAssertEqual(first, replay)
                XCTAssertEqual(carriers.count, 1)
                XCTAssertEqual(carriers.first?.embeddedItem, expectedKind)
                XCTAssertEqual(carriers.first?.role, .normal)
                XCTAssertEqual(first.filter { $0.role == .prism }.count, profile.prismCount)
                XCTAssertEqual(first.filter { $0.role == .negative }.count, profile.negativeCount)
                XCTAssertTrue(
                    first.filter { $0.role != .negative }
                        .allSatisfy { $0.maximumArmor == expectedArmor && $0.armor == expectedArmor }
                )
                XCTAssertTrue(
                    first.filter { $0.role == .negative }
                        .allSatisfy { $0.maximumArmor == 0 && $0.armor == 0 }
                )
                XCTAssertTrue(first.filter { $0.role == .prism }.allSatisfy { $0.maximumHitPoints == 3 })
            }
        }
    }

    func testClearingLevelEmitsOneLevelTransitionAndUsesEntrySpeed() {
        var state = stateWith(
            bricks: [brick(id: 1, role: .normal, hitPoints: 1, signature: nil, anchored: true)]
        )
        state.ball.velocity = .zero
        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

        let transition = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
        let profile = GameRules.difficultyProfile(segment: 1)
        XCTAssertEqual(state.segment, 1)
        XCTAssertEqual(state.ball.velocity.length, profile.entryBallSpeed, accuracy: 0.001)
        XCTAssertEqual(transition.filter { $0 == .segmentAdvanced(1) }.count, 1)
        XCTAssertEqual(transition.filter { $0 == .levelAdvanced(profile) }.count, 1)
        XCTAssertEqual(state.bricks.filter { $0.role == .prism }.count, 1)
        XCTAssertEqual(state.bricks.filter { $0.role == .negative }.count, 0)

        let nextTick = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
        XCTAssertFalse(nextTick.contains { event in
            if case .levelAdvanced = event { return true }
            return false
        })
    }

    func testArmorAbsorbsDamageBeforeCoreAndDoesNotPayCoreScore() {
        var state = stateWith(
            bricks: [brick(id: 1, role: .normal, hitPoints: 1, signature: nil, anchored: true, armor: 2)]
        )

        let first = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertEqual(state.bricks[0].armor, 1)
        XCTAssertEqual(state.bricks[0].hitPoints, 1)
        XCTAssertEqual(state.score, 0)
        XCTAssertFalse(state.bricks[0].isRemoved)
        XCTAssertTrue(first.events.contains(.armorChanged(id: 1, remainingArmor: 1)))

        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertEqual(state.bricks[0].armor, 0)
        XCTAssertEqual(state.bricks[0].hitPoints, 1)
        XCTAssertEqual(state.score, 0)

        let third = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertTrue(state.bricks[0].isRemoved)
        XCTAssertTrue(third.events.contains { event in
            if case .brickRemoved(id: 1, cause: .direct, points: _) = event { return true }
            return false
        })
    }

    func testLightningTargetsNearestPositiveOnlyWithoutRecursionAndAddsOneWaveCombo() {
        let carrier = brick(
            id: 1,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            item: .lightning,
            center: ShotVector(x: 195, y: 300)
        )
        let negative = brick(
            id: 2,
            role: .negative,
            hitPoints: Int.max,
            signature: nil,
            anchored: true,
            center: ShotVector(x: 198, y: 300)
        )
        let otherCarrier = brick(
            id: 3,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            item: .flame,
            center: ShotVector(x: 201, y: 300)
        )
        let nearest = brick(
            id: 4,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            center: ShotVector(x: 215, y: 300)
        )
        let farther = brick(
            id: 5,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            center: ShotVector(x: 255, y: 300)
        )
        var state = stateWith(bricks: [carrier, negative, otherCarrier, nearest, farther])

        let outcome = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

        XCTAssertEqual(state.attackItems.levels.lightning, 1)
        XCTAssertEqual(state.attackItems.levels.flame, 0)
        XCTAssertEqual(state.attackItems.totalCollected, 1)
        XCTAssertFalse(state.bricks[1].isRemoved)
        XCTAssertEqual(state.bricks[1].penaltyHits, 0)
        XCTAssertFalse(state.bricks[2].isRemoved)
        XCTAssertTrue(state.bricks[3].isRemoved)
        XCTAssertFalse(state.bricks[4].isRemoved)
        XCTAssertEqual(state.combo, 2)
        XCTAssertTrue(outcome.events.contains(.itemCollected(kind: .lightning, level: 1, carrierID: 1)))
        XCTAssertTrue(outcome.events.contains(.brickRemoved(id: 4, cause: .attackItem(.lightning), points: 60)))

        let directIndex = outcome.events.firstIndex { event in
            if case .brickRemoved(id: 1, cause: .direct, points: _) = event { return true }
            return false
        }
        let collectIndex = outcome.events.firstIndex(of: .itemCollected(kind: .lightning, level: 1, carrierID: 1))
        let waveIndex = outcome.events.firstIndex(of: .brickRemoved(id: 4, cause: .attackItem(.lightning), points: 60))
        XCTAssertNotNil(directIndex)
        XCTAssertNotNil(collectIndex)
        XCTAssertNotNil(waveIndex)
        XCTAssertLessThan(directIndex!, collectIndex!)
        XCTAssertLessThan(collectIndex!, waveIndex!)
    }

    func testLightningTargetCountScalesOneTwoThree() {
        for expectedLevel in 1...3 {
            var bricks = [
                brick(
                    id: 1,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    item: .lightning,
                    center: ShotVector(x: 195, y: 300)
                )
            ]
            for offset in 1...4 {
                bricks.append(
                    brick(
                        id: offset + 1,
                        role: .normal,
                        hitPoints: 1,
                        signature: nil,
                        anchored: true,
                        center: ShotVector(x: 195 + Double(offset * 20), y: 300)
                    )
                )
            }
            var state = stateWith(bricks: bricks)
            for _ in 1..<expectedLevel {
                _ = state.attackItems.levels.levelUp(.lightning)
            }

            _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

            XCTAssertEqual(state.attackItems.levels.lightning, expectedLevel)
            XCTAssertEqual(state.bricks.dropFirst().filter(\.isRemoved).count, expectedLevel)
            XCTAssertEqual(state.combo, 2)
        }
    }

    func testAttackWaveSupportCollapsePreservesLinkAndAwardsOnlyOneWaveCombo() {
        let carrier = brick(
            id: 1,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            item: .lightning,
            center: ShotVector(x: 150, y: 300)
        )
        let support = brick(
            id: 2,
            role: .support,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            center: ShotVector(x: 170, y: 300)
        )
        let dependent = brick(
            id: 3,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            supportIDs: [2],
            center: ShotVector(x: 170, y: 340)
        )
        var state = stateWith(bricks: [carrier, support, dependent])
        let existingLink = AttributeLinkState(
            previousSignature: BrickSignature(color: .blue, pattern: .grid, mark: .star),
            colorCount: 3,
            patternCount: 2,
            markCount: 1
        )
        state.link = existingLink

        let outcome = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

        XCTAssertTrue(state.bricks[1].isRemoved)
        XCTAssertTrue(state.bricks[2].isRemoved)
        XCTAssertEqual(state.combo, 2)
        XCTAssertEqual(state.link, existingLink)
        XCTAssertTrue(
            outcome.events.contains(
                .brickRemoved(id: 3, cause: .unsupportedFall, points: 45)
            )
        )
    }

    func testFlameUsesBoundedRadiusAndTargetCountAtEachLevel() {
        for expectedLevel in 1...3 {
            var bricks = [
                brick(
                    id: 1,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    item: .flame,
                    center: ShotVector(x: 195, y: 300)
                )
            ]
            for offset in 1...8 {
                bricks.append(
                    brick(
                        id: offset + 1,
                        role: .normal,
                        hitPoints: 1,
                        signature: nil,
                        anchored: true,
                        center: ShotVector(x: 195 + Double(offset * 10), y: 300)
                    )
                )
            }
            var state = stateWith(bricks: bricks)
            for _ in 1..<expectedLevel {
                _ = state.attackItems.levels.levelUp(.flame)
            }

            _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

            let expectedRemoved = [3, 5, 7][expectedLevel - 1]
            XCTAssertEqual(state.attackItems.levels.flame, expectedLevel)
            XCTAssertEqual(state.bricks.dropFirst().filter(\.isRemoved).count, expectedRemoved)
            XCTAssertEqual(state.combo, 2)
        }
    }

    func testWindDamagesOnlyBoundedPositiveTargetsAboveCarrierAndUsesArmorFirst() {
        let carrier = brick(
            id: 1,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            item: .wind,
            center: ShotVector(x: 195, y: 300)
        )
        var targets: [ShotBrick] = []
        for offset in 1...5 {
            targets.append(
                brick(
                    id: offset + 1,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    armor: offset == 1 ? 1 : 0,
                    center: ShotVector(x: 195, y: 300 + Double(offset * 10))
                )
            )
        }
        targets.append(
            brick(
                id: 9,
                role: .normal,
                hitPoints: 1,
                signature: nil,
                anchored: true,
                center: ShotVector(x: 195, y: 290)
            )
        )
        var state = stateWith(bricks: [carrier] + targets)
        _ = state.attackItems.levels.levelUp(.wind)
        _ = state.attackItems.levels.levelUp(.wind)

        let outcome = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

        XCTAssertEqual(state.attackItems.levels.wind, 3)
        XCTAssertEqual(state.bricks[1].armor, 0)
        XCTAssertFalse(state.bricks[1].isRemoved)
        XCTAssertTrue(state.bricks[2].isRemoved)
        XCTAssertTrue(state.bricks[3].isRemoved)
        XCTAssertTrue(state.bricks[4].isRemoved)
        XCTAssertFalse(state.bricks[5].isRemoved)
        XCTAssertFalse(state.bricks[6].isRemoved)
        XCTAssertTrue(outcome.events.contains(.armorChanged(id: 2, remainingArmor: 0)))
    }

    func testWindTargetCountScalesTwoThreeFour() {
        for expectedLevel in 1...3 {
            var bricks = [
                brick(
                    id: 1,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    item: .wind,
                    center: ShotVector(x: 195, y: 300)
                )
            ]
            for offset in 1...5 {
                bricks.append(
                    brick(
                        id: offset + 1,
                        role: .normal,
                        hitPoints: 1,
                        signature: nil,
                        anchored: true,
                        center: ShotVector(x: 195, y: 300 + Double(offset * 10))
                    )
                )
            }
            var state = stateWith(bricks: bricks)
            for _ in 1..<expectedLevel {
                _ = state.attackItems.levels.levelUp(.wind)
            }

            _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

            XCTAssertEqual(state.attackItems.levels.wind, expectedLevel)
            XCTAssertEqual(state.bricks.dropFirst().filter(\.isRemoved).count, expectedLevel + 1)
            XCTAssertEqual(state.combo, 2)
        }
    }

    func testPerKindLevelCapsAtThreeAndItemOnlyRemovalNeverCollectsAnotherCarrier() {
        var carriers: [ShotBrick] = []
        for id in 1...4 {
            carriers.append(
                brick(
                    id: id,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    item: .lightning,
                    center: ShotVector(x: 150 + Double(id * 10), y: 300)
                )
            )
        }
        var state = stateWith(bricks: carriers)

        for id in 1...4 {
            _ = GameRules.resolveDirectBrickContact(state: &state, brickID: id)
        }

        XCTAssertEqual(state.attackItems.levels.lightning, 3)
        XCTAssertEqual(state.attackItems.totalCollected, 4)
        XCTAssertEqual(state.attackItems.levels.flame, 0)
        XCTAssertEqual(state.attackItems.overdriveCount, 1)
        XCTAssertEqual(state.attackItems.pendingEchoes.count, 1)
    }

    func testAttackUpgradeRanksOneToThreeThenUsesBoundedOverdrive() {
        for kind in AttackItemKind.allCases {
            var items = AttackItemState()
            XCTAssertEqual(
                GameRules.registerAttackCollection(state: &items, kind: kind),
                .rankedUp(previous: 0, current: 1)
            )
            XCTAssertEqual(
                GameRules.registerAttackCollection(state: &items, kind: kind),
                .rankedUp(previous: 1, current: 2)
            )
            XCTAssertEqual(
                GameRules.registerAttackCollection(state: &items, kind: kind),
                .rankedUp(previous: 2, current: 3)
            )
            XCTAssertEqual(
                GameRules.registerAttackCollection(state: &items, kind: kind),
                .overdrive(rank: 3, activation: 1)
            )
            XCTAssertEqual(items.levels.level(for: kind), 3)
            XCTAssertEqual(items.totalCollected, 4)
            XCTAssertEqual(items.overdriveCount, 1)
        }
    }

    func testMaxOverdriveEchoesSameStableTargetsAtExactlyFifteenTicksWithoutRetarget() {
        let expectedTargetCounts: [AttackItemKind: Int] = [
            .lightning: 3,
            .flame: 7,
            .wind: 4
        ]

        for kind in [AttackItemKind.lightning, .flame, .wind] {
            let center = ShotVector(x: 195, y: 300)
            let targetCount = try! XCTUnwrap(expectedTargetCounts[kind])
            var bricks = [
                brick(
                    id: 1,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    item: kind,
                    center: center
                )
            ]
            for offset in 0...targetCount {
                let targetCenter: ShotVector
                if kind == .wind {
                    targetCenter = ShotVector(x: center.x, y: center.y + Double(offset + 1) * 10)
                } else {
                    targetCenter = ShotVector(x: center.x + Double(offset + 1) * 10, y: center.y)
                }
                bricks.append(
                    brick(
                        id: 10 + offset,
                        role: .normal,
                        hitPoints: 1,
                        signature: nil,
                        anchored: true,
                        armor: 1,
                        center: targetCenter
                    )
                )
            }

            var state = stateWith(bricks: bricks)
            state.ball.velocity = .zero
            for _ in 0..<AttackItemLevels.maximumRank {
                _ = state.attackItems.levels.levelUp(kind)
            }

            let direct = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
            let expectedIDs = Array(10..<(10 + targetCount))
            let extraID = 10 + targetCount
            XCTAssertEqual(state.attackItems.levels.level(for: kind), 3)
            XCTAssertEqual(state.attackItems.pendingEchoes.first?.targetIDs, expectedIDs)
            XCTAssertEqual(state.attackItems.pendingEchoes.first?.triggerTick, 15)
            XCTAssertEqual(state.combo, 1)
            XCTAssertTrue(direct.events.contains { event in
                if case .itemOverdriveScheduled(let eventKind, 3, 1, 1, 15) = event {
                    return eventKind == kind
                }
                return false
            })
            for id in expectedIDs {
                let target = try! XCTUnwrap(state.bricks.first { $0.id == id })
                XCTAssertEqual(target.armor, 0)
                XCTAssertEqual(target.hitPoints, 1)
                XCTAssertFalse(target.isRemoved)
            }
            XCTAssertEqual(state.bricks.first { $0.id == extraID }?.armor, 1)

            if kind == .lightning,
               let removedBeforeEcho = state.bricks.firstIndex(where: { $0.id == expectedIDs[0] }) {
                state.bricks[removedBeforeEcho].isRemoved = true
            }

            for _ in 0..<14 {
                let events = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
                XCTAssertFalse(events.contains { event in
                    if case .itemOverdriveActivated = event { return true }
                    return false
                })
            }
            XCTAssertEqual(state.attackItems.pendingEchoes.count, 1)

            let echo = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
            XCTAssertEqual(state.tick, 15)
            XCTAssertEqual(echo.filter { event in
                if case .itemOverdriveActivated(let eventKind, 3, 1, 1) = event {
                    return eventKind == kind
                }
                return false
            }.count, 1)
            XCTAssertTrue(state.attackItems.pendingEchoes.isEmpty)
            XCTAssertEqual(state.combo, 2)
            XCTAssertEqual(state.bricks.first { $0.id == extraID }?.armor, 1)
            XCTAssertFalse(state.bricks.first { $0.id == extraID }?.isRemoved ?? true)

            let afterEcho = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
            XCTAssertFalse(afterEcho.contains { event in
                if case .itemOverdriveActivated = event { return true }
                return false
            })
        }
    }

    func testPierceMaxOverdriveAddsThreeThenThreeAtTickFifteenAndCapsAtSix() {
        for initialCharges in [0, 6] {
            let carrier = brick(
                id: 1,
                role: .normal,
                hitPoints: 1,
                signature: nil,
                anchored: true,
                item: .pierce
            )
            let survivor = brick(id: 2, role: .normal, hitPoints: 1, signature: nil, anchored: true)
            var state = stateWith(bricks: [carrier, survivor])
            state.ball.velocity = .zero
            state.attackItems.pierceCharges = initialCharges
            for _ in 0..<AttackItemLevels.maximumRank {
                _ = state.attackItems.levels.levelUp(.pierce)
            }

            _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
            XCTAssertEqual(state.attackItems.pierceCharges, initialCharges == 0 ? 3 : 6)
            XCTAssertEqual(state.attackItems.pendingEchoes.first?.triggerTick, 15)

            for _ in 0..<14 {
                _ = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
            }
            XCTAssertEqual(state.attackItems.pierceCharges, initialCharges == 0 ? 3 : 6)

            let echo = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
            XCTAssertEqual(state.attackItems.pierceCharges, 6)
            XCTAssertEqual(echo.filter { event in
                if case .itemOverdriveActivated(.pierce, 3, 1, 1) = event { return true }
                return false
            }.count, 1)
        }
    }

    func testPierceAddsLevelChargesConsumesOnPositiveAndNeverOnNegative() {
        let carrier = brick(
            id: 1,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            item: .pierce
        )
        let positive = brick(id: 2, role: .normal, hitPoints: 1, signature: nil, anchored: true)
        let negative = brick(id: 3, role: .negative, hitPoints: Int.max, signature: nil, anchored: true)
        var state = stateWith(bricks: [carrier, positive, negative])

        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)
        XCTAssertEqual(state.attackItems.levels.pierce, 1)
        XCTAssertEqual(state.attackItems.pierceCharges, 1)

        let pierced = GameRules.resolveDirectBrickContact(state: &state, brickID: 2)
        XCTAssertFalse(pierced.shouldReflect)
        XCTAssertEqual(state.attackItems.pierceCharges, 0)
        XCTAssertTrue(pierced.events.contains(.pierceChargesChanged(0)))

        state.attackItems.pierceCharges = 1
        state.score = 500
        let negativeHit = GameRules.resolveDirectBrickContact(state: &state, brickID: 3)
        XCTAssertTrue(negativeHit.shouldReflect)
        XCTAssertEqual(state.attackItems.pierceCharges, 1)
        XCTAssertFalse(state.bricks[2].isRemoved)
    }

    func testPierceChargeAwardsScaleOneTwoThreeAtEachLevel() {
        for expectedLevel in 1...3 {
            let carrier = brick(
                id: 1,
                role: .normal,
                hitPoints: 1,
                signature: nil,
                anchored: true,
                item: .pierce
            )
            var state = stateWith(bricks: [carrier])
            for _ in 1..<expectedLevel {
                _ = state.attackItems.levels.levelUp(.pierce)
            }

            let outcome = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

            XCTAssertEqual(state.attackItems.levels.pierce, expectedLevel)
            XCTAssertEqual(state.attackItems.pierceCharges, expectedLevel)
            XCTAssertTrue(outcome.events.contains(.pierceChargesChanged(expectedLevel)))
        }
    }

    func testShockwaveAndUnsupportedFallDoNotCollectCarrierItems() {
        var shockwaveState = stateWith(
            bricks: [
                brick(
                    id: 1,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    center: ShotVector(x: 195, y: 300)
                ),
                brick(
                    id: 2,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    item: .flame,
                    center: ShotVector(x: 215, y: 300)
                )
            ]
        )
        shockwaveState.powerTicks = 100
        let shockwave = GameRules.resolveDirectBrickContact(state: &shockwaveState, brickID: 1)
        XCTAssertTrue(shockwaveState.bricks[1].isRemoved)
        XCTAssertEqual(shockwaveState.attackItems.totalCollected, 0)
        XCTAssertFalse(shockwave.events.contains { event in
            if case .itemCollected = event { return true }
            return false
        })

        let removedSupport = brick(
            id: 10,
            role: .support,
            hitPoints: 0,
            signature: nil,
            anchored: true,
            removed: true
        )
        let fallingCarrier = brick(
            id: 11,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            supportIDs: [10],
            item: .wind
        )
        var fallState = stateWith(bricks: [removedSupport, fallingCarrier])
        let fallEvents = GameRules.collapseUnsupported(state: &fallState)
        XCTAssertTrue(fallState.bricks[1].isRemoved)
        XCTAssertEqual(fallState.attackItems.totalCollected, 0)
        XCTAssertFalse(fallEvents.contains { event in
            if case .itemCollected = event { return true }
            return false
        })
    }

    func testChecksumCoversArmorCarrierLevelsPierceAndPendingOverdrive() {
        let baseline = GameRules.initialReturnShotState(seed: 99)
        let baselineChecksum = GameRules.checksum(baseline)

        var armorChanged = baseline
        armorChanged.bricks[0].armor += 1
        XCTAssertNotEqual(GameRules.checksum(armorChanged), baselineChecksum)

        var carrierChanged = baseline
        carrierChanged.bricks[0].embeddedItem = .flame
        XCTAssertNotEqual(GameRules.checksum(carrierChanged), baselineChecksum)

        var levelChanged = baseline
        _ = levelChanged.attackItems.levels.levelUp(.wind)
        XCTAssertNotEqual(GameRules.checksum(levelChanged), baselineChecksum)

        var chargeChanged = baseline
        chargeChanged.attackItems.pierceCharges = 2
        XCTAssertNotEqual(GameRules.checksum(chargeChanged), baselineChecksum)

        var overdriveChanged = baseline
        overdriveChanged.attackItems.overdriveCount = 1
        XCTAssertNotEqual(GameRules.checksum(overdriveChanged), baselineChecksum)

        var pendingChanged = baseline
        pendingChanged.attackItems.pendingEchoes = [
            PendingAttackEcho(
                sequence: 1,
                triggerTick: 15,
                segment: 0,
                kind: .flame,
                carrierID: 7,
                targetIDs: [8, 9],
                canAwardCombo: true
            )
        ]
        XCTAssertNotEqual(GameRules.checksum(pendingChanged), baselineChecksum)
    }

#if !SWIFT_PACKAGE
    func testNativeDesignAdapterExposesOnlyApprovedAttackSet() {
        let tokens = BrickBreakerDesignAdapter.approvedElements

        XCTAssertEqual(tokens.count, 4)
        XCTAssertEqual(Set(tokens.map(\.kind)), Set(AttackItemKind.allCases))
        XCTAssertEqual(Set(tokens.map(\.id)).count, tokens.count)
        XCTAssertTrue(BrickBreakerDesignAdapter.element(for: .wind).isSourceExtension)
        XCTAssertFalse(BrickBreakerDesignAdapter.element(for: .lightning).isSourceExtension)
        XCTAssertEqual(BrickBreakerDesignAdapter.sourceVersion, "1.0.0")
    }
#endif

    private func simulatedChecksum(framesPerSecond: Int, seconds: Int) -> UInt64 {
        var state = GameRules.initialReturnShotState(seed: 424_242)
        let ticksPerFrame = GameRules.tickRate / framesPerSecond
        for _ in 0..<(framesPerSecond * seconds) {
            for _ in 0..<ticksPerFrame where state.phase == .playing {
                let target = GameRules.fieldWidth / 2
                    + sin(Double(state.tick) * 0.037) * 112
                _ = GameRules.stepReturnShot(state: &state, paddleTargetX: target)
            }
        }
        return GameRules.checksum(state)
    }

    private func simulatedOverdriveChecksum(ticksPerBatch: Int, totalTicks: Int) -> UInt64 {
        let carrier = brick(
            id: 1,
            role: .normal,
            hitPoints: 1,
            signature: nil,
            anchored: true,
            item: .lightning,
            center: ShotVector(x: 195, y: 300)
        )
        var targets: [ShotBrick] = []
        for offset in 0..<4 {
            targets.append(
                brick(
                    id: 10 + offset,
                    role: .normal,
                    hitPoints: 1,
                    signature: nil,
                    anchored: true,
                    armor: 1,
                    center: ShotVector(x: 205 + Double(offset) * 10, y: 300)
                )
            )
        }
        var state = stateWith(bricks: [carrier] + targets)
        state.ball.velocity = .zero
        for _ in 0..<AttackItemLevels.maximumRank {
            _ = state.attackItems.levels.levelUp(.lightning)
        }
        _ = GameRules.resolveDirectBrickContact(state: &state, brickID: 1)

        var completedTicks = 0
        while completedTicks < totalTicks {
            let batch = min(ticksPerBatch, totalTicks - completedTicks)
            for _ in 0..<batch {
                _ = GameRules.stepReturnShot(state: &state, paddleTargetX: 195)
            }
            completedTicks += batch
        }
        return GameRules.checksum(state)
    }

    private func stateWith(bricks: [ShotBrick]) -> ReturnShotState {
        ReturnShotState(
            seed: 7,
            ball: ShotBall(
                position: ShotVector(x: 195, y: 190),
                velocity: ShotVector(x: 0, y: 370),
                radius: 10
            ),
            paddleX: 195,
            paddleTargetX: 195,
            bricks: bricks
        )
    }

    private func brick(
        id: Int,
        role: ShotBrickRole,
        hitPoints: Int,
        signature: BrickSignature?,
        supportIDs: [Int] = [],
        anchored: Bool = false,
        removed: Bool = false,
        item: AttackItemKind? = nil,
        armor: Int = 0,
        center: ShotVector = ShotVector(x: 195, y: 300)
    ) -> ShotBrick {
        let maximumHitPoints: Int = switch role {
        case .normal: 1
        case .support: 2
        case .prism: 3
        case .negative: Int.max
        }
        return ShotBrick(
            id: id,
            rect: ShotRect(center: center, width: 48, height: 38),
            signature: signature,
            role: role,
            maximumHitPoints: maximumHitPoints,
            hitPoints: hitPoints,
            supportIDs: supportIDs,
            anchored: anchored,
            embeddedItem: item,
            maximumArmor: armor,
            armor: armor,
            isRemoved: removed
        )
    }
}
