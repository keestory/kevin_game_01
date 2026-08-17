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
        XCTAssertEqual(first.bricks.filter { $0.role == .prism }.count, 2)
        XCTAssertEqual(first.bricks.filter { $0.role == .negative }.count, 2)
        XCTAssertTrue(first.bricks.filter { $0.anchored }.allSatisfy { $0.role == .support })
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
            let expectedArmor = GameRules.stageArmor(segment: segment)

            for seed in UInt64(0)..<64 {
                let first = GameRules.returnShotBricks(seed: seed, segment: segment)
                let replay = GameRules.returnShotBricks(seed: seed, segment: segment)
                let carriers = first.filter { $0.embeddedItem != nil }

                XCTAssertEqual(first, replay)
                XCTAssertEqual(carriers.count, 1)
                XCTAssertEqual(carriers.first?.embeddedItem, expectedKind)
                XCTAssertEqual(carriers.first?.role, .normal)
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

    func testChecksumCoversArmorCarrierLevelsAndPierceCharges() {
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
    }

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
