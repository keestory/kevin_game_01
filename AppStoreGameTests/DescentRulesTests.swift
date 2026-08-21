import XCTest
#if SWIFT_PACKAGE
@testable import GameCore
#else
@testable import AppStoreGame
#endif

@MainActor
final class DescentRulesTests: XCTestCase {
    func testInitialStateCoordinatesObjectSpecsAndDifficultyContract() {
        let state = GameRules.initialDescentState(seed: 20_260_819)

        XCTAssertEqual(state.shipKind, .interceptor)
        XCTAssertEqual(state.tick, 0)
        XCTAssertEqual(state.frenzy, DescentFrenzyState())
        XCTAssertEqual(state.player.reactorHP, 3)
        XCTAssertEqual(state.phase, .playing)
        XCTAssertEqual(state.choiceArena, DescentChoiceArenaState())
        XCTAssertEqual(state.player.xQ, GameRules.descentQ(fromPoints: 195))
        XCTAssertEqual(GameRules.descentCoordinateScale, 6_000)
        XCTAssertEqual(GameRules.descentTickRate, 120)
        XCTAssertEqual(GameRules.descentTickDuration, 1.0 / 120.0, accuracy: 0.000_001)
        XCTAssertEqual(GameRules.descentAutoFireIntervalTicks, 22)
        XCTAssertEqual(GameRules.descentLaneXPoints, [39, 117, 195, 273, 351])
        XCTAssertEqual(
            GameRules.descentPoints(fromQ: GameRules.descentQ(fromPoints: 123.456)),
            123.456,
            accuracy: 1.0 / Double(GameRules.descentCoordinateScale)
        )

        let objectSpecs: [(DescentObjectKind, Int, Int, Int)] = [
            (.normal, 1, 100, 100),
            (.armored, 3, 78, 300),
            (.spike, 2, 122, 220),
            (.drone, 2, 108, 250),
            (.core, 2, 90, 250),
            (.brute, 8, 70, 700)
        ]
        for (kind, hitPoints, speedPercent, score) in objectSpecs {
            XCTAssertEqual(kind.hitPoints, hitPoints)
            XCTAssertEqual(kind.fallSpeedPercent, speedPercent)
            XCTAssertEqual(kind.baseScore, score)
        }

        let expected = [
            (tick: 0, tier: 0, speed: 72, interval: 180, pattern: DescentSpawnPattern.singleRain),
            (tick: 1_800, tier: 1, speed: 84, interval: 144, pattern: .splitPair),
            (tick: 3_600, tier: 2, speed: 98, interval: 114, pattern: .stairSequence),
            (tick: 5_400, tier: 3, speed: 112, interval: 98, pattern: .clusterGate)
        ]
        for value in expected {
            let profile = GameRules.descentDifficulty(atTick: value.tick)
            XCTAssertEqual(profile.tier, value.tier)
            XCTAssertEqual(profile.baseFallSpeed, value.speed)
            XCTAssertEqual(profile.spawnIntervalTicks, value.interval)
            XCTAssertEqual(profile.pattern, value.pattern)
            XCTAssertEqual(profile.objectCap, 36)
            XCTAssertEqual(profile.projectileCap, 24)
            XCTAssertEqual(profile.dropCap, 8)
        }
    }

    func testShipLoadoutsMapOneToOneAndPreserveBaselineWeaponBalance() {
        let expected: [(DescentShipKind, DescentMissileKind, Int, Int, Int)] = [
            (.interceptor, .pulse, 22, 1, 1),
            (.striker, .lance, 44, 1, 2),
            (.guardian, .salvo, 66, 3, 1)
        ]

        let loadouts = expected.map { shipKind, missileKind, interval, count, damage in
            let loadout = GameRules.descentLoadout(for: shipKind)
            XCTAssertEqual(loadout.shipKind, shipKind)
            XCTAssertEqual(loadout.missileKind, missileKind)
            XCTAssertEqual(loadout.fireIntervalTicks, interval)
            XCTAssertEqual(loadout.projectilesPerVolley, count)
            XCTAssertEqual(loadout.projectileSpeed, 780)
            XCTAssertEqual(loadout.damage, damage)
            XCTAssertEqual(132 / interval * count * damage, 6)
            return loadout
        }

        XCTAssertEqual(Set(loadouts.map(\.missileKind)).count, DescentShipKind.allCases.count)
        XCTAssertEqual(Set(DescentShipKind.allCases), Set(expected.map(\.0)))
        XCTAssertEqual(Set(DescentMissileKind.allCases), Set(expected.map(\.1)))
        XCTAssertEqual(GameRules.descentVolleyLanes(centerLane: 0, shipKind: .guardian), [0, 1, 2])
        XCTAssertEqual(GameRules.descentVolleyLanes(centerLane: 2, shipKind: .guardian), [1, 2, 3])
        XCTAssertEqual(GameRules.descentVolleyLanes(centerLane: 4, shipKind: .guardian), [2, 3, 4])
    }

    func testEachShipFiresOnlyItsMissileAtSameCadenceAndHonorsSharedCap() {
        for shipKind in DescentShipKind.allCases {
            let loadout = GameRules.descentLoadout(for: shipKind)
            var state = quietState(seed: UInt64(100 + shipKind.rawValue), shipKind: shipKind)
            var fired: [(tick: Int, projectile: DescentProjectile)] = []

            for _ in 0..<132 {
                let events = GameRules.stepDescent(
                    state: &state,
                    input: DescentInput(targetXPoints: 195)
                )
                for event in events {
                    if case .projectileFired(let projectile) = event {
                        fired.append((state.tick, projectile))
                    }
                }
            }

            let expectedVolleyTicks = stride(
                from: loadout.fireIntervalTicks,
                through: 132,
                by: loadout.fireIntervalTicks
            ).flatMap { tick in Array(repeating: tick, count: loadout.projectilesPerVolley) }
            XCTAssertEqual(fired.map(\.tick), expectedVolleyTicks)
            XCTAssertTrue(fired.allSatisfy { $0.projectile.missileKind == loadout.missileKind })
            XCTAssertTrue(fired.allSatisfy { $0.projectile.velocityQPerTick == 39_000 })
            XCTAssertTrue(fired.allSatisfy { $0.projectile.damage == loadout.damage })
            XCTAssertEqual(fired.reduce(0) { $0 + $1.projectile.damage }, 6)

            if shipKind == .guardian {
                for tick in [66, 132] {
                    XCTAssertEqual(fired.filter { $0.tick == tick }.map { $0.projectile.lane }, [1, 2, 3])
                }
            } else {
                XCTAssertTrue(fired.allSatisfy { $0.projectile.lane == 2 })
            }

            state.tick = loadout.fireIntervalTicks - 1
            state.projectiles = blockingProjectiles(
                count: GameRules.descentMaximumProjectiles - loadout.projectilesPerVolley + 1,
                missileKind: loadout.missileKind
            )
            let cappedEvents = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            XCTAssertFalse(cappedEvents.contains { if case .projectileFired = $0 { true } else { false } })
            XCTAssertEqual(
                state.projectiles.count,
                GameRules.descentMaximumProjectiles - loadout.projectilesPerVolley + 1
            )
        }

        var exactGuardianCap = quietState(seed: 999, shipKind: .guardian)
        exactGuardianCap.tick = 65
        exactGuardianCap.projectiles = blockingProjectiles(count: 21, missileKind: .salvo)
        exactGuardianCap.nextProjectileID = 22
        let exactEvents = GameRules.stepDescent(
            state: &exactGuardianCap,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(exactEvents.filter { if case .projectileFired = $0 { true } else { false } }.count, 3)
        XCTAssertEqual(exactGuardianCap.projectiles.count, 24)
    }

    func testShipMissileIdentitySurvivesPierceAndOtherSkillActivation() {
        for shipKind in DescentShipKind.allCases {
            var state = quietState(seed: UInt64(200 + shipKind.rawValue), shipKind: shipKind)
            let missileKind = GameRules.descentLoadout(for: shipKind).missileKind

            for kind in DescentSkillKind.allCases {
                _ = GameRules.acquireDescentEffect(state: &state, kind: kind)
            }
            let loadout = GameRules.descentLoadout(for: shipKind)
            for _ in 0..<loadout.fireIntervalTicks {
                _ = GameRules.stepDescent(
                    state: &state,
                    input: DescentInput(targetXPoints: 195)
                )
            }

            XCTAssertEqual(state.shipKind, shipKind)
            XCTAssertEqual(state.projectiles.map(\.missileKind), Array(repeating: missileKind, count: loadout.projectilesPerVolley))
            XCTAssertEqual(state.projectiles.first { $0.lane == 2 }?.remainingHits, 3)
            XCTAssertTrue(state.projectiles.filter { $0.lane != 2 }.allSatisfy { $0.remainingHits == 1 })
            XCTAssertEqual(state.projectiles.first?.effectSnapshot.levels.pierce, 1)
            XCTAssertEqual(state.projectiles.first?.effectSnapshot.loadoutVersion, 5)
            XCTAssertLessThanOrEqual(state.projectiles.count, GameRules.descentMaximumProjectiles)
        }
    }

    func testTenThousandSeedSpawnPlansAreDeterministicBoundedAndReachable() {
        var observedSkills = Set<DescentSkillKind>()

        for seed in UInt64(0)..<10_000 {
            let plan = GameRules.descentSpawnPlan(seed: seed)
            let replay = GameRules.descentSpawnPlan(seed: seed)
            let carriers = plan.filter { $0.dropKind != nil }

            XCTAssertEqual(plan, replay)
            XCTAssertEqual(Set(plan.map(\.objectID)).count, plan.count)
            XCTAssertEqual(carriers.map(\.tick), [780, 2_520, 4_380])
            XCTAssertEqual(carriers.map(\.kind), [.core, .core, .core])
            XCTAssertEqual(Set(carriers.compactMap(\.dropKind)).count, 3)
            XCTAssertTrue(plan.allSatisfy { (0..<5).contains($0.lane) })
            XCTAssertTrue(plan.filter { $0.dropKind == nil }.allSatisfy { $0.kind != .core })
            XCTAssertLessThanOrEqual(plannedPeakObjectCount(plan), 36)

            for entry in plan {
                let profile = GameRules.descentDifficulty(atTick: entry.tick)
                let fallSpeed = Double(profile.baseFallSpeed)
                    * Double(entry.kind.fallSpeedPercent) / 100.0
                let timeToDanger = (GameRules.descentSpawnY - GameRules.descentDangerY)
                    / fallSpeed
                XCTAssertGreaterThanOrEqual(timeToDanger, 3.5)
            }
            observedSkills.formUnion(carriers.compactMap(\.dropKind))
        }

        XCTAssertEqual(observedSkills, Set(DescentSkillKind.allCases))
    }

    func testInputIsOnePointQuantizedClampedAndPlayerSpeedBounded() {
        XCTAssertEqual(DescentInput(targetX: 120.49).targetXPoints, 120)
        XCTAssertEqual(DescentInput(targetX: 120.51).targetXPoints, 121)

        var state = quietState(seed: 1)
        _ = GameRules.stepDescent(state: &state, input: DescentInput(targetX: -900))

        XCTAssertEqual(state.player.targetXQ, GameRules.descentQ(fromPoints: 39))
        XCTAssertEqual(
            GameRules.descentPoints(fromQ: state.player.xQ),
            195 - 900.0 / 120.0,
            accuracy: 0.000_001
        )

        for _ in 0..<100 {
            _ = GameRules.stepDescent(state: &state, input: DescentInput(targetX: 999))
        }
        XCTAssertEqual(state.player.targetXQ, GameRules.descentQ(fromPoints: 351))
        XCTAssertLessThanOrEqual(state.player.xQ, GameRules.descentQ(fromPoints: 351))
    }

    func testAutoFireUsesTwentyTwoTicksAndHonorsProjectileCap() {
        var state = quietState(seed: 2)
        var firedTicks: [Int] = []
        for _ in 0..<44 {
            let events = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            if events.contains(where: { if case .projectileFired = $0 { true } else { false } }) {
                firedTicks.append(state.tick)
            }
        }
        XCTAssertEqual(firedTicks, [22, 44])
        XCTAssertEqual(state.projectiles.count, 2)
        XCTAssertEqual(state.projectiles.map(\.velocityQPerTick), [39_000, 39_000])

        var capped = quietState(seed: 3)
        capped.tick = 21
        capped.projectiles = blockingProjectiles(count: 24)
        capped.nextProjectileID = 25
        let events = GameRules.stepDescent(
            state: &capped,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertFalse(events.contains { if case .projectileFired = $0 { true } else { false } })
        XCTAssertEqual(capped.projectiles.count, 24)
    }

    func testSweptMultiHitDestroysScoresAndDropsOnceBeforeDanger() {
        var state = quietState(seed: 4)
        state.player.reactorHP = 3
        state.objects = [
            object(
                id: 10,
                kind: .core,
                lane: 2,
                y: 128.4,
                hitPoints: 2,
                fallPerTick: 1,
                dropKind: .fire
            )
        ]
        state.projectiles = [
            projectile(id: 1, lane: 2, y: 126.0),
            projectile(id: 2, lane: 2, y: 125.0)
        ]
        state.nextProjectileID = 3

        let events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertTrue(state.objects.isEmpty)
        XCTAssertEqual(state.player.reactorHP, 3)
        XCTAssertEqual(state.score, 400)
        XCTAssertEqual(state.combo, 1)
        XCTAssertEqual(events.compactMap(destroyedObjectID).filter { $0 == 10 }.count, 1)
        XCTAssertEqual(events.compactMap(spawnedDrop).count, 1)
        XCTAssertFalse(events.contains { if case .objectBreached = $0 { true } else { false } })
        XCTAssertFalse(events.contains { if case .dropCollected = $0 { true } else { false } })
    }

    func testNewDropCanOnlyBeCollectedFromFollowingTick() {
        var state = quietState(seed: 5)
        state.drops = [
            DescentDrop(
                id: 1,
                sourceObjectID: 50,
                kind: .electric,
                lane: 2,
                yQ: GameRules.descentQ(fromPoints: GameRules.descentPlayerY),
                spawnedAtTick: 1
            )
        ]
        state.nextDropID = 2

        let creationTick = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.tick, 1)
        XCTAssertEqual(state.drops.count, 1)
        XCTAssertFalse(creationTick.contains { if case .dropCollected = $0 { true } else { false } })

        let followingTick = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertTrue(state.drops.isEmpty)
        XCTAssertEqual(state.skills.levels.electric, 1)
        XCTAssertTrue(followingTick.contains { event in
            if case .dropCollected(
                id: let id,
                kind: let kind,
                level: let level,
                display: let display,
                loadoutVersion: let version
            ) = event {
                return id == 1 && kind == .electric && level == 1
                    && display == .plusOne && version == 1
            }
            return false
        })
    }

    func testPickupOnlyUpdatesPersistentLoadoutAndDisplaysCurrentLevel() {
        var state = quietState(seed: 5_001)
        state.objects = [
            object(id: 90, kind: .armored, lane: 2, y: 260, hitPoints: 10)
        ]
        let expected: [(DescentEffectLevelDisplay, Int)] = [
            (.plusOne, 1), (.plusTwo, 2), (.plusThree, 3), (.maximum, 3)
        ]

        for (index, expectation) in expected.enumerated() {
            state.drops = [
                DescentDrop(
                    id: index + 1,
                    sourceObjectID: 500 + index,
                    kind: .fire,
                    lane: 2,
                    yQ: GameRules.descentQ(fromPoints: GameRules.descentPlayerY),
                    spawnedAtTick: state.tick - 1
                )
            ]
            let events = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )

            XCTAssertEqual(state.objects.first?.hitPoints, 10)
            XCTAssertEqual(state.score, 0)
            XCTAssertEqual(state.skills.levels.fire, expectation.1)
            XCTAssertEqual(state.skills.loadoutVersion, index + 1)
            XCTAssertEqual(state.skills.latestEffect, .fire)
            XCTAssertFalse(events.contains { if case .objectDamaged = $0 { true } else { false } })
            XCTAssertFalse(events.contains { if case .skillActivated = $0 { true } else { false } })
            XCTAssertTrue(events.contains { event in
                if case .dropCollected(
                    id: index + 1,
                    kind: .fire,
                    level: expectation.1,
                    display: expectation.0,
                    loadoutVersion: index + 1
                ) = event { return true }
                return false
            })
        }
    }

    func testVolleySnapshotsAreImmutableAndSharedOnlyByNewProjectiles() throws {
        var state = quietState(seed: 5_002)
        state.tick = 21
        _ = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        let oldProjectile = try XCTUnwrap(state.projectiles.first)
        XCTAssertEqual(oldProjectile.effectSnapshot.levels, .init())
        XCTAssertEqual(oldProjectile.effectSnapshot.loadoutVersion, 0)

        _ = GameRules.acquireDescentEffect(state: &state, kind: .fire)
        for _ in 0..<22 {
            _ = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
        }
        XCTAssertEqual(
            state.projectiles.first { $0.id == oldProjectile.id }?.effectSnapshot,
            oldProjectile.effectSnapshot
        )
        let newProjectile = try XCTUnwrap(state.projectiles.max(by: { $0.id < $1.id }))
        XCTAssertEqual(newProjectile.effectSnapshot.levels.fire, 1)
        XCTAssertEqual(newProjectile.effectSnapshot.loadoutVersion, 1)
        XCTAssertEqual(newProjectile.effectSnapshot.dominantEffect, .fire)
        XCTAssertNotEqual(newProjectile.effectSnapshot.shotEventID, oldProjectile.effectSnapshot.shotEventID)

        var guardian = quietState(seed: 5_003, shipKind: .guardian)
        for kind in DescentSkillKind.allCases {
            _ = GameRules.acquireDescentEffect(state: &guardian, kind: kind)
        }
        guardian.tick = 65
        _ = GameRules.stepDescent(
            state: &guardian,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(guardian.projectiles.count, 3)
        XCTAssertEqual(Set(guardian.projectiles.map(\.effectSnapshot.shotEventID)).count, 1)
        XCTAssertTrue(guardian.projectiles.allSatisfy { $0.effectSnapshot.loadoutVersion == 5 })
        XCTAssertEqual(guardian.projectiles.first { $0.lane == 2 }?.remainingHits, 3)
        XCTAssertTrue(guardian.projectiles.filter { $0.lane != 2 }.allSatisfy { $0.remainingHits == 1 })
    }

    func testPersistentEffectsTriggerOnProjectileHitWithoutRecursiveDrops() {
        var state = quietState(seed: 5_004)
        for kind in DescentSkillKind.allCases {
            _ = GameRules.acquireDescentEffect(state: &state, kind: kind)
        }
        let snapshot = DescentProjectileEffectSnapshot(
            shotEventID: 77,
            loadoutVersion: state.skills.loadoutVersion,
            dominantEffect: .explosion,
            levels: state.skills.levels
        )
        state.objects = [
            object(id: 1, kind: .armored, lane: 2, y: 200, hitPoints: 10, dropKind: .fire),
            object(id: 2, kind: .armored, lane: 1, y: 200, hitPoints: 10, dropKind: .electric),
            object(id: 3, kind: .armored, lane: 3, y: 200, hitPoints: 10, dropKind: .wind),
            object(id: 4, kind: .armored, lane: 0, y: 200, hitPoints: 10, dropKind: .explosion)
        ]
        state.projectiles = [
            DescentProjectile(
                id: 9,
                lane: 2,
                effectSnapshot: snapshot,
                yQ: GameRules.descentQ(fromPoints: 194),
                velocityQPerTick: GameRules.descentQ(fromPoints: 6.5),
                damage: 1,
                remainingHits: 3,
                hitObjectIDs: []
            )
        ]
        let events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertTrue(events.contains { if case .fireEchoScheduled = $0 { true } else { false } })
        XCTAssertTrue(events.contains { if case .skillActivated(kind: .electric, level: 1, activationID: _, targetIDs: _) = $0 { true } else { false } })
        XCTAssertTrue(events.contains { if case .skillActivated(kind: .wind, level: 1, activationID: _, targetIDs: _) = $0 { true } else { false } })
        XCTAssertTrue(events.contains { if case .skillActivated(kind: .explosion, level: 1, activationID: _, targetIDs: _) = $0 { true } else { false } })
        XCTAssertFalse(events.contains { if case .dropSpawned = $0 { true } else { false } })
        XCTAssertTrue(state.drops.isEmpty)
        XCTAssertEqual(state.skills.levels, snapshot.levels)
        XCTAssertEqual(state.skills.loadoutVersion, snapshot.loadoutVersion)
    }

    func testFrenzyThresholdCapsAtEightAndMultiHitSchedulesOnlyOnce() {
        var state = quietState(seed: 5_101)
        state.tick = 999
        state.frenzy.directChainCount = 7
        state.frenzy.maxDirectChain = 7
        state.frenzy.lastDirectDestructionTick = 999
        state.objects = [
            object(id: 1, kind: .normal, lane: 0, y: 200),
            object(id: 2, kind: .normal, lane: 1, y: 200)
        ]
        state.projectiles = [
            projectile(id: 101, lane: 0, y: 194),
            projectile(id: 102, lane: 1, y: 194)
        ]

        let thresholdEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertEqual(state.frenzy.directChainCount, GameRules.descentFrenzyThreshold)
        XCTAssertEqual(state.frenzy.maxDirectChain, GameRules.descentFrenzyThreshold)
        XCTAssertEqual(state.frenzy.pendingStartTick, 1_001)
        XCTAssertEqual(
            thresholdEvents.filter { if case .frenzyChargeChanged(8) = $0 { true } else { false } }.count,
            1
        )
        XCTAssertFalse(thresholdEvents.contains { if case .frenzyStarted = $0 { true } else { false } })

        let startEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.frenzy.mode, .frenzy)
        XCTAssertEqual(state.frenzy.activationCount, 1)
        XCTAssertEqual(state.frenzy.expiresAtTick, 1_361)
        XCTAssertEqual(startEvents.filter { if case .frenzyStarted = $0 { true } else { false } }.count, 1)
    }

    func testFrenzyChainWindowUsesInclusiveOneNinetyTwoTickBoundary() {
        for (gap, expectedCount, shouldSchedule) in [
            (191, 8, true),
            (192, 8, true),
            (193, 1, false)
        ] {
            var state = quietState(seed: UInt64(5_200 + gap))
            state.tick = 999
            state.frenzy.directChainCount = 7
            state.frenzy.maxDirectChain = 7
            state.frenzy.lastDirectDestructionTick = 1_000 - gap
            state.objects = [object(id: 1, kind: .normal, lane: 0, y: 200)]
            state.projectiles = [projectile(id: 1, lane: 0, y: 194)]

            _ = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )

            XCTAssertEqual(state.frenzy.directChainCount, expectedCount, "gap \(gap)")
            XCTAssertEqual(
                state.frenzy.maxDirectChain,
                shouldSchedule ? 8 : 7,
                "gap \(gap)"
            )
            XCTAssertEqual(state.frenzy.pendingStartTick != nil, shouldSchedule, "gap \(gap)")
        }
    }

    func testFrenzyStartsNextTickRefreshesFromDirectHitAndExpiresBeforeCollision() {
        var state = quietState(seed: 5_301)
        state.tick = 100
        state.frenzy.directChainCount = 7
        state.frenzy.maxDirectChain = 7
        state.frenzy.lastDirectDestructionTick = 100
        state.objects = [object(id: 1, kind: .normal, lane: 0, y: 200)]
        state.projectiles = [projectile(id: 1, lane: 0, y: 194)]

        let thresholdEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.tick, 101)
        XCTAssertEqual(state.frenzy.mode, .calm)
        XCTAssertEqual(state.frenzy.pendingStartTick, 102)
        XCTAssertFalse(thresholdEvents.contains { if case .frenzyStarted = $0 { true } else { false } })

        let startEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.frenzy.mode, .frenzy)
        XCTAssertEqual(state.frenzy.expiresAtTick, 462)
        XCTAssertTrue(startEvents.contains {
            if case .frenzyStarted(activationID: 1, expiresAtTick: 462) = $0 { true } else { false }
        })
        XCTAssertEqual(state.frenzy.activeTickCount, 1)

        state.tick = 199
        state.objects = [object(id: 2, kind: .normal, lane: 0, y: 200)]
        state.projectiles = [projectile(id: 2, lane: 0, y: 194)]
        let extensionEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.frenzy.expiresAtTick, 560)
        XCTAssertTrue(extensionEvents.contains {
            if case .frenzyExtended(activationID: 1, expiresAtTick: 560) = $0 { true } else { false }
        })

        var capped = quietState(seed: 5_302)
        capped.tick = 7_099
        capped.frenzy.mode = .frenzy
        capped.frenzy.activationCount = 1
        capped.frenzy.expiresAtTick = 7_150
        capped.objects = [object(id: 1, kind: .normal, lane: 0, y: 200)]
        capped.projectiles = [projectile(id: 1, lane: 0, y: 194)]
        _ = GameRules.stepDescent(
            state: &capped,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(capped.frenzy.expiresAtTick, GameRules.descentRunDurationTicks)

        state.tick = 559
        state.objects = [object(id: 3, kind: .normal, lane: 0, y: 200)]
        state.projectiles = [projectile(id: 3, lane: 0, y: 194)]
        let expiryEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.frenzy.mode, .calm)
        XCTAssertEqual(state.frenzy.directChainCount, 1)
        XCTAssertNil(state.frenzy.expiresAtTick)
        XCTAssertTrue(expiryEvents.contains { if case .frenzyEnded(activationID: 1) = $0 { true } else { false } })
        XCTAssertFalse(expiryEvents.contains { if case .frenzyBonus = $0 { true } else { false } })
    }

    func testFrenzyActiveTickCountIncludesStartAndExcludesExpiryAtNMinusOneNAndNPlusOne() {
        var state = quietState(seed: 5_303)
        state.tick = 99
        state.frenzy.pendingStartTick = 100

        _ = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.tick, 100)
        XCTAssertEqual(state.frenzy.activeTickCount, 1)
        XCTAssertEqual(state.frenzy.expiresAtTick, 460)

        for _ in 0..<358 {
            _ = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
        }
        XCTAssertEqual(state.tick, 458)
        XCTAssertEqual(state.frenzy.activeTickCount, 359) // N-1

        _ = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.tick, 459)
        XCTAssertEqual(state.frenzy.activeTickCount, 360) // N

        _ = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.tick, 460)
        XCTAssertEqual(state.frenzy.mode, .calm)
        XCTAssertEqual(state.frenzy.activeTickCount, 360) // N+1 expiry tick excluded
    }

    func testSkillAndEchoDestructionsNeverChargeOrExtendFrenzy() {
        var echoState = quietState(seed: 5_401)
        echoState.tick = 10
        echoState.frenzy.directChainCount = 7
        echoState.frenzy.maxDirectChain = 7
        echoState.frenzy.lastDirectDestructionTick = 10
        echoState.objects = [object(id: 1, kind: .normal, lane: 0, y: 250)]
        echoState.skills.pendingFireEchoes = [
            DescentPendingFireEcho(
                activationID: 1,
                projectileID: 1,
                shotEventID: 1,
                triggerTick: 11,
                targetIDs: [1],
                comboAwardsRemaining: 1
            )
        ]
        let echoEvents = GameRules.stepDescent(
            state: &echoState,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(echoState.frenzy.directChainCount, 7)
        XCTAssertNil(echoState.frenzy.pendingStartTick)
        XCTAssertFalse(echoEvents.contains { if case .frenzyChargeChanged = $0 { true } else { false } })

        var waveState = quietState(seed: 5_402)
        waveState.tick = 99
        waveState.frenzy.directChainCount = 7
        waveState.frenzy.maxDirectChain = 7
        waveState.frenzy.lastDirectDestructionTick = 99
        waveState.skills.levels.electric = 1
        let snapshot = DescentProjectileEffectSnapshot(
            shotEventID: 1,
            loadoutVersion: 1,
            dominantEffect: .electric,
            levels: waveState.skills.levels
        )
        waveState.objects = [
            object(id: 1, kind: .normal, lane: 0, y: 200),
            object(id: 2, kind: .normal, lane: 1, y: 200),
            object(id: 3, kind: .normal, lane: 2, y: 200)
        ]
        waveState.projectiles = [
            DescentProjectile(
                id: 1,
                lane: 0,
                effectSnapshot: snapshot,
                yQ: GameRules.descentQ(fromPoints: 194),
                velocityQPerTick: GameRules.descentQ(fromPoints: 6.5),
                damage: 1,
                remainingHits: 1,
                hitObjectIDs: []
            )
        ]
        let waveEvents = GameRules.stepDescent(
            state: &waveState,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertTrue(waveState.objects.isEmpty)
        XCTAssertEqual(waveState.frenzy.directChainCount, 8)
        XCTAssertEqual(waveState.frenzy.maxDirectChain, 8)
        XCTAssertEqual(waveState.frenzy.pendingStartTick, 101)
        XCTAssertEqual(
            waveEvents.filter { if case .frenzyChargeChanged = $0 { true } else { false } }.count,
            1
        )
    }

    func testFrenzyAndRedlineBonusesAreAdditiveFromSameComboBase() {
        var state = quietState(seed: 5_501)
        state.tick = 100
        state.combo = 4
        state.lastDestructionTick = 100
        state.choiceArena.wasPresented = true
        state.choiceArena.selectedChoice = .redline
        state.choiceArena.selectedAtTick = 100
        state.frenzy.mode = .frenzy
        state.frenzy.activationCount = 1
        state.frenzy.expiresAtTick = 460
        state.objects = [object(id: 1, kind: .normal, lane: 0, y: 200)]
        state.projectiles = [projectile(id: 1, lane: 0, y: 194)]

        let events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertEqual(state.combo, 5)
        XCTAssertEqual(state.score, 170) // base 110 + redline 38 + frenzy 22
        XCTAssertEqual(state.choiceArena.redlineBonusScore, 38)
        XCTAssertEqual(state.frenzy.bonusScore, 22)
        XCTAssertEqual(state.frenzy.maxDirectChain, 0)
        XCTAssertTrue(events.contains { if case .frenzyBonus(objectID: 1, points: 22) = $0 { true } else { false } })
        XCTAssertTrue(events.contains { if case .objectDestroyed(id: 1, cause: _, points: 170) = $0 { true } else { false } })
    }

    func testChoiceArenaFreezeAlsoFreezesFrenzyExpiry() {
        var state = quietState(seed: 5_601)
        state.tick = 3_600
        state.frenzy.mode = .frenzy
        state.frenzy.activationCount = 2
        state.frenzy.expiresAtTick = 3_601
        state.frenzy.activeTickCount = 10
        _ = GameRules.presentDescentChoiceArena(state: &state)
        let frozen = state

        XCTAssertTrue(GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 39)
        ).isEmpty)
        XCTAssertEqual(state, frozen)

        _ = GameRules.resolveDescentChoiceArena(state: &state, choice: .steady)
        let resumedEvents = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 39)
        )
        XCTAssertEqual(state.tick, 3_601)
        XCTAssertEqual(state.frenzy.mode, .calm)
        XCTAssertEqual(state.frenzy.activeTickCount, 10)
        XCTAssertTrue(resumedEvents.contains { if case .frenzyEnded(activationID: 2) = $0 { true } else { false } })
    }

    func testFrenzyEventsStateAndChecksumMatchAllCadences() {
        let baseline = scriptedFrenzyRun(batchSize: 1)
        XCTAssertTrue(baseline.events.contains { if case .frenzyStarted = $0 { true } else { false } })
        XCTAssertTrue(baseline.events.contains { if case .frenzyExtended = $0 { true } else { false } })
        XCTAssertTrue(baseline.events.contains { if case .frenzyEnded = $0 { true } else { false } })

        for batchSize in [2, 4, 37] {
            let candidate = scriptedFrenzyRun(batchSize: batchSize)
            XCTAssertEqual(candidate.state, baseline.state, "batch \(batchSize)")
            XCTAssertEqual(candidate.events, baseline.events, "batch \(batchSize)")
            XCTAssertEqual(
                GameRules.descentChecksum(candidate.state),
                GameRules.descentChecksum(baseline.state),
                "batch \(batchSize)"
            )
        }
    }

    func testBreachCooldownCoalescesDamageForExactlyFiftyFourTicks() {
        var state = quietState(seed: 6)
        state.player.reactorHP = 3
        state.objects = [
            object(id: 1, kind: .normal, lane: 0, y: 128.1, fallPerTick: 1),
            object(id: 2, kind: .normal, lane: 4, y: 128.1, fallPerTick: 1)
        ]
        var events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.player.reactorHP, 2)
        XCTAssertEqual(events.filter(breachedObject).count, 2)
        XCTAssertEqual(events.filter(damagingBreach).count, 1)

        state.objects = [object(id: 3, kind: .normal, lane: 2, y: 128.1, fallPerTick: 1)]
        events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.player.reactorHP, 2)
        XCTAssertEqual(events.filter(damagingBreach).count, 0)

        state.tick = 54
        state.objects = [object(id: 4, kind: .normal, lane: 2, y: 128.1, fallPerTick: 1)]
        events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.player.reactorHP, 1)
        XCTAssertEqual(events.filter(damagingBreach).count, 1)
    }

    func testLegacyDirectActivationFixtureCapsAtThree() {
        for kind in DescentSkillKind.allCases {
            var state = quietState(seed: UInt64(kind.rawValue + 20))
            var levels: [Int] = []
            for _ in 0..<4 {
                let events = GameRules.testOnlyActivateLegacyDescentSkill(state: &state, kind: kind)
                levels.append(contentsOf: events.compactMap(activatedSkillLevel))
            }
            XCTAssertEqual(levels, [1, 2, 3, 3], "\(kind)")
            XCTAssertEqual(state.skills.levels.level(for: kind), 3, "\(kind)")
            XCTAssertEqual(state.skills.activationCount, 4, "\(kind)")
        }
    }

    func testLegacyFireFixtureEchoesSameStableIDsAtTickSixty() {
        var state = quietState(seed: 30)
        state.objects = (1...5).map {
            object(id: $0, kind: .core, lane: 2, y: Double(200 + $0 * 10), hitPoints: 2)
        } + [object(id: 90, kind: .core, lane: 1, y: 150, hitPoints: 2)]
        state.projectiles = blockingProjectiles(count: 24)
        state.nextProjectileID = 25

        let activation = GameRules.testOnlyActivateLegacyDescentSkill(state: &state, kind: .fire)
        XCTAssertEqual(activation.compactMap(activatedTargetIDs).first, [1, 2, 3])
        XCTAssertEqual(state.skills.pendingFireEchoes.first?.triggerTick, 60)
        XCTAssertEqual(state.objects.filter { [1, 2, 3].contains($0.id) }.map(\.hitPoints), [1, 1, 1])

        state.objects.removeAll { $0.id == 2 }
        state.objects.append(object(id: 99, kind: .core, lane: 2, y: 190, hitPoints: 2))
        for _ in 0..<59 {
            let events = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            XCTAssertFalse(events.contains { if case .fireEchoActivated = $0 { true } else { false } })
        }
        let echo = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.tick, 60)
        XCTAssertTrue(echo.contains { event in
            if case .fireEchoActivated(activationID: let id, targetIDs: let targets) = event {
                return id == 1 && targets == [1, 2, 3]
            }
            return false
        })
        XCTAssertFalse(state.objects.contains { $0.id == 1 || $0.id == 3 })
        XCTAssertEqual(state.objects.first { $0.id == 99 }?.hitPoints, 2)
        XCTAssertLessThanOrEqual(state.maxCombo, 3)
    }

    func testLegacyFireAndElectricFixturesNeverCreateRecursiveDrops() {
        let expectedCounts = [3, 4, 5]

        for level in 1...3 {
            var fire = quietState(seed: UInt64(40 + level))
            fire.skills.levels.fire = level - 1
            fire.objects = (1...8).map {
                object(id: $0, kind: .armored, lane: 2, y: Double(180 + $0), hitPoints: 10)
            }
            let fireEvents = GameRules.testOnlyActivateLegacyDescentSkill(state: &fire, kind: .fire)
            XCTAssertEqual(fireEvents.compactMap(activatedTargetIDs).first?.count, expectedCounts[level - 1])

            var electric = quietState(seed: UInt64(50 + level))
            electric.skills.levels.electric = level - 1
            electric.objects = (1...8).map {
                object(
                    id: $0,
                    kind: .normal,
                    lane: $0 % 5,
                    y: Double(170 + (9 - $0) * 4),
                    hitPoints: 1,
                    dropKind: .fire
                )
            }
            let electricEvents = GameRules.testOnlyActivateLegacyDescentSkill(state: &electric, kind: .electric)
            let targets = electricEvents.compactMap(activatedTargetIDs).first ?? []
            XCTAssertEqual(targets.count, expectedCounts[level - 1])
            XCTAssertEqual(targets, Array((1...8).reversed()).prefix(expectedCounts[level - 1]).map { $0 })
            XCTAssertFalse(electricEvents.contains { if case .dropSpawned = $0 { true } else { false } })
            XCTAssertTrue(electric.drops.isEmpty)
            XCTAssertEqual(electric.skills.levels.fire, 0)
        }
    }

    func testPiercePersistsInNewProjectileSnapshotsWithoutExpiring() {
        let capacities = [3, 5, 7]
        for level in 1...3 {
            var state = quietState(seed: UInt64(60 + level))
            for _ in 0..<level {
                _ = GameRules.acquireDescentEffect(state: &state, kind: .pierce)
            }
            state.tick = 21
            _ = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            XCTAssertEqual(state.projectiles.last?.remainingHits, capacities[level - 1])
            XCTAssertEqual(state.projectiles.last?.effectSnapshot.levels.pierce, level)

            state.tick = 2_000
            state.projectiles.removeAll()
            state.nextSpawnTick = .max
            _ = GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            while !state.tick.isMultiple(of: 22) {
                _ = GameRules.stepDescent(
                    state: &state,
                    input: DescentInput(targetXPoints: 195)
                )
            }
            XCTAssertEqual(state.projectiles.last?.remainingHits, capacities[level - 1])
            XCTAssertEqual(state.skills.levels.pierce, level)
        }
    }

    func testLegacyWindFixtureRetainsRevisionThreeExpiryContract() {
        var state = quietState(seed: 70)
        state.objects = [object(id: 1, kind: .armored, lane: 2, y: 300, fallPerTick: 1)]

        _ = GameRules.testOnlyActivateLegacyDescentSkill(state: &state, kind: .wind)
        XCTAssertEqual(GameRules.descentPoints(fromQ: state.objects[0].yQ), 348, accuracy: 0.001)
        XCTAssertEqual(state.skills.windMultiplierPercent, 70)
        XCTAssertEqual(state.skills.windExpiresTick, 300)

        _ = GameRules.testOnlyActivateLegacyDescentSkill(state: &state, kind: .wind)
        XCTAssertEqual(GameRules.descentPoints(fromQ: state.objects[0].yQ), 412, accuracy: 0.001)
        XCTAssertEqual(state.skills.windMultiplierPercent, 60)
        XCTAssertEqual(state.skills.windExpiresTick, 360)

        state.tick = 359
        _ = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.skills.windMultiplierPercent, 100)
        XCTAssertEqual(GameRules.descentPoints(fromQ: state.objects[0].yQ), 411, accuracy: 0.001)
    }

    func testLegacyExplosionFixtureUsesStableTargetOrder() {
        let targetCaps = [6, 7, 8]
        let damages = [2, 2, 3]
        for level in 1...3 {
            var state = quietState(seed: UInt64(80 + level))
            state.skills.levels.explosion = level - 1
            state.objects = (1...10).map {
                object(id: $0, kind: .armored, lane: 2, y: 200, hitPoints: 10)
            }
            let events = GameRules.testOnlyActivateLegacyDescentSkill(state: &state, kind: .explosion)
            let targets = events.compactMap(activatedTargetIDs).first ?? []
            XCTAssertEqual(targets, Array(1...targetCaps[level - 1]))
            XCTAssertEqual(state.objects.first { $0.id == 1 }?.hitPoints, 10 - damages[level - 1])
            XCTAssertEqual(state.objects.first { $0.id == 10 }?.hitPoints, 10)
        }

        var radius = quietState(seed: 84)
        radius.objects = [
            object(id: 10, kind: .armored, lane: 2, y: 200, hitPoints: 10),
            object(id: 11, kind: .armored, lane: 1, y: 200, hitPoints: 10),
            object(id: 12, kind: .armored, lane: 3, y: 200, hitPoints: 10),
            object(id: 13, kind: .armored, lane: 2, y: 290, hitPoints: 10),
            object(id: 14, kind: .armored, lane: 0, y: 200, hitPoints: 10)
        ]
        let events = GameRules.testOnlyActivateLegacyDescentSkill(state: &radius, kind: .explosion)
        XCTAssertEqual(events.compactMap(activatedTargetIDs).first, [10, 11, 12, 13])
        XCTAssertEqual(radius.objects.first { $0.id == 14 }?.hitPoints, 10)
    }

    func testChoiceArenaPresentsOnceAfterTickThirtyProcessingAndFreezesStepState() {
        var state = quietState(seed: 85)
        state.tick = 3_599
        state.objects = [
            object(
                id: 10,
                kind: .core,
                lane: 2,
                y: 128.4,
                hitPoints: 1,
                fallPerTick: 1,
                dropKind: .fire
            )
        ]
        state.projectiles = [projectile(id: 1, lane: 2, y: 126)]
        state.drops = [
            DescentDrop(
                id: 8,
                sourceObjectID: 7,
                kind: .electric,
                lane: 2,
                yQ: GameRules.descentQ(fromPoints: GameRules.descentPlayerY + 1),
                spawnedAtTick: 3_598
            )
        ]
        state.nextDropID = 9

        let events = GameRules.stepDescent(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertEqual(state.tick, 3_600)
        XCTAssertTrue(state.choiceArena.wasPresented)
        XCTAssertTrue(state.choiceArena.isAwaitingChoice)
        XCTAssertNil(state.choiceArena.selectedChoice)
        XCTAssertNil(state.choiceArena.selectedAtTick)
        XCTAssertTrue(events.contains { if case .difficultyAdvanced = $0 { true } else { false } })
        XCTAssertTrue(events.contains { if case .objectDestroyed(id: 10, cause: _, points: _) = $0 { true } else { false } })
        XCTAssertTrue(events.contains {
            if case .dropCollected(
                id: 8,
                kind: .electric,
                level: 1,
                display: .plusOne,
                loadoutVersion: 1
            ) = $0 { true } else { false }
        })
        XCTAssertEqual(events.last, .choiceArenaPresented(tick: 3_600))
        XCTAssertEqual(events.filter { if case .choiceArenaPresented = $0 { true } else { false } }.count, 1)

        let frozen = state
        let frozenChecksum = GameRules.descentChecksum(state)
        XCTAssertEqual(
            GameRules.stepDescent(
                state: &state,
                input: DescentInput(targetXPoints: 39)
            ),
            []
        )
        XCTAssertEqual(state, frozen)
        XCTAssertEqual(GameRules.descentChecksum(state), frozenChecksum)
        XCTAssertEqual(GameRules.presentDescentChoiceArena(state: &state), [])
        XCTAssertEqual(state, frozen)

        var ending = quietState(seed: 850)
        ending.tick = 3_599
        ending.player.reactorHP = 1
        ending.objects = [object(id: 20, kind: .normal, lane: 0, y: 128.1, fallPerTick: 1)]
        let endingEvents = GameRules.stepDescent(
            state: &ending,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(ending.tick, 3_600)
        XCTAssertEqual(ending.phase, .finished)
        XCTAssertEqual(ending.endReason, .reactorDestroyed)
        XCTAssertFalse(ending.choiceArena.wasPresented)
        XCTAssertFalse(endingEvents.contains { if case .choiceArenaPresented = $0 { true } else { false } })
    }

    func testChoiceArenaResolveIsIdempotentAndRedlineStartsOnFollowingTick() {
        var notPresented = quietState(seed: 860)
        let notPresentedSnapshot = notPresented
        XCTAssertEqual(
            GameRules.resolveDescentChoiceArena(state: &notPresented, choice: .redline),
            []
        )
        XCTAssertEqual(notPresented, notPresentedSnapshot)

        var redline = quietState(seed: 86)
        redline.tick = 3_600
        XCTAssertEqual(
            GameRules.presentDescentChoiceArena(state: &redline),
            [.choiceArenaPresented(tick: 3_600)]
        )
        XCTAssertEqual(
            GameRules.resolveDescentChoiceArena(state: &redline, choice: .redline),
            [.choiceArenaResolved(.redline)]
        )
        XCTAssertEqual(redline.choiceArena.selectedAtTick, 3_600)
        XCTAssertEqual(
            GameRules.resolveDescentChoiceArena(state: &redline, choice: .steady),
            []
        )
        XCTAssertEqual(redline.choiceArena.selectedChoice, .redline)

        redline.objects = [object(id: 1, kind: .normal, lane: 2, y: 300, fallPerTick: 1)]
        let selectedY = redline.objects[0].yQ
        XCTAssertEqual(selectedY, GameRules.descentQ(fromPoints: 300))

        var steady = redline
        steady.choiceArena.selectedChoice = .steady
        _ = GameRules.stepDescent(state: &redline, input: DescentInput(targetXPoints: 195))
        _ = GameRules.stepDescent(state: &steady, input: DescentInput(targetXPoints: 195))

        XCTAssertEqual(redline.tick, 3_601)
        XCTAssertEqual(
            selectedY - redline.objects[0].yQ,
            GameRules.descentQ(fromPoints: 1.18)
        )
        XCTAssertEqual(
            selectedY - steady.objects[0].yQ,
            GameRules.descentQ(fromPoints: 1)
        )
    }

    func testRedlineRelativeImpactUsesBoostedDeltaAndDirectScoreBonusOnly() {
        var redline = resolvedChoiceState(seed: 87, choice: .redline)
        redline.objects = [object(id: 1, kind: .normal, lane: 2, y: 201.1, fallPerTick: 1)]
        redline.projectiles = [
            DescentProjectile(
                id: 1,
                lane: 2,
                yQ: GameRules.descentQ(fromPoints: 200),
                velocityQPerTick: 0,
                damage: 1,
                remainingHits: 1,
                hitObjectIDs: []
            )
        ]
        var steady = redline
        steady.choiceArena.selectedChoice = .steady

        let redlineEvents = GameRules.stepDescent(
            state: &redline,
            input: DescentInput(targetXPoints: 195)
        )
        let steadyEvents = GameRules.stepDescent(
            state: &steady,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertTrue(redline.objects.isEmpty)
        XCTAssertEqual(steady.objects.count, 1)
        XCTAssertEqual(redlineEvents.compactMap(destroyedPoints).first, 135)
        XCTAssertFalse(steadyEvents.contains { if case .objectDestroyed = $0 { true } else { false } })
        XCTAssertEqual(redline.score, 135)
        XCTAssertEqual(redline.choiceArena.redlineBonusScore, 35)
    }

    func testRedlineUsesComboBaseFloorWhileLegacySkillFixtureRemainsUnchanged() {
        var direct = resolvedChoiceState(seed: 88, choice: .redline)
        direct.combo = 4
        direct.lastDestructionTick = direct.tick
        direct.objects = [object(id: 1, kind: .normal, lane: 2, y: 160, hitPoints: 1)]
        direct.projectiles = [projectile(id: 1, lane: 2, y: 154)]
        let directEvents = GameRules.stepDescent(
            state: &direct,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertEqual(direct.combo, 5)
        XCTAssertEqual(directEvents.compactMap(destroyedPoints).first, 298)
        XCTAssertTrue(directEvents.contains(.dangerSave(id: 1, bonus: 150)))
        XCTAssertEqual(direct.choiceArena.redlineBonusScore, 38)
        XCTAssertEqual(direct.score, 298)

        var skill = resolvedChoiceState(seed: 89, choice: .redline)
        skill.tick = 3_601
        skill.objects = [object(id: 2, kind: .normal, lane: 2, y: 160, hitPoints: 1)]
        let skillEvents = GameRules.testOnlyActivateLegacyDescentSkill(state: &skill, kind: .electric)
        XCTAssertEqual(skillEvents.compactMap(destroyedPoints).first, 250)
        XCTAssertTrue(skillEvents.contains(.dangerSave(id: 2, bonus: 150)))
        XCTAssertEqual(skill.score, 250)
        XCTAssertEqual(skill.skillScore, 250)
        XCTAssertEqual(skill.choiceArena.redlineBonusScore, 0)
    }

    func testChoiceArenaChecksumCoversEveryAuthoritativeField() {
        let baseline = quietState(seed: 90)
        let baselineChecksum = GameRules.descentChecksum(baseline)

        var presented = baseline
        presented.choiceArena.wasPresented = true
        XCTAssertNotEqual(GameRules.descentChecksum(presented), baselineChecksum)

        var awaiting = presented
        awaiting.choiceArena.isAwaitingChoice = true
        XCTAssertNotEqual(GameRules.descentChecksum(awaiting), GameRules.descentChecksum(presented))

        var steady = presented
        steady.choiceArena.selectedChoice = .steady
        steady.choiceArena.selectedAtTick = 3_600
        XCTAssertNotEqual(GameRules.descentChecksum(steady), GameRules.descentChecksum(presented))

        var redline = steady
        redline.choiceArena.selectedChoice = .redline
        XCTAssertNotEqual(GameRules.descentChecksum(redline), GameRules.descentChecksum(steady))

        var later = redline
        later.choiceArena.selectedAtTick = 3_601
        XCTAssertNotEqual(GameRules.descentChecksum(later), GameRules.descentChecksum(redline))

        var bonus = redline
        bonus.choiceArena.redlineBonusScore = 1
        XCTAssertNotEqual(GameRules.descentChecksum(bonus), GameRules.descentChecksum(redline))
    }

    func testRedlineMatchesAllSchedulersShipsAndFiveSkillsWithinCaps() {
        for shipKind in DescentShipKind.allCases {
            let baseline = simulatedRun(
                seed: 20_260_821,
                batchSize: 1,
                shipKind: shipKind,
                choice: .redline,
                preactivatedSkills: DescentSkillKind.allCases
            )
            for batchSize in [2, 4, 37] {
                let candidate = simulatedRun(
                    seed: 20_260_821,
                    batchSize: batchSize,
                    shipKind: shipKind,
                    choice: .redline,
                    preactivatedSkills: DescentSkillKind.allCases
                )
                XCTAssertEqual(candidate.state, baseline.state, "\(shipKind), batch \(batchSize)")
                XCTAssertEqual(candidate.events, baseline.events, "\(shipKind), batch \(batchSize)")
                XCTAssertEqual(
                    GameRules.descentChecksum(candidate.state),
                    GameRules.descentChecksum(baseline.state)
                )
            }
            XCTAssertEqual(baseline.state.tick, GameRules.descentRunDurationTicks)
            XCTAssertEqual(baseline.state.choiceArena.selectedChoice, .redline)
            XCTAssertLessThanOrEqual(baseline.state.peakObjectCount, GameRules.descentMaximumObjects)
            XCTAssertLessThanOrEqual(baseline.state.peakProjectileCount, GameRules.descentMaximumProjectiles)
            XCTAssertLessThanOrEqual(baseline.state.peakDropCount, GameRules.descentMaximumDrops)
            for kind in DescentSkillKind.allCases {
                XCTAssertGreaterThanOrEqual(baseline.state.skills.levels.level(for: kind), 1)
            }
        }
    }

    func testFixedTickStateEventsAndChecksumMatchThirtySixtyOneTwentyAndLargeBatches() {
        let oneTwenty = simulatedRun(seed: 20_260_819, batchSize: 1)
        let sixty = simulatedRun(seed: 20_260_819, batchSize: 2)
        let thirty = simulatedRun(seed: 20_260_819, batchSize: 4)
        let largeDelta = simulatedRun(seed: 20_260_819, batchSize: 37)

        for candidate in [sixty, thirty, largeDelta] {
            XCTAssertEqual(candidate.state, oneTwenty.state)
            XCTAssertEqual(candidate.events, oneTwenty.events)
            XCTAssertEqual(
                GameRules.descentChecksum(candidate.state),
                GameRules.descentChecksum(oneTwenty.state)
            )
        }
        XCTAssertEqual(oneTwenty.state.tick, 7_200)
        XCTAssertEqual(oneTwenty.state.phase, .finished)
        XCTAssertEqual(oneTwenty.state.endReason, .survivedSixtySeconds)
        XCTAssertLessThanOrEqual(oneTwenty.state.peakObjectCount, 36)
        XCTAssertLessThanOrEqual(oneTwenty.state.peakProjectileCount, 24)
        XCTAssertLessThanOrEqual(oneTwenty.state.peakDropCount, 8)
    }

    func testEveryShipMatchesThirtySixtyOneTwentyAndLargeBatchScheduling() {
        var checksums: [UInt64] = []
        for shipKind in DescentShipKind.allCases {
            let oneTwenty = simulatedRun(seed: 20_260_820, batchSize: 1, shipKind: shipKind)
            let candidates = [
                simulatedRun(seed: 20_260_820, batchSize: 2, shipKind: shipKind),
                simulatedRun(seed: 20_260_820, batchSize: 4, shipKind: shipKind),
                simulatedRun(seed: 20_260_820, batchSize: 37, shipKind: shipKind)
            ]
            for candidate in candidates {
                XCTAssertEqual(candidate.state, oneTwenty.state)
                XCTAssertEqual(candidate.events, oneTwenty.events)
                XCTAssertEqual(
                    GameRules.descentChecksum(candidate.state),
                    GameRules.descentChecksum(oneTwenty.state)
                )
            }
            XCTAssertLessThanOrEqual(oneTwenty.state.peakProjectileCount, GameRules.descentMaximumProjectiles)
            checksums.append(GameRules.descentChecksum(oneTwenty.state))
        }
        XCTAssertEqual(Set(checksums).count, DescentShipKind.allCases.count)
    }

    func testReferenceControllerSurvivesAtLeastNinetyNineOfOneHundredSeeds() {
        var survivors = 0
        var failures: [(UInt64, Int)] = []
        for seed in UInt64(0)..<100 {
            let run = simulatedRun(seed: seed, batchSize: 4, reactorHP: 3)
            if run.state.endReason == .survivedSixtySeconds { survivors += 1 }
            else { failures.append((seed, run.state.tick)) }
        }
        XCTAssertGreaterThanOrEqual(survivors, 99, "failures: \(failures)")
    }

    func testChecksumCoversAllAuthoritativeCollectionsAndSkillTimers() {
        var state = quietState(seed: 90)
        state.objects = [
            object(id: 2, kind: .normal, lane: 2, y: 300),
            object(id: 1, kind: .core, lane: 1, y: 250, dropKind: .wind)
        ]
        state.drops = [
            DescentDrop(
                id: 1,
                sourceObjectID: 1,
                kind: .wind,
                lane: 1,
                yQ: 900_000,
                spawnedAtTick: 2
            )
        ]
        let baseline = GameRules.descentChecksum(state)

        state.objects.reverse()
        XCTAssertEqual(GameRules.descentChecksum(state), baseline)

        state.objects[0].yQ += 1
        XCTAssertNotEqual(GameRules.descentChecksum(state), baseline)
        let moved = GameRules.descentChecksum(state)
        state.skills.pendingFireEchoes.append(
            DescentPendingFireEcho(
                activationID: 7,
                projectileID: 3,
                shotEventID: 2,
                triggerTick: 70,
                targetIDs: [1, 2],
                comboAwardsRemaining: 2
            )
        )
        XCTAssertNotEqual(GameRules.descentChecksum(state), moved)
    }

    func testChecksumCoversEveryAuthoritativeFrenzyField() {
        let state = quietState(seed: 91)
        let baseline = GameRules.descentChecksum(state)

        func assertChangesChecksum(
            _ mutate: (inout DescentState) -> Void,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            var candidate = state
            mutate(&candidate)
            XCTAssertNotEqual(
                GameRules.descentChecksum(candidate),
                baseline,
                file: file,
                line: line
            )
        }

        assertChangesChecksum { $0.frenzy.mode = .frenzy }
        assertChangesChecksum { $0.frenzy.directChainCount = 1 }
        assertChangesChecksum { $0.frenzy.maxDirectChain = 1 }
        assertChangesChecksum { $0.frenzy.lastDirectDestructionTick = 1 }
        assertChangesChecksum { $0.frenzy.pendingStartTick = 2 }
        assertChangesChecksum { $0.frenzy.expiresAtTick = 3 }
        assertChangesChecksum { $0.frenzy.activationCount = 1 }
        assertChangesChecksum { $0.frenzy.activeTickCount = 1 }
        assertChangesChecksum { $0.frenzy.bonusScore = 1 }
    }

    func testEndlessDifficultyAlternatesOneBoundedAxisAfterRevisionFiveMinute() {
        XCTAssertEqual(GameRules.descentEndlessDifficulty(atTick: 7_199), GameRules.descentDifficulty(atTick: 7_199))

        let levelTwo = GameRules.descentEndlessDifficulty(atTick: 7_200)
        XCTAssertEqual(levelTwo.startTick, 7_200)
        XCTAssertEqual(levelTwo.baseFallSpeed, 112)
        XCTAssertEqual(levelTwo.spawnIntervalTicks, 94)

        let levelThree = GameRules.descentEndlessDifficulty(atTick: 14_400)
        XCTAssertEqual(levelThree.startTick, 14_400)
        XCTAssertEqual(levelThree.baseFallSpeed, 120)
        XCTAssertEqual(levelThree.spawnIntervalTicks, 94)

        let levelFour = GameRules.descentEndlessDifficulty(atTick: 21_600)
        XCTAssertEqual(levelFour.baseFallSpeed, 120)
        XCTAssertEqual(levelFour.spawnIntervalTicks, 90)

        let bounded = GameRules.descentEndlessDifficulty(atTick: Int.max)
        XCTAssertEqual(bounded.baseFallSpeed, 160)
        XCTAssertEqual(bounded.spawnIntervalTicks, 72)
        XCTAssertEqual(bounded.objectCap, GameRules.descentMaximumObjects)
        XCTAssertEqual(bounded.projectileCap, GameRules.descentMaximumProjectiles)
        XCTAssertEqual(bounded.dropCap, GameRules.descentMaximumDrops)
    }

    func testRankedEndlessLoadoutsExposeNonDominatingTradeoffs() {
        let interceptor = GameRules.descentEndlessLoadout(for: .interceptor)
        XCTAssertEqual(interceptor.damage, 2)
        XCTAssertEqual(interceptor.fireIntervalTicks, 24)
        XCTAssertEqual(interceptor.projectilesPerVolley, 1)
        XCTAssertEqual(interceptor.maximumPlayerSpeed, 1_000)

        let striker = GameRules.descentEndlessLoadout(for: .striker)
        XCTAssertEqual(striker.damage, 5)
        XCTAssertEqual(striker.fireIntervalTicks, 32)
        XCTAssertEqual(striker.projectilesPerVolley, 1)
        XCTAssertEqual(striker.maximumPlayerSpeed, 620)

        let guardian = GameRules.descentEndlessLoadout(for: .guardian)
        XCTAssertEqual(guardian.damage, 2)
        XCTAssertEqual(guardian.fireIntervalTicks, 36)
        XCTAssertEqual(guardian.projectilesPerVolley, 3)
        XCTAssertEqual(guardian.maximumPlayerSpeed, 800)
        XCTAssertTrue(guardian.centerProjectileCarriesEffectsOnly)

        XCTAssertEqual(GameRules.descentLoadout(for: .interceptor).damage, 1)
        XCTAssertEqual(GameRules.descentLoadout(for: .striker).fireIntervalTicks, 44)
        XCTAssertEqual(GameRules.descentLoadout(for: .guardian).fireIntervalTicks, 66)
    }

    func testEndlessThreatAndHitPointsAdvanceAcrossScoreAndTimeBoundaries() {
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 3_999, tick: 0), 0)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 4_000, tick: 0), 1)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 10_000, tick: 0), 2)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 25_000, tick: 0), 3)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 50_000, tick: 0), 4)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 0, tick: 3_600), 1)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 0, tick: 7_200), 2)
        XCTAssertEqual(GameRules.descentEndlessThreatTier(score: 0, tick: Int.max), 6)

        XCTAssertEqual(GameRules.descentEndlessHitPoints(for: .normal, threatTier: 0), 4)
        XCTAssertEqual(GameRules.descentEndlessHitPoints(for: .armored, threatTier: 0), 10)
        XCTAssertEqual(GameRules.descentEndlessHitPoints(for: .drone, threatTier: 2), 7)
        XCTAssertEqual(GameRules.descentEndlessHitPoints(for: .brute, threatTier: 1), 16)
        XCTAssertEqual(GameRules.descentEndlessHitPoints(for: .brute, threatTier: 6), 32)
    }

    func testEndlessGuardianSideProjectilesCannotTripleProcElementalSkills() {
        var state = quietEndlessState(seed: 20_260_821, shipKind: .guardian)
        _ = GameRules.acquireDescentEffect(state: &state.combat, kind: .electric)
        _ = GameRules.acquireDescentEffect(state: &state.combat, kind: .wind)
        state.combat.tick = GameRules.descentEndlessLoadout(for: .guardian).fireIntervalTicks - 1

        let events = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        let fired = events.compactMap { event -> DescentProjectile? in
            guard case .combat(.projectileFired(let projectile)) = event else { return nil }
            return projectile
        }

        XCTAssertEqual(fired.map(\.lane), [1, 2, 3])
        XCTAssertEqual(fired.first { $0.lane == 2 }?.effectSnapshot.levels.electric, 1)
        XCTAssertEqual(fired.first { $0.lane == 2 }?.effectSnapshot.levels.wind, 1)
        XCTAssertTrue(fired.filter { $0.lane != 2 }.allSatisfy {
            $0.effectSnapshot.levels == DescentSkillLevels()
        })
    }

    func testEndlessElectricChainsFourSixEightWhileRevisionFiveKeepsThreeTargets() {
        for (level, expectedTotal) in [(1, 4), (2, 6), (3, 8)] {
            var state = quietEndlessState(seed: UInt64(3_000 + level))
            state.combat.skills.levels.electric = level
            state.combat.objects = electricTestObjects()
            state.combat.projectiles = [electricTestProjectile(level: level)]

            let events = GameRules.stepDescentEndless(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            let targets = events.compactMap { event -> [Int]? in
                guard case .combat(.skillActivated(
                    kind: .electric,
                    level: level,
                    activationID: _,
                    targetIDs: let ids
                )) = event else { return nil }
                return ids
            }.first
            let cue = events.compactMap { event -> DescentSkillActivationCue? in
                guard case .combat(.skillCue(let cue)) = event, cue.kind == .electric else {
                    return nil
                }
                return cue
            }.first

            XCTAssertEqual(targets?.count, expectedTotal)
            XCTAssertEqual(cue?.targets.count, expectedTotal - 1)
            XCTAssertEqual(cue?.origin.xQ, GameRules.descentQ(fromPoints: 195))
        }

        var revisionFive = quietState(seed: 4_000)
        revisionFive.skills.levels.electric = 1
        revisionFive.objects = electricTestObjects()
        revisionFive.projectiles = [electricTestProjectile(level: 1)]
        let legacyEvents = GameRules.stepDescent(
            state: &revisionFive,
            input: DescentInput(targetXPoints: 195)
        )
        let legacyTargets = legacyEvents.compactMap { event -> [Int]? in
            guard case .skillActivated(
                kind: .electric,
                level: 1,
                activationID: _,
                targetIDs: let ids
            ) = event else { return nil }
            return ids
        }.first
        XCTAssertEqual(legacyTargets?.count, 3)
    }

    func testEndlessWindCueTargetsMatchPostPushObjectCoordinates() throws {
        var state = quietEndlessState(seed: 4_120)
        state.combat.skills.levels.wind = 3
        state.combat.objects = electricTestObjects()
        var levels = DescentSkillLevels()
        levels.wind = 3
        state.combat.projectiles = [
            DescentProjectile(
                id: 1,
                lane: 2,
                effectSnapshot: DescentProjectileEffectSnapshot(
                    shotEventID: 1,
                    loadoutVersion: 1,
                    dominantEffect: .wind,
                    levels: levels
                ),
                yQ: GameRules.descentQ(fromPoints: 194),
                velocityQPerTick: GameRules.descentQ(fromPoints: 6.5),
                damage: 1,
                remainingHits: 1,
                hitObjectIDs: []
            )
        ]

        let events = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        let cue = events.compactMap { event -> DescentSkillActivationCue? in
            guard case .combat(.skillCue(let cue)) = event, cue.kind == .wind else {
                return nil
            }
            return cue
        }.first

        XCTAssertEqual(cue?.targets.count, 5)
        for point in cue?.targets ?? [] {
            let object = try XCTUnwrap(
                state.combat.objects.first { $0.id == point.objectID }
            )
            XCTAssertEqual(
                point.xQ,
                GameRules.descentQ(
                    fromPoints: Double(GameRules.descentLaneXPoints[object.lane])
                )
            )
            XCTAssertEqual(point.yQ, object.yQ)
        }
    }

    func testEndlessDroneFiresTelegraphedProjectileThatResolvesOnce() {
        var state = quietEndlessState(seed: 8_021)
        state.combat.score = 10_000
        state.combat.player.reactorHP = 3
        state.combat.objects = [
            object(
                id: 90,
                kind: .drone,
                lane: 2,
                y: 500,
                hitPoints: 100,
                enemyAttackAtTick: 1
            )
        ]

        let firedEvents = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.combat.enemyProjectiles.count, 1)
        XCTAssertTrue(firedEvents.contains { event in
            if case .combat(.enemyProjectileFired(let projectile)) = event {
                return projectile.sourceObjectID == 90 && projectile.spawnedAtTick == 1
            }
            return false
        })

        var resolutions: [(Bool, Bool)] = []
        for _ in 0..<240 where state.phase == .playing && resolutions.isEmpty {
            let events = GameRules.stepDescentEndless(
                state: &state,
                input: DescentInput(targetXPoints: 195)
            )
            for event in events {
                if case .combat(.enemyProjectileResolved(
                    id: _,
                    hitPlayer: let hit,
                    reactorDamaged: let damaged
                )) = event {
                    resolutions.append((hit, damaged))
                }
            }
        }

        XCTAssertEqual(resolutions.count, 1)
        XCTAssertEqual(resolutions.first?.0, true)
        XCTAssertEqual(resolutions.first?.1, true)
        XCTAssertEqual(state.combat.player.reactorHP, 2)
        XCTAssertTrue(state.combat.enemyProjectiles.isEmpty)
    }

    func testEndlessCraftReferenceScoresStayInsideProvisionalBalanceBand() {
        var medians: [DescentShipKind: Int64] = [:]
        for ship in DescentShipKind.allCases {
            let scores = (0..<20).map { seed in
                endlessReferenceScore(seed: UInt64(seed), ticks: 14_400, shipKind: ship)
            }.sorted()
            medians[ship] = scores[scores.count / 2]
        }

        let values = Array(medians.values)
        let lowest = values.min() ?? 0
        let highest = values.max() ?? 0
        XCTAssertGreaterThan(lowest, 0, "medians: \(medians)")
        XCTAssertLessThanOrEqual(
            highest * 100,
            lowest * 135,
            "provisional two-minute score gap exceeded 35%: \(medians)"
        )
    }

    func testEndlessLevelBoundaryIsNonTerminalAtSevenThousandTwoHundred() {
        var state = quietEndlessState(seed: 7_200)
        state.combat.tick = 7_198

        let before = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.combat.tick, 7_199)
        XCTAssertEqual(state.level, 1)
        XCTAssertFalse(before.contains { if case .levelAdvanced = $0 { true } else { false } })

        let boundary = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.combat.tick, 7_200)
        XCTAssertEqual(state.level, 2)
        XCTAssertEqual(state.phase, .playing)
        XCTAssertEqual(state.combat.phase, .playing)
        XCTAssertNil(state.combat.endReason)
        XCTAssertFalse(state.combat.choiceArena.wasPresented)
        XCTAssertTrue(boundary.contains(.levelAdvanced(2)))
        XCTAssertFalse(boundary.contains { if case .finished = $0 { true } else { false } })

        _ = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.combat.tick, 7_201)
        XCTAssertEqual(state.level, 2)
        XCTAssertEqual(state.phase, .playing)
    }

    func testEndlessForcedCarriersRepeatAtStableLevelLocalTicks() {
        var first = quietEndlessState(seed: 919)
        first.combat.tick = 7_200 + 779
        let firstEvents = GameRules.stepDescentEndless(
            state: &first,
            input: DescentInput(targetXPoints: 195)
        )
        let firstCarrier = firstEvents.compactMap { event -> DescentObject? in
            guard case .combat(.objectSpawned(let object)) = event,
                  object.kind == .core else { return nil }
            return object
        }.first
        XCTAssertEqual(first.combat.tick, 7_200 + 780)
        XCTAssertNotNil(firstCarrier)
        XCTAssertLessThan(firstCarrier?.id ?? 0, 0)
        XCTAssertNotNil(firstCarrier?.dropKind)

        var replay = quietEndlessState(seed: 919)
        replay.combat.tick = 7_200 + 779
        let replayEvents = GameRules.stepDescentEndless(
            state: &replay,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(replayEvents, firstEvents)
        XCTAssertEqual(GameRules.descentEndlessChecksum(replay), GameRules.descentEndlessChecksum(first))

        var nextLevel = quietEndlessState(seed: 919)
        nextLevel.combat.tick = 14_400 + 779
        let nextEvents = GameRules.stepDescentEndless(
            state: &nextLevel,
            input: DescentInput(targetXPoints: 195)
        )
        let nextCarrier = nextEvents.compactMap { event -> DescentObject? in
            guard case .combat(.objectSpawned(let object)) = event,
                  object.kind == .core else { return nil }
            return object
        }.first
        XCTAssertNotEqual(nextCarrier?.id, firstCarrier?.id)
    }

    func testEndlessFatalCheckpointFreezesAfterTransactionAndDeclineIsIdempotent() {
        var state = fatalEndlessState(seed: 101)
        let events = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )

        XCTAssertEqual(state.phase, .awaitingRevive)
        XCTAssertEqual(state.combat.player.reactorHP, 0)
        XCTAssertEqual(state.combat.endReason, .reactorDestroyed)
        XCTAssertEqual(state.fatalCheckpoint?.combatChecksum, GameRules.descentChecksum(state.combat))
        XCTAssertEqual(state.fatalCheckpoint?.rankedClass, .clean)
        XCTAssertTrue(state.canSubmitFatalScoreToCleanLeaderboard)
        let breachIndex = events.firstIndex { if case .combat(.objectBreached) = $0 { true } else { false } }
        let checkpointIndex = events.firstIndex { if case .fatalCheckpoint = $0 { true } else { false } }
        XCTAssertNotNil(breachIndex)
        XCTAssertNotNil(checkpointIndex)
        if let breachIndex, let checkpointIndex {
            XCTAssertLessThan(breachIndex, checkpointIndex)
        }

        let frozen = state
        XCTAssertEqual(
            GameRules.stepDescentEndless(
                state: &state,
                input: DescentInput(targetXPoints: 39)
            ),
            []
        )
        XCTAssertEqual(state, frozen)
        XCTAssertEqual(GameRules.declineDescentEndlessRevive(state: &state), [.finished])
        XCTAssertEqual(state.phase, .finished)
        XCTAssertEqual(GameRules.declineDescentEndlessRevive(state: &state), [])
        XCTAssertTrue(state.canSubmitFatalScoreToCleanLeaderboard)
    }

    func testVerifiedMockReviveAppliesNextTickOnceAndPermanentlyMarksAssisted() {
        var state = fatalEndlessState(seed: 102)
        _ = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        let fatalTick = state.combat.tick
        let firstCheckpoint = state.fatalCheckpoint

        XCTAssertEqual(
            GameRules.scheduleVerifiedMockDescentEndlessRevive(state: &state, grantID: 55),
            [.reviveScheduled(grantID: 55, applyAtTick: fatalTick + 1)]
        )
        XCTAssertEqual(state.rankedClass, .assisted)
        XCTAssertEqual(state.revivesUsed, 1)
        XCTAssertFalse(state.canSubmitFatalScoreToCleanLeaderboard)
        XCTAssertEqual(GameRules.scheduleVerifiedMockDescentEndlessRevive(state: &state, grantID: 56), [])
        XCTAssertEqual(state.combat.tick, fatalTick)

        let resumed = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(resumed.first, .revived(grantID: 55, tick: fatalTick + 1))
        XCTAssertEqual(state.combat.tick, fatalTick + 1)
        XCTAssertEqual(state.combat.player.reactorHP, 1)
        XCTAssertEqual(state.phase, .playing)
        XCTAssertNil(state.pendingRevive)
        XCTAssertEqual(state.fatalCheckpoint, firstCheckpoint)

        state.combat.player.nextBreachDamageTick = 0
        state.combat.objects.append(
            object(id: 999, kind: .normal, lane: 0, y: GameRules.descentDangerY)
        )
        let secondFatal = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.phase, .finished)
        XCTAssertTrue(secondFatal.contains(.finished))
        XCTAssertEqual(state.revivesUsed, GameRules.descentEndlessMaximumRevives)
        XCTAssertEqual(GameRules.scheduleVerifiedMockDescentEndlessRevive(state: &state, grantID: 57), [])
        XCTAssertEqual(state.fatalCheckpoint, firstCheckpoint)
    }

    func testEndlessBoosterSnapshotIsImmutableAuthoritativeAndAssistedFromStart() {
        let coreSnapshot = DescentEndlessBoosterSnapshot(
            grantID: 700,
            kind: .startingCore(.electric)
        )
        var coreState = GameRules.initialDescentEndlessState(
            seed: 700,
            boosterSnapshot: coreSnapshot
        )
        XCTAssertEqual(coreState.boosterSnapshot, coreSnapshot)
        XCTAssertEqual(coreState.rankedClass, .assisted)
        XCTAssertEqual(coreState.combat.skills.levels.electric, 1)
        XCTAssertFalse(coreState.canSubmitFatalScoreToCleanLeaderboard)
        _ = GameRules.stepDescentEndless(
            state: &coreState,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(coreState.boosterSnapshot, coreSnapshot)

        let guardSnapshot = DescentEndlessBoosterSnapshot(grantID: 701, kind: .reactorGuard)
        let guardState = GameRules.initialDescentEndlessState(
            seed: 700,
            boosterSnapshot: guardSnapshot
        )
        XCTAssertEqual(guardState.combat.player.reactorHP, 4)
        XCTAssertEqual(guardState.rankedClass, .assisted)

        let clean = GameRules.initialDescentEndlessState(seed: 700)
        XCTAssertEqual(clean.rankedClass, .clean)
        XCTAssertNil(clean.boosterSnapshot)
    }

    func testEndlessChecksumCoversAssistanceCheckpointPendingGrantAndBoosterIdentity() {
        let baseline = quietEndlessState(seed: 103)
        let checksum = GameRules.descentEndlessChecksum(baseline)

        var ranked = baseline
        ranked.rankedClass = .assisted
        XCTAssertNotEqual(GameRules.descentEndlessChecksum(ranked), checksum)

        var checkpointed = baseline
        checkpointed.fatalCheckpoint = DescentEndlessFatalCheckpoint(
            tick: 1,
            score: 2,
            combatChecksum: 3,
            rankedClass: .clean
        )
        XCTAssertNotEqual(GameRules.descentEndlessChecksum(checkpointed), checksum)

        var pending = baseline
        pending.pendingRevive = DescentEndlessPendingRevive(grantID: 4, applyAtTick: 5)
        XCTAssertNotEqual(GameRules.descentEndlessChecksum(pending), checksum)

        var used = baseline
        used.revivesUsed = 1
        XCTAssertNotEqual(GameRules.descentEndlessChecksum(used), checksum)

        let boosterA = GameRules.initialDescentEndlessState(
            seed: 103,
            boosterSnapshot: .init(grantID: 10, kind: .reactorGuard)
        )
        let boosterB = GameRules.initialDescentEndlessState(
            seed: 103,
            boosterSnapshot: .init(grantID: 11, kind: .reactorGuard)
        )
        XCTAssertEqual(boosterA.combat, boosterB.combat)
        XCTAssertNotEqual(
            GameRules.descentEndlessChecksum(boosterA),
            GameRules.descentEndlessChecksum(boosterB)
        )
    }

    func testEndlessScoreSaturatesAtInt64MaximumWithoutWrapping() {
        var state = quietEndlessState(seed: 104)
        state.combat.tick = 10
        state.combat.score = Int64.max - 10
        state.combat.objects = [object(id: 1, kind: .normal, lane: 0, y: 200)]
        state.combat.projectiles = [projectile(id: 1, lane: 0, y: 194)]

        _ = GameRules.stepDescentEndless(
            state: &state,
            input: DescentInput(targetXPoints: 195)
        )
        XCTAssertEqual(state.combat.score, Int64.max)
        XCTAssertGreaterThanOrEqual(state.combat.score, 0)
    }

    func testEndlessStateEventsAndChecksumMatchThirtySixtyOneTwentyAndLargeBatches() {
        for shipKind in DescentShipKind.allCases {
            let oneTwenty = simulatedEndless(
                seed: 105,
                ticks: 7_201,
                batchSize: 1,
                shipKind: shipKind
            )
            for batchSize in [2, 4, 37] {
                let candidate = simulatedEndless(
                    seed: 105,
                    ticks: 7_201,
                    batchSize: batchSize,
                    shipKind: shipKind
                )
                XCTAssertEqual(candidate.state, oneTwenty.state, "\(shipKind), batch \(batchSize)")
                XCTAssertEqual(candidate.events, oneTwenty.events, "\(shipKind), batch \(batchSize)")
                XCTAssertEqual(
                    GameRules.descentEndlessChecksum(candidate.state),
                    GameRules.descentEndlessChecksum(oneTwenty.state)
                )
            }
            XCTAssertEqual(oneTwenty.state.combat.tick, 7_201)
            XCTAssertEqual(oneTwenty.state.level, 2)
            XCTAssertEqual(oneTwenty.state.phase, .playing)
            XCTAssertFalse(oneTwenty.state.combat.choiceArena.wasPresented)
        }
    }

    // MARK: - Helpers

    private func quietState(
        seed: UInt64,
        shipKind: DescentShipKind = .interceptor
    ) -> DescentState {
        var state = GameRules.initialDescentState(seed: seed, shipKind: shipKind)
        state.nextSpawnTick = .max
        state.forcedCarrierIndex = 3
        state.player.reactorHP = 10_000
        return state
    }

    private func quietEndlessState(
        seed: UInt64,
        shipKind: DescentShipKind = .interceptor
    ) -> DescentEndlessState {
        var state = GameRules.initialDescentEndlessState(seed: seed, shipKind: shipKind)
        state.combat.nextSpawnTick = .max
        state.combat.forcedCarrierIndex = 3
        state.combat.player.reactorHP = 10_000
        return state
    }

    private func fatalEndlessState(seed: UInt64) -> DescentEndlessState {
        var state = quietEndlessState(seed: seed)
        state.combat.player.reactorHP = 1
        state.combat.player.nextBreachDamageTick = 0
        state.combat.objects = [
            object(id: 800, kind: .normal, lane: 0, y: GameRules.descentDangerY)
        ]
        return state
    }

    private func simulatedEndless(
        seed: UInt64,
        ticks: Int,
        batchSize: Int,
        shipKind: DescentShipKind = .interceptor
    ) -> (state: DescentEndlessState, events: [DescentEndlessEvent]) {
        var state = quietEndlessState(seed: seed, shipKind: shipKind)
        var events: [DescentEndlessEvent] = []
        while state.combat.tick < ticks, state.phase == .playing {
            let count = min(batchSize, ticks - state.combat.tick)
            for _ in 0..<count {
                events.append(
                    contentsOf: GameRules.stepDescentEndless(
                        state: &state,
                        input: DescentInput(targetXPoints: 195)
                    )
                )
            }
        }
        return (state, events)
    }

    private func object(
        id: Int,
        kind: DescentObjectKind,
        lane: Int,
        y: Double,
        hitPoints: Int? = nil,
        fallPerTick: Double = 0,
        dropKind: DescentSkillKind? = nil,
        enemyAttackAtTick: Int? = nil
    ) -> DescentObject {
        let hp = hitPoints ?? kind.hitPoints
        return DescentObject(
            id: id,
            kind: kind,
            lane: lane,
            yQ: GameRules.descentQ(fromPoints: y),
            hitPoints: hp,
            maximumHitPoints: hp,
            fallSpeedQPerTick: GameRules.descentQ(fromPoints: fallPerTick),
            spawnedAtTick: 0,
            dropKind: dropKind,
            enemyAttackAtTick: enemyAttackAtTick
        )
    }

    private func electricTestObjects() -> [DescentObject] {
        [
            object(id: 1, kind: .armored, lane: 2, y: 200, hitPoints: 20),
            object(id: 2, kind: .armored, lane: 2, y: 202, hitPoints: 20),
            object(id: 3, kind: .armored, lane: 2, y: 204, hitPoints: 20),
            object(id: 4, kind: .armored, lane: 2, y: 206, hitPoints: 20),
            object(id: 5, kind: .armored, lane: 2, y: 208, hitPoints: 20),
            object(id: 6, kind: .armored, lane: 2, y: 210, hitPoints: 20),
            object(id: 7, kind: .armored, lane: 2, y: 212, hitPoints: 20),
            object(id: 8, kind: .armored, lane: 2, y: 214, hitPoints: 20)
        ]
    }

    private func electricTestProjectile(level: Int) -> DescentProjectile {
        var levels = DescentSkillLevels()
        levels.electric = level
        return DescentProjectile(
            id: 1,
            lane: 2,
            effectSnapshot: DescentProjectileEffectSnapshot(
                shotEventID: 1,
                loadoutVersion: level,
                dominantEffect: .electric,
                levels: levels
            ),
            yQ: GameRules.descentQ(fromPoints: 194),
            velocityQPerTick: GameRules.descentQ(fromPoints: 6.5),
            damage: 1,
            remainingHits: 1,
            hitObjectIDs: []
        )
    }

    private func endlessReferenceScore(
        seed: UInt64,
        ticks: Int,
        shipKind: DescentShipKind
    ) -> Int64 {
        var state = GameRules.initialDescentEndlessState(seed: seed, shipKind: shipKind)
        state.combat.player.reactorHP = 999
        let loadout = GameRules.descentEndlessLoadout(for: shipKind)
        while state.combat.tick < ticks, state.phase == .playing {
            let targetLane = referenceTargetLane(
                state.combat,
                fireIntervalTicks: loadout.fireIntervalTicks
            )
            _ = GameRules.stepDescentEndless(
                state: &state,
                input: DescentInput(
                    targetXPoints: GameRules.descentLaneXPoints[targetLane]
                )
            )
        }
        return state.combat.score
    }

    private func projectile(id: Int, lane: Int, y: Double) -> DescentProjectile {
        DescentProjectile(
            id: id,
            lane: lane,
            yQ: GameRules.descentQ(fromPoints: y),
            velocityQPerTick: GameRules.descentQ(fromPoints: 780.0 / 120.0),
            damage: 1,
            remainingHits: 1,
            hitObjectIDs: []
        )
    }

    private func blockingProjectiles(
        count: Int,
        missileKind: DescentMissileKind = .pulse
    ) -> [DescentProjectile] {
        (1...count).map {
            DescentProjectile(
                id: $0,
                lane: 0,
                missileKind: missileKind,
                yQ: 0,
                velocityQPerTick: 0,
                damage: 1,
                remainingHits: 1,
                hitObjectIDs: []
            )
        }
    }

    private func plannedPeakObjectCount(_ plan: [DescentSpawnPlanEntry]) -> Int {
        var changes: [(tick: Int, delta: Int)] = []
        let distancePoints = Int(GameRules.descentSpawnY - GameRules.descentDangerY)
        for entry in plan {
            let profile = GameRules.descentDifficulty(atTick: entry.tick)
            let denominator = profile.baseFallSpeed * entry.kind.fallSpeedPercent
            let numerator = distancePoints * GameRules.descentTickRate * 100
            let lifetime = (numerator + denominator - 1) / denominator
            changes.append((entry.tick, 1))
            changes.append((entry.tick + lifetime, -1))
        }
        changes.sort {
            if $0.tick != $1.tick { return $0.tick < $1.tick }
            return $0.delta > $1.delta
        }
        var active = 0
        var peak = 0
        for change in changes {
            active += change.delta
            peak = max(peak, active)
        }
        return peak
    }

    private func simulatedRun(
        seed: UInt64,
        batchSize: Int,
        reactorHP: Int = 10_000,
        shipKind: DescentShipKind = .interceptor,
        choice: DescentArenaChoice = .steady,
        preactivatedSkills: [DescentSkillKind] = []
    ) -> (state: DescentState, events: [DescentSimulationEvent]) {
        var state = GameRules.initialDescentState(seed: seed, shipKind: shipKind)
        state.player.reactorHP = reactorHP
        var events: [DescentSimulationEvent] = []
        for kind in preactivatedSkills {
            _ = GameRules.acquireDescentEffect(state: &state, kind: kind)
        }

        while state.tick < GameRules.descentRunDurationTicks, state.phase == .playing {
            let count = min(batchSize, GameRules.descentRunDurationTicks - state.tick)
            for _ in 0..<count {
                let targetLane = referenceTargetLane(state)
                events.append(contentsOf: GameRules.stepDescent(
                    state: &state,
                    input: DescentInput(
                        targetXPoints: GameRules.descentLaneXPoints[targetLane]
                    )
                ))
                if state.choiceArena.isAwaitingChoice {
                    events.append(contentsOf: GameRules.resolveDescentChoiceArena(
                        state: &state,
                        choice: choice
                    ))
                }
            }
        }
        return (state, events)
    }

    private func scriptedFrenzyRun(
        batchSize: Int
    ) -> (state: DescentState, events: [DescentSimulationEvent]) {
        var state = quietState(seed: 5_701)
        var events: [DescentSimulationEvent] = []
        let destructionTicks = Set(Array(100...107) + [120])
        let finalTick = 480

        while state.tick < finalTick {
            let count = min(batchSize, finalTick - state.tick)
            for _ in 0..<count {
                let nextTick = state.tick + 1
                if destructionTicks.contains(nextTick) {
                    state.objects.append(
                        object(
                            id: 10_000 + nextTick,
                            kind: .normal,
                            lane: 0,
                            y: 200
                        )
                    )
                    state.projectiles.append(
                        projectile(id: 20_000 + nextTick, lane: 0, y: 194)
                    )
                }
                events.append(contentsOf: GameRules.stepDescent(
                    state: &state,
                    input: DescentInput(targetXPoints: 195)
                ))
            }
        }
        return (state, events)
    }

    private func resolvedChoiceState(
        seed: UInt64,
        choice: DescentArenaChoice
    ) -> DescentState {
        var state = quietState(seed: seed)
        state.tick = 3_600
        _ = GameRules.presentDescentChoiceArena(state: &state)
        _ = GameRules.resolveDescentChoiceArena(state: &state, choice: choice)
        return state
    }

    private func referenceTargetLane(
        _ state: DescentState,
        fireIntervalTicks: Int = GameRules.descentAutoFireIntervalTicks
    ) -> Int {
        let dangerQ = GameRules.descentQ(fromPoints: GameRules.descentDangerY)
        let playerYQ = GameRules.descentQ(fromPoints: GameRules.descentPlayerY)
        let projectileDelta = GameRules.descentQ(fromPoints: 780.0 / 120.0)
        let windPercent = Int64(state.skills.windMultiplierPercent)

        let threat = state.objects.min { lhs, rhs in
            let left = threatSlack(
                lhs,
                dangerQ: dangerQ,
                playerYQ: playerYQ,
                projectileDelta: projectileDelta,
                windPercent: windPercent,
                fireIntervalTicks: fireIntervalTicks
            )
            let right = threatSlack(
                rhs,
                dangerQ: dangerQ,
                playerYQ: playerYQ,
                projectileDelta: projectileDelta,
                windPercent: windPercent,
                fireIntervalTicks: fireIntervalTicks
            )
            if left != right { return left < right }
            return lhs.id < rhs.id
        }
        let slack = threat.map {
            threatSlack(
                $0,
                dangerQ: dangerQ,
                playerYQ: playerYQ,
                projectileDelta: projectileDelta,
                windPercent: windPercent,
                fireIntervalTicks: fireIntervalTicks
            )
        } ?? .max

        if slack > 90,
           let drop = state.drops.min(by: {
               if $0.yQ != $1.yQ { return $0.yQ < $1.yQ }
               return $0.id < $1.id
           }) {
            return drop.lane
        }
        return threat?.lane ?? 2
    }

    private func threatSlack(
        _ object: DescentObject,
        dangerQ: Int64,
        playerYQ: Int64,
        projectileDelta: Int64,
        windPercent: Int64,
        fireIntervalTicks: Int
    ) -> Int64 {
        let fallDelta = max(1, object.fallSpeedQPerTick * windPercent / 100)
        let dangerTicks = max(0, object.yQ - dangerQ) / fallDelta
        let interceptTicks = max(0, object.yQ - playerYQ) / (projectileDelta + fallDelta)
        let followupTicks = Int64(max(0, object.hitPoints - 1) * fireIntervalTicks)
        return dangerTicks - interceptTicks - followupTicks
    }

    private func destroyedObjectID(_ event: DescentSimulationEvent) -> Int? {
        if case .objectDestroyed(id: let id, cause: _, points: _) = event { return id }
        return nil
    }

    private func destroyedPoints(_ event: DescentSimulationEvent) -> Int? {
        if case .objectDestroyed(id: _, cause: _, points: let points) = event { return points }
        return nil
    }

    private func spawnedDrop(_ event: DescentSimulationEvent) -> DescentDrop? {
        if case .dropSpawned(let drop) = event { return drop }
        return nil
    }

    private func breachedObject(_ event: DescentSimulationEvent) -> Bool {
        if case .objectBreached = event { return true }
        return false
    }

    private func damagingBreach(_ event: DescentSimulationEvent) -> Bool {
        if case .objectBreached(id: _, reactorDamaged: true) = event { return true }
        return false
    }

    private func activatedSkillLevel(_ event: DescentSimulationEvent) -> Int? {
        if case .skillActivated(kind: _, level: let level, activationID: _, targetIDs: _) = event {
            return level
        }
        return nil
    }

    private func activatedTargetIDs(_ event: DescentSimulationEvent) -> [Int]? {
        if case .skillActivated(kind: _, level: _, activationID: _, targetIDs: let ids) = event {
            return ids
        }
        return nil
    }
}
