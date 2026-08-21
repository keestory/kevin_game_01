import Foundation

extension GameRules {
    static let descentCoordinateScale: Int64 = 6_000
    static let descentTickRate = 120
    static let descentTickDuration = 1.0 / Double(descentTickRate)
    static let descentFieldWidth = 390.0
    static let descentFieldHeight = 844.0
    static let descentLaneXPoints = [39, 117, 195, 273, 351]
    static let descentPlayerY = 84.0
    static let descentDangerY = 128.0
    static let descentSpawnY = 738.0
    static let descentRunDurationTicks = 60 * descentTickRate
    static let descentAutoFireIntervalTicks = 22
    static let descentProjectileSpeed = 780
    static let descentMaximumPlayerSpeed = 900
    static let descentBreachCooldownTicks = 54
    static let descentMaximumObjects = 36
    static let descentMaximumProjectiles = 24
    static let descentMaximumDrops = 8
    static let descentMaximumEnemyProjectiles = 12
    static let descentFrenzyThreshold = 8
    static let descentFrenzyDurationTicks = 360
    static let descentFrenzyBonusPercent = 20
    static let descentEndlessLevelDurationTicks = 60 * descentTickRate
    static let descentEndlessMaximumRevives = 1
    static let descentEndlessBruteUnlockScore: Int64 = 4_000
    static let descentEndlessDroneAttackUnlockScore: Int64 = 10_000
    static let descentEnemyAttackTelegraphTicks = 90

    private static let descentDropSpeed = 160
    private static let descentPickupRadius = 34
    private static let descentComboGraceTicks = 192
    private static let descentDangerSaveDistance = 48
    private static let descentDangerSaveBonus = 150
    private static let descentForcedCarrierTicks = [780, 2_520, 4_380]
    private static let descentForcedObjectIDBase = 9_000_000
    private static let descentObjectSalt: UInt64 = 0xD35C_EA71_0B1E_C751
    private static let descentLaneSalt: UInt64 = 0x1A4E_5EED_427A_0193
    private static let descentDropSalt: UInt64 = 0xD20F_51A1_11C0_2026

    private struct DescentImpact {
        let projectileID: Int
        let objectID: Int
        let numerator: Int64
        let denominator: Int64
        let impactYQ: Int64
    }

    private struct DescentWaveResolution {
        var events: [DescentSimulationEvent]
        var comboAwardsRemaining: Int
    }

    static func descentPoints(fromQ value: Int64) -> Double {
        Double(value) / Double(descentCoordinateScale)
    }

    static func descentQ(fromPoints value: Double) -> Int64 {
        Int64((value * Double(descentCoordinateScale)).rounded())
    }

    static func descentLoadout(for shipKind: DescentShipKind) -> DescentLoadout {
        switch shipKind {
        case .interceptor:
            DescentLoadout(
                shipKind: shipKind,
                missileKind: .pulse,
                fireIntervalTicks: 22,
                projectilesPerVolley: 1,
                projectileSpeed: descentProjectileSpeed,
                damage: 1,
                maximumPlayerSpeed: descentMaximumPlayerSpeed,
                centerProjectileCarriesEffectsOnly: false
            )
        case .striker:
            DescentLoadout(
                shipKind: shipKind,
                missileKind: .lance,
                fireIntervalTicks: 44,
                projectilesPerVolley: 1,
                projectileSpeed: descentProjectileSpeed,
                damage: 2,
                maximumPlayerSpeed: descentMaximumPlayerSpeed,
                centerProjectileCarriesEffectsOnly: false
            )
        case .guardian:
            DescentLoadout(
                shipKind: shipKind,
                missileKind: .salvo,
                fireIntervalTicks: 66,
                projectilesPerVolley: 3,
                projectileSpeed: descentProjectileSpeed,
                damage: 1,
                maximumPlayerSpeed: descentMaximumPlayerSpeed,
                centerProjectileCarriesEffectsOnly: false
            )
        }
    }

    /// Ranked Endless v2 loadouts expose real trade-offs. The fast craft tracks
    /// priority threats, the striker converts mobility into burst damage, and
    /// the guardian trades single-lane DPS and elemental proc rate for coverage.
    static func descentEndlessLoadout(for shipKind: DescentShipKind) -> DescentLoadout {
        switch shipKind {
        case .interceptor:
            DescentLoadout(
                shipKind: shipKind,
                missileKind: .pulse,
                fireIntervalTicks: 24,
                projectilesPerVolley: 1,
                projectileSpeed: descentProjectileSpeed,
                damage: 2,
                maximumPlayerSpeed: 1_000,
                centerProjectileCarriesEffectsOnly: false
            )
        case .striker:
            DescentLoadout(
                shipKind: shipKind,
                missileKind: .lance,
                fireIntervalTicks: 32,
                projectilesPerVolley: 1,
                projectileSpeed: descentProjectileSpeed,
                damage: 5,
                maximumPlayerSpeed: 620,
                centerProjectileCarriesEffectsOnly: false
            )
        case .guardian:
            DescentLoadout(
                shipKind: shipKind,
                missileKind: .salvo,
                fireIntervalTicks: 36,
                projectilesPerVolley: 3,
                projectileSpeed: descentProjectileSpeed,
                damage: 2,
                maximumPlayerSpeed: 800,
                centerProjectileCarriesEffectsOnly: true
            )
        }
    }

    /// Returns stable, unique lane IDs for one authoritative volley. Guardian uses
    /// a three-lane sliding window at field edges so a boundary selection never
    /// produces overlapping projectiles or loses theoretical volley damage.
    static func descentVolleyLanes(
        centerLane: Int,
        shipKind: DescentShipKind
    ) -> [Int] {
        let boundedCenter = min(descentLaneXPoints.count - 1, max(0, centerLane))
        guard shipKind == .guardian else { return [boundedCenter] }
        let width = 3
        let start = min(
            max(0, boundedCenter - 1),
            descentLaneXPoints.count - width
        )
        return Array(start..<(start + width))
    }

    static func initialDescentState(
        seed: UInt64,
        shipKind: DescentShipKind = .interceptor
    ) -> DescentState {
        let centerX = descentQ(fromPoints: 195)
        return DescentState(
            seed: seed,
            shipKind: shipKind,
            tick: 0,
            player: DescentPlayerState(
                xQ: centerX,
                targetXQ: centerX,
                reactorHP: 3,
                nextBreachDamageTick: 0
            ),
            objects: [],
            projectiles: [],
            enemyProjectiles: [],
            drops: [],
            skills: DescentSkillState(),
            choiceArena: DescentChoiceArenaState(),
            frenzy: DescentFrenzyState(),
            nextObjectID: 1,
            nextProjectileID: 1,
            nextEnemyProjectileID: 1,
            nextShotEventID: 1,
            nextDropID: 1,
            spawnSequence: 0,
            nextSpawnTick: 1,
            forcedCarrierIndex: 0,
            score: 0,
            skillScore: 0,
            combo: 0,
            maxCombo: 0,
            lastDestructionTick: nil,
            dangerSaves: 0,
            peakObjectCount: 0,
            peakProjectileCount: 0,
            peakDropCount: 0,
            phase: .playing,
            endReason: nil
        )
    }

    static func descentDifficulty(atTick tick: Int) -> DescentDifficultyProfile {
        switch max(0, tick) {
        case 0..<(15 * descentTickRate):
            DescentDifficultyProfile(
                tier: 0,
                startTick: 0,
                baseFallSpeed: 72,
                spawnIntervalTicks: 180,
                pattern: .singleRain,
                objectCap: descentMaximumObjects,
                projectileCap: descentMaximumProjectiles,
                dropCap: descentMaximumDrops
            )
        case (15 * descentTickRate)..<(30 * descentTickRate):
            DescentDifficultyProfile(
                tier: 1,
                startTick: 15 * descentTickRate,
                baseFallSpeed: 84,
                spawnIntervalTicks: 144,
                pattern: .splitPair,
                objectCap: descentMaximumObjects,
                projectileCap: descentMaximumProjectiles,
                dropCap: descentMaximumDrops
            )
        case (30 * descentTickRate)..<(45 * descentTickRate):
            DescentDifficultyProfile(
                tier: 2,
                startTick: 30 * descentTickRate,
                baseFallSpeed: 98,
                spawnIntervalTicks: 114,
                pattern: .stairSequence,
                objectCap: descentMaximumObjects,
                projectileCap: descentMaximumProjectiles,
                dropCap: descentMaximumDrops
            )
        default:
            DescentDifficultyProfile(
                tier: 3,
                startTick: 45 * descentTickRate,
                baseFallSpeed: 112,
                spawnIntervalTicks: 98,
                pattern: .clusterGate,
                objectCap: descentMaximumObjects,
                projectileCap: descentMaximumProjectiles,
                dropCap: descentMaximumDrops
            )
        }
    }

    /// Level 1 is byte-for-byte the Revision 5 curve. From Level 2 onward only
    /// one pressure axis changes per transition: even levels tighten cadence,
    /// odd levels raise fall speed. Both axes are bounded for long-run safety.
    static func descentEndlessDifficulty(atTick tick: Int) -> DescentDifficultyProfile {
        let boundedTick = max(0, tick)
        let level = 1 + boundedTick / descentEndlessLevelDurationTicks
        guard level > 1 else { return descentDifficulty(atTick: boundedTick) }

        let speedSteps = min(6, max(0, (level - 1) / 2))
        let cadenceSteps = min(7, max(0, level / 2))
        return DescentDifficultyProfile(
            tier: descentSaturatingAdd(2, level),
            startTick: boundedTick - boundedTick % descentEndlessLevelDurationTicks,
            baseFallSpeed: 112 + speedSteps * 8,
            spawnIntervalTicks: max(72, 98 - cadenceSteps * 4),
            pattern: .clusterGate,
            objectCap: descentMaximumObjects,
            projectileCap: descentMaximumProjectiles,
            dropCap: descentMaximumDrops
        )
    }

    /// Score pressure rewards strong play, while the time floor prevents a
    /// player from deliberately avoiding score to freeze an easy run forever.
    static func descentEndlessThreatTier(score: Int64, tick: Int) -> Int {
        let scoreBand: Int = switch max(0, score) {
        case 0..<descentEndlessBruteUnlockScore: 0
        case descentEndlessBruteUnlockScore..<descentEndlessDroneAttackUnlockScore: 1
        case descentEndlessDroneAttackUnlockScore..<25_000: 2
        case 25_000..<50_000: 3
        default: 4
        }
        let boundedTick = max(0, tick)
        let timeBand: Int
        if boundedTick < 30 * descentTickRate {
            timeBand = 0
        } else if boundedTick < descentEndlessLevelDurationTicks {
            timeBand = 1
        } else {
            timeBand = min(6, 2 + boundedTick / descentEndlessLevelDurationTicks - 1)
        }
        return min(6, max(scoreBand, timeBand))
    }

    static func descentEndlessHitPoints(
        for kind: DescentObjectKind,
        threatTier: Int
    ) -> Int {
        let tier = min(6, max(0, threatTier))
        let hpStep = min(4, max(0, tier / 2))
        switch kind {
        case .normal: return min(8, 4 + hpStep)
        case .armored: return min(18, 10 + hpStep * 2)
        case .spike: return min(10, 6 + hpStep)
        case .drone: return min(12, 6 + hpStep)
        case .core: return min(8, 6 + hpStep / 2)
        case .brute: return min(32, 16 + max(0, tier - 1) * 4)
        }
    }

    static func descentEnemyAttackDelayTicks(objectID: Int, threatTier: Int) -> Int {
        let jitter = Int(descentHash(
            UInt64(truncatingIfNeeded: objectID)
                ^ UInt64(truncatingIfNeeded: threatTier)
                ^ 0xA77A_C4E2_2026_0821
        ) % 60)
        return 180 + jitter
    }

    static func descentSpawnPlan(
        seed: UInt64,
        durationTicks: Int = descentRunDurationTicks
    ) -> [DescentSpawnPlanEntry] {
        guard durationTicks > 0 else { return [] }
        var entries: [DescentSpawnPlanEntry] = []
        var nextTick = 1
        var sequence = 0
        var nextObjectID = 1

        while nextTick <= durationTicks {
            let profile = descentDifficulty(atTick: nextTick)
            let lanes = descentLanes(
                seed: seed,
                sequence: sequence,
                pattern: profile.pattern
            )
            for lane in lanes {
                let objectID = nextObjectID
                nextObjectID += 1
                entries.append(
                    DescentSpawnPlanEntry(
                        tick: nextTick,
                        objectID: objectID,
                        kind: descentRegularObjectKind(seed: seed, objectID: objectID),
                        lane: lane,
                        dropKind: nil
                    )
                )
            }
            sequence += 1
            nextTick += profile.spawnIntervalTicks
        }

        for (index, tick) in descentForcedCarrierTicks.enumerated() where tick <= durationTicks {
            let objectID = descentForcedObjectIDBase + index
            entries.append(
                DescentSpawnPlanEntry(
                    tick: tick,
                    objectID: objectID,
                    kind: .core,
                    lane: descentForcedCarrierLane(seed: seed, index: index),
                    dropKind: descentDropKind(seed: seed, objectID: objectID)
                )
            )
        }
        return entries.sorted {
            if $0.tick != $1.tick { return $0.tick < $1.tick }
            return $0.objectID < $1.objectID
        }
    }

    @discardableResult
    static func stepDescent(
        state: inout DescentState,
        input: DescentInput
    ) -> [DescentSimulationEvent] {
        guard state.phase == .playing,
              !state.choiceArena.isAwaitingChoice else { return [] }
        var events = stepDescentCombatTransaction(
            state: &state,
            input: input,
            frenzyRunEndTick: descentRunDurationTicks,
            usesEndlessRules: false
        )

        if state.phase == .playing, state.tick >= descentRunDurationTicks {
            state.phase = .finished
            state.endReason = .survivedSixtySeconds
            events.append(.finished(.survivedSixtySeconds))
        }
        if state.phase == .playing, state.tick == 30 * descentTickRate {
            events.append(contentsOf: presentDescentChoiceArena(state: &state))
        }
        return events
    }

    static func initialDescentEndlessState(
        seed: UInt64,
        shipKind: DescentShipKind = .interceptor,
        boosterSnapshot: DescentEndlessBoosterSnapshot? = nil
    ) -> DescentEndlessState {
        var combat = initialDescentState(seed: seed, shipKind: shipKind)
        if let boosterSnapshot {
            switch boosterSnapshot.kind {
            case .startingCore(let kind):
                _ = acquireDescentEffect(state: &combat, kind: kind)
            case .reactorGuard:
                combat.player.reactorHP += 1
            }
        }
        return DescentEndlessState(
            combat: combat,
            rankedClass: boosterSnapshot == nil ? .clean : .assisted,
            boosterSnapshot: boosterSnapshot,
            phase: .playing,
            fatalCheckpoint: nil,
            pendingRevive: nil,
            revivesUsed: 0
        )
    }

    /// Advances the additive Ranked Endless rules by exactly one authoritative
    /// tick. Unlike `stepDescent`, this path has no 60-second terminal and never
    /// presents Choice Arena. A verified revive is applied at the beginning of
    /// its scheduled next tick before combat resolution resumes.
    @discardableResult
    static func stepDescentEndless(
        state: inout DescentEndlessState,
        input: DescentInput
    ) -> [DescentEndlessEvent] {
        guard state.phase != .finished else { return [] }

        var events: [DescentEndlessEvent] = []
        if state.phase == .awaitingRevive {
            guard let pending = state.pendingRevive,
                  pending.applyAtTick == descentSaturatingAdd(state.combat.tick, 1),
                  state.combat.tick < Int.max else { return [] }
            state.pendingRevive = nil
            state.phase = .playing
            state.combat.phase = .playing
            state.combat.endReason = nil
            state.combat.player.reactorHP = max(1, state.combat.player.reactorHP)
            events.append(.revived(grantID: pending.grantID, tick: pending.applyAtTick))
        }

        guard state.phase == .playing, state.combat.tick < Int.max else {
            state.phase = .finished
            events.append(.finished)
            return events
        }

        let previousLevel = state.level
        let combatEvents = stepDescentCombatTransaction(
            state: &state.combat,
            input: input,
            frenzyRunEndTick: Int.max,
            usesEndlessRules: true
        )
        events.append(contentsOf: combatEvents.compactMap { event in
            if case .finished = event { return nil }
            return .combat(event)
        })

        if state.combat.endReason == .reactorDestroyed {
            let checkpoint = DescentEndlessFatalCheckpoint(
                tick: state.combat.tick,
                score: state.combat.score,
                combatChecksum: descentChecksum(state.combat),
                rankedClass: state.rankedClass
            )
            if state.fatalCheckpoint == nil {
                state.fatalCheckpoint = checkpoint
            }
            events.append(.fatalCheckpoint(checkpoint))
            if state.revivesUsed < descentEndlessMaximumRevives {
                state.phase = .awaitingRevive
            } else {
                state.phase = .finished
                events.append(.finished)
            }
            return events
        }

        if state.level != previousLevel {
            events.append(.levelAdvanced(state.level))
        }
        return events
    }

    /// Accepts only an already-verified local mock grant. The grant changes the
    /// ranked class immediately, but combat remains frozen until the next call
    /// to `stepDescentEndless`, when `applyAtTick` is processed exactly once.
    @discardableResult
    static func scheduleVerifiedMockDescentEndlessRevive(
        state: inout DescentEndlessState,
        grantID: UInt64
    ) -> [DescentEndlessEvent] {
        guard state.phase == .awaitingRevive,
              state.pendingRevive == nil,
              state.revivesUsed < descentEndlessMaximumRevives,
              state.combat.tick < Int.max else { return [] }
        let applyAtTick = state.combat.tick + 1
        state.pendingRevive = DescentEndlessPendingRevive(
            grantID: grantID,
            applyAtTick: applyAtTick
        )
        state.revivesUsed += 1
        state.rankedClass = .assisted
        return [.reviveScheduled(grantID: grantID, applyAtTick: applyAtTick)]
    }

    @discardableResult
    static func declineDescentEndlessRevive(
        state: inout DescentEndlessState
    ) -> [DescentEndlessEvent] {
        guard state.phase == .awaitingRevive,
              state.pendingRevive == nil else { return [] }
        state.phase = .finished
        return [.finished]
    }

    private static func stepDescentCombatTransaction(
        state: inout DescentState,
        input: DescentInput,
        frenzyRunEndTick: Int,
        usesEndlessRules: Bool
    ) -> [DescentSimulationEvent] {
        var events: [DescentSimulationEvent] = []
        state.tick += 1

        events.append(
            contentsOf: advanceDescentFrenzyClock(
                state: &state,
                runEndTick: frenzyRunEndTick
            )
        )
        moveDescentPlayer(
            state: &state,
            input: input,
            usesEndlessRules: usesEndlessRules
        )
        expireDescentSkills(state: &state)
        events.append(contentsOf: resolveDueFireEchoes(state: &state))

        let profile = usesEndlessRules
            ? descentEndlessDifficulty(atTick: state.tick)
            : descentDifficulty(atTick: state.tick)
        if state.tick == profile.startTick, state.tick > 0 {
            events.append(.difficultyAdvanced(profile))
        }
        events.append(
            contentsOf: spawnDescentObjects(
                state: &state,
                profile: profile,
                usesEndlessRules: usesEndlessRules
            )
        )
        events.append(
            contentsOf: fireDescentProjectileIfDue(
                state: &state,
                profile: profile,
                usesEndlessRules: usesEndlessRules
            )
        )
        events.append(
            contentsOf: resolveDescentProjectileImpacts(
                state: &state,
                frenzyRunEndTick: frenzyRunEndTick,
                usesEndlessRules: usesEndlessRules
            )
        )
        if usesEndlessRules, state.phase == .playing {
            events.append(contentsOf: advanceEnemyProjectiles(state: &state))
        }
        if state.phase == .playing {
            events.append(contentsOf: advanceObjectsAndResolveBreaches(state: &state))
        }
        if usesEndlessRules, state.phase == .playing {
            events.append(contentsOf: fireEnemyProjectilesIfDue(state: &state))
        }

        if state.phase == .playing {
            events.append(contentsOf: advanceDropsAndCollect(state: &state))
        }
        removeExpiredDescentEntities(state: &state)
        updateDescentPeaks(state: &state)
        return events
    }

    @discardableResult
    static func presentDescentChoiceArena(
        state: inout DescentState
    ) -> [DescentSimulationEvent] {
        guard state.phase == .playing,
              !state.choiceArena.wasPresented else { return [] }
        state.choiceArena.wasPresented = true
        state.choiceArena.isAwaitingChoice = true
        return [.choiceArenaPresented(tick: state.tick)]
    }

    @discardableResult
    static func resolveDescentChoiceArena(
        state: inout DescentState,
        choice: DescentArenaChoice
    ) -> [DescentSimulationEvent] {
        guard state.phase == .playing,
              state.choiceArena.wasPresented,
              state.choiceArena.isAwaitingChoice,
              state.choiceArena.selectedChoice == nil else { return [] }
        state.choiceArena.isAwaitingChoice = false
        state.choiceArena.selectedChoice = choice
        state.choiceArena.selectedAtTick = state.tick
        return [.choiceArenaResolved(choice)]
    }

    @discardableResult
    static func acquireDescentEffect(
        state: inout DescentState,
        kind: DescentSkillKind
    ) -> (level: Int, display: DescentEffectLevelDisplay) {
        let previousLevel = state.skills.levels.level(for: kind)
        let level = state.skills.levels.levelUp(kind)
        state.skills.loadoutVersion += 1
        state.skills.latestEffect = kind
        return (
            level,
            DescentEffectLevelDisplay.make(
                level: level,
                wasAlreadyMaximum: previousLevel == DescentSkillLevels.maximumRank
            )
        )
    }

    #if DEBUG
    /// Test-only compatibility fixture for Revision 3 expectations. Production
    /// persistent-effect gameplay never exposes or calls this direct activation path.
    @discardableResult
    static func testOnlyActivateLegacyDescentSkill(
        state: inout DescentState,
        kind: DescentSkillKind
    ) -> [DescentSimulationEvent] {
        let level = state.skills.levels.levelUp(kind)
        state.skills.activationCount += 1
        let activationID = state.skills.activationCount

        switch kind {
        case .fire:
            let limits = [3, 4, 5]
            let lane = descentNearestLane(toXQ: state.player.xQ)
            let targets = state.objects
                .filter { $0.lane == lane }
                .sorted {
                    if $0.yQ != $1.yQ { return $0.yQ < $1.yQ }
                    return $0.id < $1.id
                }
                .prefix(limits[level - 1])
                .map(\.id)
            var events: [DescentSimulationEvent] = [
                .skillActivated(
                    kind: kind,
                    level: level,
                    activationID: activationID,
                    targetIDs: targets
                )
            ]
            let primary = applyDescentSkillWave(
                state: &state,
                targetIDs: targets,
                damage: 1,
                cause: .skill(kind: kind, activationID: activationID),
                comboBudget: 3
            )
            events.append(contentsOf: primary.events)
            let echo = DescentPendingFireEcho(
                activationID: activationID,
                projectileID: 0,
                shotEventID: 0,
                triggerTick: state.tick + 60,
                targetIDs: targets,
                comboAwardsRemaining: primary.comboAwardsRemaining
            )
            state.skills.pendingFireEchoes.append(echo)
            state.skills.pendingFireEchoes.sort {
                if $0.triggerTick != $1.triggerTick { return $0.triggerTick < $1.triggerTick }
                return $0.activationID < $1.activationID
            }
            events.append(
                .fireEchoScheduled(
                    activationID: activationID,
                    triggerTick: echo.triggerTick,
                    targetIDs: targets
                )
            )
            return events

        case .electric:
            let limits = [3, 4, 5]
            let targets = state.objects.sorted {
                if $0.yQ != $1.yQ { return $0.yQ < $1.yQ }
                return $0.id < $1.id
            }
            .prefix(limits[level - 1])
            .map(\.id)
            var events: [DescentSimulationEvent] = [
                .skillActivated(
                    kind: kind,
                    level: level,
                    activationID: activationID,
                    targetIDs: targets
                )
            ]
            events.append(
                contentsOf: applyDescentSkillWave(
                    state: &state,
                    targetIDs: targets,
                    damage: 1,
                    cause: .skill(kind: kind, activationID: activationID),
                    comboBudget: 3
                ).events
            )
            return events

        case .pierce:
            let shotCounts = [8, 12, 16]
            let capacities = [2, 3, 4]
            state.skills.pierceShotsRemaining = max(
                state.skills.pierceShotsRemaining,
                shotCounts[level - 1]
            )
            state.skills.pierceHitCapacity = max(
                state.skills.pierceHitCapacity,
                capacities[level - 1]
            )
            state.skills.pierceExpiresTick = state.tick + 720
            return [
                .skillActivated(
                    kind: kind,
                    level: level,
                    activationID: activationID,
                    targetIDs: []
                )
            ]

        case .wind:
            let shifts = [48, 64, 80]
            let durations = [300, 360, 420]
            let multipliers = [70, 60, 50]
            for index in state.objects.indices {
                state.objects[index].yQ += descentQ(fromPoints: Double(shifts[level - 1]))
            }
            let activeLevel = state.tick < state.skills.windExpiresTick
                ? max(state.skills.windLevel, level)
                : level
            state.skills.windLevel = activeLevel
            state.skills.windMultiplierPercent = multipliers[activeLevel - 1]
            state.skills.windExpiresTick = state.tick + durations[activeLevel - 1]
            return [
                .skillActivated(
                    kind: kind,
                    level: level,
                    activationID: activationID,
                    targetIDs: state.objects.map(\.id).sorted()
                )
            ]

        case .explosion:
            let radii = [96, 112, 128]
            let damage = [2, 2, 3]
            let caps = [6, 7, 8]
            let lane = descentNearestLane(toXQ: state.player.xQ)
            guard let center = state.objects
                .filter({ $0.lane == lane })
                .min(by: {
                    if $0.yQ != $1.yQ { return $0.yQ < $1.yQ }
                    return $0.id < $1.id
                }) else {
                return [
                    .skillActivated(
                        kind: kind,
                        level: level,
                        activationID: activationID,
                        targetIDs: []
                    )
                ]
            }
            let radiusQ = descentQ(fromPoints: Double(radii[level - 1]))
            let targets = state.objects.compactMap { object -> (Int, Int64)? in
                let dx = descentLaneXQ(object.lane) - descentLaneXQ(center.lane)
                let dy = object.yQ - center.yQ
                let distanceSquared = dx * dx + dy * dy
                guard distanceSquared <= radiusQ * radiusQ else { return nil }
                return (object.id, distanceSquared)
            }
            .sorted {
                if $0.1 != $1.1 { return $0.1 < $1.1 }
                return $0.0 < $1.0
            }
            .prefix(caps[level - 1])
            .map(\.0)
            var events: [DescentSimulationEvent] = [
                .skillActivated(
                    kind: kind,
                    level: level,
                    activationID: activationID,
                    targetIDs: targets
                )
            ]
            events.append(
                contentsOf: applyDescentSkillWave(
                    state: &state,
                    targetIDs: targets,
                    damage: damage[level - 1],
                    cause: .skill(kind: kind, activationID: activationID),
                    comboBudget: 3
                ).events
            )
            return events
        }
    }
    #endif

    static func descentChecksum(_ state: DescentState) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ value: UInt64) {
            hash ^= value
            hash &*= 0x1000_0000_01b3
        }
        func mixInt(_ value: Int) { mix(UInt64(bitPattern: Int64(value))) }
        func mixInt64(_ value: Int64) { mix(UInt64(bitPattern: value)) }

        mix(state.seed)
        mixInt(state.shipKind.rawValue)
        mixInt(state.tick)
        mixInt64(state.player.xQ)
        mixInt64(state.player.targetXQ)
        mixInt(state.player.reactorHP)
        mixInt(state.player.nextBreachDamageTick)
        mixInt(state.nextObjectID)
        mixInt(state.nextProjectileID)
        mixInt(state.nextEnemyProjectileID)
        mixInt(state.nextShotEventID)
        mixInt(state.nextDropID)
        mixInt(state.spawnSequence)
        mixInt(state.nextSpawnTick)
        mixInt(state.forcedCarrierIndex)
        mix(UInt64(bitPattern: state.score))
        mix(UInt64(bitPattern: state.skillScore))
        mixInt(state.combo)
        mixInt(state.maxCombo)
        mixInt(state.lastDestructionTick ?? -1)
        mixInt(state.dangerSaves)
        mixInt(state.peakObjectCount)
        mixInt(state.peakProjectileCount)
        mixInt(state.peakDropCount)
        mixInt(state.skills.levels.fire)
        mixInt(state.skills.levels.electric)
        mixInt(state.skills.levels.pierce)
        mixInt(state.skills.levels.wind)
        mixInt(state.skills.levels.explosion)
        mixInt(state.skills.loadoutVersion)
        mixInt(state.skills.latestEffect?.rawValue ?? -1)
        mixInt(state.skills.activationCount)
        mixInt(state.skills.pierceShotsRemaining)
        mixInt(state.skills.pierceHitCapacity)
        mixInt(state.skills.pierceExpiresTick)
        mixInt(state.skills.windLevel)
        mixInt(state.skills.windMultiplierPercent)
        mixInt(state.skills.windExpiresTick)
        mixInt(state.choiceArena.wasPresented ? 1 : 0)
        mixInt(state.choiceArena.isAwaitingChoice ? 1 : 0)
        mixInt(state.choiceArena.selectedChoice?.rawValue ?? -1)
        mixInt(state.choiceArena.selectedAtTick ?? -1)
        mix(UInt64(bitPattern: state.choiceArena.redlineBonusScore))
        mixInt(state.frenzy.mode.rawValue)
        mixInt(state.frenzy.directChainCount)
        mixInt(state.frenzy.maxDirectChain)
        mixInt(state.frenzy.lastDirectDestructionTick ?? -1)
        mixInt(state.frenzy.pendingStartTick ?? -1)
        mixInt(state.frenzy.expiresAtTick ?? -1)
        mixInt(state.frenzy.activationCount)
        mixInt(state.frenzy.activeTickCount)
        mix(UInt64(bitPattern: state.frenzy.bonusScore))
        mixInt(state.phase == .playing ? 1 : (state.phase == .finished ? 2 : 0))
        mixInt(state.endReason.map { $0 == .reactorDestroyed ? 1 : 2 } ?? 0)

        for echo in state.skills.pendingFireEchoes.sorted(by: {
            if $0.triggerTick != $1.triggerTick { return $0.triggerTick < $1.triggerTick }
            return $0.activationID < $1.activationID
        }) {
            mixInt(echo.activationID)
            mixInt(echo.projectileID)
            mixInt(echo.shotEventID)
            mixInt(echo.triggerTick)
            mixInt(echo.comboAwardsRemaining)
            mixInt(echo.targetIDs.count)
            for id in echo.targetIDs.sorted() { mixInt(id) }
        }
        mixInt(state.skills.pendingFireEchoes.count)

        for object in state.objects.sorted(by: { $0.id < $1.id }) {
            mixInt(object.id)
            mixInt(object.kind.rawValue)
            mixInt(object.lane)
            mixInt64(object.yQ)
            mixInt(object.hitPoints)
            mixInt(object.maximumHitPoints)
            mixInt64(object.fallSpeedQPerTick)
            mixInt(object.spawnedAtTick)
            mixInt(object.dropKind?.rawValue ?? -1)
            mixInt(object.enemyAttackAtTick ?? -1)
        }
        mixInt(state.objects.count)

        for projectile in state.projectiles.sorted(by: { $0.id < $1.id }) {
            mixInt(projectile.id)
            mixInt(projectile.lane)
            mixInt(projectile.missileKind.rawValue)
            mixInt(projectile.effectSnapshot.shotEventID)
            mixInt(projectile.effectSnapshot.loadoutVersion)
            mixInt(projectile.effectSnapshot.dominantEffect?.rawValue ?? -1)
            mixInt(projectile.effectSnapshot.levels.fire)
            mixInt(projectile.effectSnapshot.levels.electric)
            mixInt(projectile.effectSnapshot.levels.pierce)
            mixInt(projectile.effectSnapshot.levels.wind)
            mixInt(projectile.effectSnapshot.levels.explosion)
            mixInt64(projectile.yQ)
            mixInt64(projectile.velocityQPerTick)
            mixInt(projectile.damage)
            mixInt(projectile.remainingHits)
            mixInt(projectile.hitObjectIDs.count)
            for id in projectile.hitObjectIDs.sorted() { mixInt(id) }
        }
        mixInt(state.projectiles.count)

        for projectile in state.enemyProjectiles.sorted(by: { $0.id < $1.id }) {
            mixInt(projectile.id)
            mixInt(projectile.sourceObjectID)
            mixInt(projectile.lane)
            mixInt64(projectile.yQ)
            mixInt64(projectile.velocityQPerTick)
            mixInt(projectile.damage)
            mixInt(projectile.spawnedAtTick)
        }
        mixInt(state.enemyProjectiles.count)

        for drop in state.drops.sorted(by: { $0.id < $1.id }) {
            mixInt(drop.id)
            mixInt(drop.sourceObjectID)
            mixInt(drop.kind.rawValue)
            mixInt(drop.lane)
            mixInt64(drop.yQ)
            mixInt(drop.spawnedAtTick)
        }
        mixInt(state.drops.count)
        return hash
    }

    static func descentEndlessChecksum(_ state: DescentEndlessState) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ value: UInt64) {
            hash ^= value
            hash &*= 0x1000_0000_01b3
        }
        func mixInt(_ value: Int) { mix(UInt64(bitPattern: Int64(value))) }

        mix(descentChecksum(state.combat))
        mixInt(state.level)
        mixInt(state.rankedClass.rawValue)
        mixInt(state.phase.rawValue)
        mixInt(state.revivesUsed)

        if let booster = state.boosterSnapshot {
            mix(booster.grantID)
            switch booster.kind {
            case .startingCore(let kind):
                mixInt(1)
                mixInt(kind.rawValue)
            case .reactorGuard:
                mixInt(2)
                mixInt(-1)
            }
        } else {
            mixInt(0)
        }

        if let checkpoint = state.fatalCheckpoint {
            mixInt(1)
            mixInt(checkpoint.tick)
            mix(UInt64(bitPattern: checkpoint.score))
            mix(checkpoint.combatChecksum)
            mixInt(checkpoint.rankedClass.rawValue)
        } else {
            mixInt(0)
        }

        if let pending = state.pendingRevive {
            mixInt(1)
            mix(pending.grantID)
            mixInt(pending.applyAtTick)
        } else {
            mixInt(0)
        }
        return hash
    }

    private static func moveDescentPlayer(
        state: inout DescentState,
        input: DescentInput,
        usesEndlessRules: Bool
    ) {
        let minimum = descentQ(fromPoints: Double(descentLaneXPoints[0]))
        let maximum = descentQ(fromPoints: Double(descentLaneXPoints[descentLaneXPoints.count - 1]))
        let target = min(
            maximum,
            max(minimum, descentQ(fromPoints: Double(input.targetXPoints)))
        )
        state.player.targetXQ = target
        let maximumSpeed = usesEndlessRules
            ? descentEndlessLoadout(for: state.shipKind).maximumPlayerSpeed
            : descentMaximumPlayerSpeed
        let maximumDelta = Int64(maximumSpeed) * descentCoordinateScale
            / Int64(descentTickRate)
        let delta = target - state.player.xQ
        state.player.xQ += min(maximumDelta, max(-maximumDelta, delta))
    }

    private static func expireDescentSkills(state: inout DescentState) {
        if state.tick >= state.skills.pierceExpiresTick {
            state.skills.pierceShotsRemaining = 0
            state.skills.pierceHitCapacity = 1
        }
        if state.tick >= state.skills.windExpiresTick {
            state.skills.windLevel = 0
            state.skills.windMultiplierPercent = 100
        }
    }

    private static func spawnDescentObjects(
        state: inout DescentState,
        profile: DescentDifficultyProfile,
        usesEndlessRules: Bool = false
    ) -> [DescentSimulationEvent] {
        var entries: [DescentSpawnPlanEntry] = []

        if state.forcedCarrierIndex < descentForcedCarrierTicks.count,
           state.tick == descentForcedCarrierTicks[state.forcedCarrierIndex] {
            let index = state.forcedCarrierIndex
            let objectID = descentForcedObjectIDBase + index
            entries.append(
                DescentSpawnPlanEntry(
                    tick: state.tick,
                    objectID: objectID,
                    kind: .core,
                    lane: descentForcedCarrierLane(seed: state.seed, index: index),
                    dropKind: descentDropKind(seed: state.seed, objectID: objectID)
                )
            )
            state.forcedCarrierIndex += 1
        }

        if usesEndlessRules, state.tick >= descentEndlessLevelDurationTicks {
            let localTick = state.tick % descentEndlessLevelDurationTicks
            if let index = descentForcedCarrierTicks.firstIndex(of: localTick) {
                let levelIndex = state.tick / descentEndlessLevelDurationTicks
                let ordinal = levelIndex * descentForcedCarrierTicks.count + index + 1
                entries.append(
                    DescentSpawnPlanEntry(
                        tick: state.tick,
                        objectID: -ordinal,
                        kind: .core,
                        lane: descentEndlessForcedCarrierLane(
                            seed: state.seed,
                            levelIndex: levelIndex,
                            index: index
                        ),
                        dropKind: descentEndlessDropKind(
                            seed: state.seed,
                            ordinal: ordinal
                        )
                    )
                )
            }
        }

        if state.tick == state.nextSpawnTick {
            let lanes = descentLanes(
                seed: state.seed,
                sequence: state.spawnSequence,
                pattern: profile.pattern
            )
            for lane in lanes {
                let objectID = state.nextObjectID
                state.nextObjectID += 1
                entries.append(
                    DescentSpawnPlanEntry(
                        tick: state.tick,
                        objectID: objectID,
                        kind: descentRegularObjectKind(
                            seed: state.seed,
                            objectID: objectID,
                            threatTier: usesEndlessRules
                                ? descentEndlessThreatTier(score: state.score, tick: state.tick)
                                : nil
                        ),
                        lane: lane,
                        dropKind: nil
                    )
                )
            }
            state.spawnSequence += 1
            state.nextSpawnTick += profile.spawnIntervalTicks
        }

        var events: [DescentSimulationEvent] = []
        for entry in entries.sorted(by: { $0.objectID < $1.objectID }) {
            guard state.objects.count < profile.objectCap else { continue }
            let object = makeDescentObject(
                entry: entry,
                profile: profile,
                threatTier: usesEndlessRules
                    ? descentEndlessThreatTier(score: state.score, tick: state.tick)
                    : nil
            )
            state.objects.append(object)
            events.append(.objectSpawned(object))
        }
        state.objects.sort { $0.id < $1.id }
        return events
    }

    private static func fireDescentProjectileIfDue(
        state: inout DescentState,
        profile: DescentDifficultyProfile,
        usesEndlessRules: Bool
    ) -> [DescentSimulationEvent] {
        let loadout = usesEndlessRules
            ? descentEndlessLoadout(for: state.shipKind)
            : descentLoadout(for: state.shipKind)
        let centerLane = descentNearestLane(toXQ: state.player.xQ)
        let lanes = descentVolleyLanes(centerLane: centerLane, shipKind: state.shipKind)
        guard state.tick.isMultiple(of: loadout.fireIntervalTicks),
              lanes.count == loadout.projectilesPerVolley,
              state.projectiles.count + lanes.count <= profile.projectileCap else { return [] }

        let snapshot = DescentProjectileEffectSnapshot(
            shotEventID: state.nextShotEventID,
            loadoutVersion: state.skills.loadoutVersion,
            dominantEffect: state.skills.latestEffect,
            levels: state.skills.levels
        )
        state.nextShotEventID += 1
        let pierceCapacities = [1, 3, 5, 7]
        let pierceCapacity = pierceCapacities[snapshot.levels.pierce]
        var fired: [DescentProjectile] = []
        for lane in lanes {
            let carriesEffects = !loadout.centerProjectileCarriesEffectsOnly
                || lane == centerLane
            let projectileSnapshot = carriesEffects ? snapshot : DescentProjectileEffectSnapshot(
                shotEventID: snapshot.shotEventID,
                loadoutVersion: snapshot.loadoutVersion,
                dominantEffect: nil,
                levels: DescentSkillLevels()
            )
            let receivesPierce = snapshot.levels.pierce > 0
                && (state.shipKind != .guardian || lane == centerLane)
            let projectile = DescentProjectile(
                id: state.nextProjectileID,
                lane: lane,
                missileKind: loadout.missileKind,
                effectSnapshot: projectileSnapshot,
                yQ: descentQ(fromPoints: descentPlayerY),
                velocityQPerTick: Int64(loadout.projectileSpeed) * descentCoordinateScale
                    / Int64(descentTickRate),
                damage: loadout.damage,
                remainingHits: receivesPierce ? pierceCapacity : 1,
                hitObjectIDs: []
            )
            state.nextProjectileID += 1
            state.projectiles.append(projectile)
            fired.append(projectile)
        }
        return fired.map(DescentSimulationEvent.projectileFired)
    }

    private static func resolveDescentProjectileImpacts(
        state: inout DescentState,
        frenzyRunEndTick: Int = descentRunDurationTicks,
        usesEndlessRules: Bool = false
    ) -> [DescentSimulationEvent] {
        var impacts: [DescentImpact] = []

        for projectile in state.projectiles where projectile.remainingHits > 0 {
            for object in state.objects where object.lane == projectile.lane {
                guard !projectile.hitObjectIDs.contains(object.id) else { continue }
                let objectDelta = descentObjectDelta(state: state, object: object)
                let separation = object.yQ - projectile.yQ
                let relativeDelta = projectile.velocityQPerTick + objectDelta
                guard separation >= 0, relativeDelta > 0, separation <= relativeDelta else { continue }
                let impactY = object.yQ - objectDelta * separation / relativeDelta
                impacts.append(
                    DescentImpact(
                        projectileID: projectile.id,
                        objectID: object.id,
                        numerator: separation,
                        denominator: relativeDelta,
                        impactYQ: impactY
                    )
                )
            }
        }
        impacts.sort(by: descentImpactSort)

        var events: [DescentSimulationEvent] = []
        for impact in impacts {
            guard let projectileIndex = state.projectiles.firstIndex(where: {
                $0.id == impact.projectileID && $0.remainingHits > 0
            }), state.objects.contains(where: { $0.id == impact.objectID }) else { continue }
            guard !state.projectiles[projectileIndex].hitObjectIDs.contains(impact.objectID) else {
                continue
            }
            let projectile = state.projectiles[projectileIndex]
            let isFirstImpact = projectile.hitObjectIDs.isEmpty
            state.projectiles[projectileIndex].hitObjectIDs.append(impact.objectID)
            state.projectiles[projectileIndex].remainingHits -= 1
            events.append(
                contentsOf: applyDescentDamage(
                    state: &state,
                    objectID: impact.objectID,
                    amount: projectile.damage,
                    cause: .projectile(id: impact.projectileID),
                    allowDrop: true,
                    allowCombo: true,
                    resolutionYQ: impact.impactYQ,
                    frenzyRunEndTick: frenzyRunEndTick
                ).events
            )
            events.append(
                contentsOf: applyPersistentProjectileEffects(
                    state: &state,
                    projectile: projectile,
                    directlyHitObjectID: impact.objectID,
                    impactLane: projectile.lane,
                    impactYQ: impact.impactYQ,
                    isFirstImpact: isFirstImpact,
                    usesEndlessRules: usesEndlessRules
                )
            )
        }

        for index in state.projectiles.indices {
            state.projectiles[index].yQ += state.projectiles[index].velocityQPerTick
        }
        state.projectiles.removeAll { $0.remainingHits <= 0 }
        return events
    }

    private static func applyPersistentProjectileEffects(
        state: inout DescentState,
        projectile: DescentProjectile,
        directlyHitObjectID: Int,
        impactLane: Int,
        impactYQ: Int64,
        isFirstImpact: Bool,
        usesEndlessRules: Bool
    ) -> [DescentSimulationEvent] {
        let levels = projectile.effectSnapshot.levels
        var events: [DescentSimulationEvent] = []

        if levels.fire > 0 {
            let delaysByLevel = [[], [60], [45, 90], [30, 60, 90]]
            for (index, delay) in delaysByLevel[levels.fire].enumerated() {
                state.skills.activationCount += 1
                let activationID = state.skills.activationCount
                let echo = DescentPendingFireEcho(
                    activationID: activationID,
                    projectileID: projectile.id,
                    shotEventID: projectile.effectSnapshot.shotEventID,
                    triggerTick: state.tick + delay,
                    targetIDs: [directlyHitObjectID],
                    comboAwardsRemaining: index == 0 ? 1 : 0
                )
                state.skills.pendingFireEchoes.append(echo)
                events.append(
                    .fireEchoScheduled(
                        activationID: activationID,
                        triggerTick: echo.triggerTick,
                        targetIDs: echo.targetIDs
                    )
                )
            }
        }

        if levels.electric > 0 {
            let secondaryIDs: [Int]
            if usesEndlessRules {
                let secondaryCaps = [0, 3, 5, 7]
                let radii = [0, 190, 225, 260]
                secondaryIDs = descentElectricChainTargets(
                    objects: state.objects,
                    excluding: directlyHitObjectID,
                    originLane: impactLane,
                    originYQ: impactYQ,
                    radiusPoints: radii[levels.electric],
                    cap: secondaryCaps[levels.electric]
                )
            } else {
                // Revision 5 remains byte-for-byte compatible at the rules
                // boundary: the direct target is included in the 3/4/5 cap
                // and secondary targets keep their legacy y/id ordering.
                let totalTargetCaps = [0, 3, 4, 5]
                secondaryIDs = state.objects
                    .filter { $0.id != directlyHitObjectID }
                    .sorted {
                        if $0.yQ != $1.yQ { return $0.yQ < $1.yQ }
                        return $0.id < $1.id
                    }
                    .prefix(max(0, totalTargetCaps[levels.electric] - 1))
                    .map(\.id)
            }
            state.skills.activationCount += 1
            let activationID = state.skills.activationCount
            events.append(
                .skillActivated(
                    kind: .electric,
                    level: levels.electric,
                    activationID: activationID,
                    targetIDs: [directlyHitObjectID] + secondaryIDs
                )
            )
            events.append(
                .skillCue(
                    DescentSkillActivationCue(
                        kind: .electric,
                        level: levels.electric,
                        activationID: activationID,
                        origin: DescentEffectPoint(
                            objectID: directlyHitObjectID,
                            xQ: descentLaneXQ(impactLane),
                            yQ: impactYQ
                        ),
                        targets: effectPoints(for: secondaryIDs, in: state.objects)
                    )
                )
            )
            events.append(
                contentsOf: applyDescentSkillWave(
                    state: &state,
                    targetIDs: secondaryIDs,
                    damage: 1,
                    cause: .skill(kind: .electric, activationID: activationID),
                    comboBudget: 1
                ).events
            )
        }

        if levels.wind > 0 {
            let radii = [0, 120, 150, 180]
            let shifts = [0, 12, 18, 24]
            let caps = [0, 3, 4, 5]
            let radiusQ = descentQ(fromPoints: Double(radii[levels.wind]))
            let centerXQ = descentLaneXQ(impactLane)
            let targets = state.objects.compactMap { object -> (id: Int, distance: Int64)? in
                let dx = descentLaneXQ(object.lane) - centerXQ
                let dy = object.yQ - impactYQ
                let distance = dx * dx + dy * dy
                guard distance <= radiusQ * radiusQ else { return nil }
                return (object.id, distance)
            }
            .sorted {
                if $0.distance != $1.distance { return $0.distance < $1.distance }
                return $0.id < $1.id
            }
            .prefix(caps[levels.wind])
            .map(\.id)
            let shiftQ = descentQ(fromPoints: Double(shifts[levels.wind]))
            let targetSet = Set(targets)
            for index in state.objects.indices where targetSet.contains(state.objects[index].id) {
                state.objects[index].yQ += shiftQ
            }
            // The visual stream must terminate at the same post-push position
            // as the authoritative object state.
            let targetPoints = effectPoints(for: targets, in: state.objects)
            state.skills.activationCount += 1
            events.append(
                .skillActivated(
                    kind: .wind,
                    level: levels.wind,
                    activationID: state.skills.activationCount,
                    targetIDs: targets
                )
            )
            events.append(
                .skillCue(
                    DescentSkillActivationCue(
                        kind: .wind,
                        level: levels.wind,
                        activationID: state.skills.activationCount,
                        origin: DescentEffectPoint(
                            objectID: directlyHitObjectID,
                            xQ: descentLaneXQ(impactLane),
                            yQ: impactYQ
                        ),
                        targets: targetPoints
                    )
                )
            )
        }

        if levels.explosion > 0, isFirstImpact {
            let radii = [0, 96, 112, 128]
            let damages = [0, 1, 1, 2]
            let caps = [0, 2, 3, 4]
            let radiusQ = descentQ(fromPoints: Double(radii[levels.explosion]))
            let centerXQ = descentLaneXQ(impactLane)
            let targets = state.objects.compactMap { object -> (id: Int, distance: Int64)? in
                guard object.id != directlyHitObjectID else { return nil }
                let dx = descentLaneXQ(object.lane) - centerXQ
                let dy = object.yQ - impactYQ
                let distance = dx * dx + dy * dy
                guard distance <= radiusQ * radiusQ else { return nil }
                return (object.id, distance)
            }
            .sorted {
                if $0.distance != $1.distance { return $0.distance < $1.distance }
                return $0.id < $1.id
            }
            .prefix(caps[levels.explosion])
            .map(\.id)
            state.skills.activationCount += 1
            let activationID = state.skills.activationCount
            events.append(
                .skillActivated(
                    kind: .explosion,
                    level: levels.explosion,
                    activationID: activationID,
                    targetIDs: [directlyHitObjectID] + targets
                )
            )
            events.append(
                contentsOf: applyDescentSkillWave(
                    state: &state,
                    targetIDs: targets,
                    damage: damages[levels.explosion],
                    cause: .skill(kind: .explosion, activationID: activationID),
                    comboBudget: 1
                ).events
            )
        }
        return events
    }

    private static func descentElectricChainTargets(
        objects: [DescentObject],
        excluding directlyHitObjectID: Int,
        originLane: Int,
        originYQ: Int64,
        radiusPoints: Int,
        cap: Int
    ) -> [Int] {
        guard cap > 0 else { return [] }
        let radiusQ = descentQ(fromPoints: Double(radiusPoints))
        var remaining = objects.filter { $0.id != directlyHitObjectID }
        var currentXQ = descentLaneXQ(originLane)
        var currentYQ = originYQ
        var result: [Int] = []

        while result.count < cap {
            let next = remaining.compactMap { object -> (object: DescentObject, distance: Int64)? in
                let dx = descentLaneXQ(object.lane) - currentXQ
                let dy = object.yQ - currentYQ
                let distance = dx * dx + dy * dy
                guard distance <= radiusQ * radiusQ else { return nil }
                return (object, distance)
            }
            .min {
                if $0.distance != $1.distance { return $0.distance < $1.distance }
                return $0.object.id < $1.object.id
            }
            guard let next else { break }
            result.append(next.object.id)
            currentXQ = descentLaneXQ(next.object.lane)
            currentYQ = next.object.yQ
            remaining.removeAll { $0.id == next.object.id }
        }
        return result
    }

    private static func effectPoints(
        for ids: [Int],
        in objects: [DescentObject]
    ) -> [DescentEffectPoint] {
        let byID = Dictionary(uniqueKeysWithValues: objects.map { ($0.id, $0) })
        return ids.compactMap { id in
            guard let object = byID[id] else { return nil }
            return DescentEffectPoint(
                objectID: id,
                xQ: descentLaneXQ(object.lane),
                yQ: object.yQ
            )
        }
    }

    private static func advanceEnemyProjectiles(
        state: inout DescentState
    ) -> [DescentSimulationEvent] {
        guard !state.enemyProjectiles.isEmpty else { return [] }
        let playerYQ = descentQ(fromPoints: descentPlayerY)
        let collisionRadiusQ = descentQ(fromPoints: 30)
        var resolved: [(id: Int, hitPlayer: Bool, damaged: Bool)] = []

        for index in state.enemyProjectiles.indices {
            let previousYQ = state.enemyProjectiles[index].yQ
            state.enemyProjectiles[index].yQ -= state.enemyProjectiles[index].velocityQPerTick
            let projectile = state.enemyProjectiles[index]
            guard previousYQ >= playerYQ, projectile.yQ <= playerYQ else { continue }
            let hitPlayer = abs(descentLaneXQ(projectile.lane) - state.player.xQ) <= collisionRadiusQ
            let canDamage = hitPlayer
                && state.tick >= state.player.nextBreachDamageTick
                && state.player.reactorHP > 0
            if canDamage {
                state.player.reactorHP -= projectile.damage
                state.player.reactorHP = max(0, state.player.reactorHP)
                state.player.nextBreachDamageTick = state.tick + descentBreachCooldownTicks
            }
            resolved.append((projectile.id, hitPlayer, canDamage))
        }

        let resolvedIDs = Set(resolved.map(\.id))
        state.enemyProjectiles.removeAll {
            resolvedIDs.contains($0.id) || $0.yQ < 0
        }

        var events: [DescentSimulationEvent] = []
        for resolution in resolved.sorted(by: { $0.id < $1.id }) {
            events.append(
                .enemyProjectileResolved(
                    id: resolution.id,
                    hitPlayer: resolution.hitPlayer,
                    reactorDamaged: resolution.damaged
                )
            )
            if resolution.damaged {
                events.append(.reactorChanged(state.player.reactorHP))
            }
        }
        if state.player.reactorHP == 0, state.phase == .playing {
            state.phase = .finished
            state.endReason = .reactorDestroyed
            events.append(.finished(.reactorDestroyed))
        }
        return events
    }

    private static func fireEnemyProjectilesIfDue(
        state: inout DescentState
    ) -> [DescentSimulationEvent] {
        guard state.enemyProjectiles.count < descentMaximumEnemyProjectiles else { return [] }
        let dueIDs = state.objects
            .filter { $0.kind == .drone && $0.enemyAttackAtTick == state.tick }
            .map(\.id)
            .sorted()
        guard !dueIDs.isEmpty else { return [] }

        let threatTier = descentEndlessThreatTier(score: state.score, tick: state.tick)
        let speed = min(440, 300 + threatTier * 20)
        var events: [DescentSimulationEvent] = []
        for objectID in dueIDs {
            guard state.enemyProjectiles.count < descentMaximumEnemyProjectiles,
                  let objectIndex = state.objects.firstIndex(where: { $0.id == objectID }) else {
                break
            }
            let object = state.objects[objectIndex]
            let targetLane = descentNearestLane(toXQ: state.player.xQ)
            let projectile = DescentEnemyProjectile(
                id: state.nextEnemyProjectileID,
                sourceObjectID: object.id,
                lane: targetLane,
                yQ: object.yQ,
                velocityQPerTick: Int64(speed) * descentCoordinateScale
                    / Int64(descentTickRate),
                damage: 1,
                spawnedAtTick: state.tick
            )
            state.nextEnemyProjectileID += 1
            state.objects[objectIndex].enemyAttackAtTick = nil
            state.enemyProjectiles.append(projectile)
            events.append(.enemyProjectileFired(projectile))
        }
        state.enemyProjectiles.sort { $0.id < $1.id }
        return events
    }

    private static func advanceObjectsAndResolveBreaches(
        state: inout DescentState
    ) -> [DescentSimulationEvent] {
        for index in state.objects.indices {
            let objectDelta = descentObjectDelta(
                state: state,
                object: state.objects[index]
            )
            state.objects[index].yQ -= objectDelta
        }

        let dangerQ = descentQ(fromPoints: descentDangerY)
        let breachedIDs = state.objects
            .filter { $0.yQ <= dangerQ }
            .map(\.id)
            .sorted()
        guard !breachedIDs.isEmpty else { return [] }

        var events: [DescentSimulationEvent] = []
        for objectID in breachedIDs {
            guard let index = state.objects.firstIndex(where: { $0.id == objectID }) else { continue }
            state.objects.remove(at: index)
            let damaged = state.tick >= state.player.nextBreachDamageTick
                && state.player.reactorHP > 0
            if damaged {
                state.player.reactorHP -= 1
                state.player.nextBreachDamageTick = state.tick + descentBreachCooldownTicks
                events.append(.reactorChanged(state.player.reactorHP))
            }
            if state.combo != 0 {
                state.combo = 0
                events.append(.comboChanged(0))
            }
            state.lastDestructionTick = nil
            events.append(.objectBreached(id: objectID, reactorDamaged: damaged))
        }

        if state.player.reactorHP == 0, state.phase == .playing {
            state.phase = .finished
            state.endReason = .reactorDestroyed
            events.append(.finished(.reactorDestroyed))
        }
        return events
    }

    private static func advanceDropsAndCollect(
        state: inout DescentState
    ) -> [DescentSimulationEvent] {
        let dropDelta = Int64(descentDropSpeed) * descentCoordinateScale
            / Int64(descentTickRate)
        let playerYQ = descentQ(fromPoints: descentPlayerY)
        let pickupRadiusQ = descentQ(fromPoints: Double(descentPickupRadius))
        let eligibleIDs = state.drops
            .filter { state.tick > $0.spawnedAtTick }
            .map(\.id)
            .sorted()
        var events: [DescentSimulationEvent] = []

        for dropID in eligibleIDs {
            guard let index = state.drops.firstIndex(where: { $0.id == dropID }) else { continue }
            state.drops[index].yQ -= dropDelta
            let dx = descentLaneXQ(state.drops[index].lane) - state.player.xQ
            let dy = state.drops[index].yQ - playerYQ
            guard dx * dx + dy * dy <= pickupRadiusQ * pickupRadiusQ else { continue }
            let drop = state.drops.remove(at: index)
            let acquisition = acquireDescentEffect(
                state: &state,
                kind: drop.kind
            )
            events.append(
                .dropCollected(
                    id: drop.id,
                    kind: drop.kind,
                    level: acquisition.level,
                    display: acquisition.display,
                    loadoutVersion: state.skills.loadoutVersion
                )
            )
        }
        return events
    }

    private static func resolveDueFireEchoes(
        state: inout DescentState
    ) -> [DescentSimulationEvent] {
        let due = state.skills.pendingFireEchoes.filter { $0.triggerTick <= state.tick }
            .sorted {
                if $0.triggerTick != $1.triggerTick { return $0.triggerTick < $1.triggerTick }
                return $0.activationID < $1.activationID
            }
        guard !due.isEmpty else { return [] }
        let dueIDs = Set(due.map(\.activationID))
        state.skills.pendingFireEchoes.removeAll { dueIDs.contains($0.activationID) }

        var events: [DescentSimulationEvent] = []
        for echo in due {
            events.append(
                .fireEchoActivated(
                    activationID: echo.activationID,
                    targetIDs: echo.targetIDs
                )
            )
            events.append(
                contentsOf: applyDescentSkillWave(
                    state: &state,
                    targetIDs: echo.targetIDs,
                    damage: 1,
                    cause: .fireEcho(activationID: echo.activationID),
                    comboBudget: echo.comboAwardsRemaining
                ).events
            )
        }
        return events
    }

    private static func applyDescentSkillWave(
        state: inout DescentState,
        targetIDs: [Int],
        damage: Int,
        cause: DescentDamageCause,
        comboBudget: Int
    ) -> DescentWaveResolution {
        var events: [DescentSimulationEvent] = []
        var remaining = max(0, comboBudget)
        for targetID in targetIDs {
            guard let object = state.objects.first(where: { $0.id == targetID }) else { continue }
            let result = applyDescentDamage(
                state: &state,
                objectID: targetID,
                amount: damage,
                cause: cause,
                allowDrop: false,
                allowCombo: remaining > 0,
                resolutionYQ: object.yQ
            )
            events.append(contentsOf: result.events)
            if result.didDestroy, remaining > 0 { remaining -= 1 }
        }
        return DescentWaveResolution(events: events, comboAwardsRemaining: remaining)
    }

    private static func advanceDescentFrenzyClock(
        state: inout DescentState,
        runEndTick: Int = descentRunDurationTicks
    ) -> [DescentSimulationEvent] {
        var events: [DescentSimulationEvent] = []

        if state.frenzy.mode == .frenzy,
           let expiresAtTick = state.frenzy.expiresAtTick,
           state.tick >= expiresAtTick {
            let activationID = state.frenzy.activationCount
            state.frenzy.mode = .calm
            state.frenzy.directChainCount = 0
            state.frenzy.lastDirectDestructionTick = nil
            state.frenzy.expiresAtTick = nil
            events.append(.frenzyEnded(activationID: activationID))
        }

        if state.frenzy.mode == .calm,
           let pendingStartTick = state.frenzy.pendingStartTick,
           state.tick >= pendingStartTick {
            state.frenzy.pendingStartTick = nil
            state.frenzy.directChainCount = 0
            state.frenzy.lastDirectDestructionTick = nil

            let expiresAtTick = min(
                descentSaturatingAdd(state.tick, descentFrenzyDurationTicks),
                runEndTick
            )
            guard expiresAtTick > state.tick else { return events }

            state.frenzy.mode = .frenzy
            state.frenzy.activationCount += 1
            state.frenzy.expiresAtTick = expiresAtTick
            events.append(
                .frenzyStarted(
                    activationID: state.frenzy.activationCount,
                    expiresAtTick: expiresAtTick
                )
            )
        }
        if state.frenzy.mode == .frenzy {
            state.frenzy.activeTickCount += 1
        }
        return events
    }

    private static func recordDescentDirectDestruction(
        state: inout DescentState,
        runEndTick: Int = descentRunDurationTicks
    ) -> [DescentSimulationEvent] {
        if state.frenzy.mode == .frenzy {
            let previousExpiry = state.frenzy.expiresAtTick ?? state.tick
            let refreshedExpiry = min(
                descentSaturatingAdd(state.tick, descentFrenzyDurationTicks),
                runEndTick
            )
            guard refreshedExpiry > previousExpiry else { return [] }
            state.frenzy.expiresAtTick = refreshedExpiry
            return [
                .frenzyExtended(
                    activationID: state.frenzy.activationCount,
                    expiresAtTick: refreshedExpiry
                )
            ]
        }

        let isWithinChainWindow: Bool
        if let lastTick = state.frenzy.lastDirectDestructionTick {
            isWithinChainWindow = state.tick - lastTick <= descentComboGraceTicks
        } else {
            isWithinChainWindow = false
        }
        let nextCount = isWithinChainWindow
            ? min(descentFrenzyThreshold, state.frenzy.directChainCount + 1)
            : 1
        state.frenzy.lastDirectDestructionTick = state.tick

        var events: [DescentSimulationEvent] = []
        if nextCount != state.frenzy.directChainCount {
            state.frenzy.directChainCount = nextCount
            events.append(.frenzyChargeChanged(nextCount))
        }
        state.frenzy.maxDirectChain = max(state.frenzy.maxDirectChain, nextCount)
        if nextCount >= descentFrenzyThreshold,
           state.frenzy.pendingStartTick == nil,
           state.tick < runEndTick {
            state.frenzy.pendingStartTick = descentSaturatingAdd(state.tick, 1)
        }
        return events
    }

    private static func applyDescentDamage(
        state: inout DescentState,
        objectID: Int,
        amount: Int,
        cause: DescentDamageCause,
        allowDrop: Bool,
        allowCombo: Bool,
        resolutionYQ: Int64,
        frenzyRunEndTick: Int = descentRunDurationTicks
    ) -> (events: [DescentSimulationEvent], didDestroy: Bool) {
        guard amount > 0,
              let index = state.objects.firstIndex(where: { $0.id == objectID }) else {
            return ([], false)
        }
        state.objects[index].hitPoints = max(0, state.objects[index].hitPoints - amount)
        var events: [DescentSimulationEvent] = [
            .objectDamaged(
                id: objectID,
                remainingHitPoints: state.objects[index].hitPoints,
                cause: cause
            )
        ]
        guard state.objects[index].hitPoints == 0 else { return (events, false) }

        let object = state.objects.remove(at: index)
        if allowCombo {
            if let last = state.lastDestructionTick,
               state.tick - last <= descentComboGraceTicks {
                state.combo += 1
            } else {
                state.combo = 1
            }
            state.maxCombo = max(state.maxCombo, state.combo)
            events.append(.comboChanged(state.combo))
        }
        state.lastDestructionTick = state.tick

        let multiplierTenths = min(20, 10 + state.combo / 5)
        let baseComboPoints = object.kind.baseScore * multiplierTenths / 10
        let isDirectProjectile: Bool
        if case .projectile = cause {
            isDirectProjectile = true
        } else {
            isDirectProjectile = false
        }
        var points = baseComboPoints
        if isDirectProjectile, descentRedlineIsActive(state) {
            let redlinePoints = baseComboPoints * 135 / 100
            state.choiceArena.redlineBonusScore = descentSaturatingAdd(
                state.choiceArena.redlineBonusScore,
                Int64(redlinePoints - baseComboPoints)
            )
            points = redlinePoints
        }
        if isDirectProjectile, state.frenzy.mode == .frenzy {
            let bonus = baseComboPoints * descentFrenzyBonusPercent / 100
            points += bonus
            state.frenzy.bonusScore = descentSaturatingAdd(
                state.frenzy.bonusScore,
                Int64(bonus)
            )
            events.append(.frenzyBonus(objectID: objectID, points: bonus))
        }
        let dangerSaveQ = descentQ(
            fromPoints: descentDangerY + Double(descentDangerSaveDistance)
        )
        if resolutionYQ <= dangerSaveQ {
            state.dangerSaves += 1
            points += descentDangerSaveBonus
            events.append(.dangerSave(id: objectID, bonus: descentDangerSaveBonus))
        }
        state.score = descentSaturatingAdd(state.score, Int64(points))
        if isDirectProjectile {
            // Direct auto-fire destruction is the only drop-producing cause.
        } else {
            state.skillScore = descentSaturatingAdd(state.skillScore, Int64(points))
        }
        events.append(.objectDestroyed(id: objectID, cause: cause, points: points))
        if isDirectProjectile {
            events.append(
                contentsOf: recordDescentDirectDestruction(
                    state: &state,
                    runEndTick: frenzyRunEndTick
                )
            )
        }

        if allowDrop,
           let kind = object.dropKind,
           state.drops.count < descentMaximumDrops {
            let drop = DescentDrop(
                id: state.nextDropID,
                sourceObjectID: object.id,
                kind: kind,
                lane: object.lane,
                yQ: resolutionYQ,
                spawnedAtTick: state.tick
            )
            state.nextDropID += 1
            state.drops.append(drop)
            events.append(.dropSpawned(drop))
        }
        return (events, true)
    }

    private static func removeExpiredDescentEntities(state: inout DescentState) {
        let fieldTopQ = descentQ(fromPoints: descentFieldHeight)
        state.projectiles.removeAll { $0.yQ > fieldTopQ }
        state.drops.removeAll { $0.yQ < 0 }
    }

    private static func updateDescentPeaks(state: inout DescentState) {
        state.peakObjectCount = max(state.peakObjectCount, state.objects.count)
        state.peakProjectileCount = max(state.peakProjectileCount, state.projectiles.count)
        state.peakDropCount = max(state.peakDropCount, state.drops.count)
    }

    private static func descentRedlineIsActive(_ state: DescentState) -> Bool {
        guard state.choiceArena.selectedChoice == .redline,
              let selectedAtTick = state.choiceArena.selectedAtTick else { return false }
        return state.tick > selectedAtTick
    }

    private static func descentObjectDelta(
        state: DescentState,
        object: DescentObject
    ) -> Int64 {
        let redlineAdjusted = descentRedlineIsActive(state)
            ? object.fallSpeedQPerTick * 118 / 100
            : object.fallSpeedQPerTick
        return redlineAdjusted * Int64(state.skills.windMultiplierPercent) / 100
    }

    private static func makeDescentObject(
        entry: DescentSpawnPlanEntry,
        profile: DescentDifficultyProfile,
        threatTier: Int? = nil
    ) -> DescentObject {
        let hitPoints = threatTier.map {
            descentEndlessHitPoints(for: entry.kind, threatTier: $0)
        } ?? entry.kind.hitPoints
        let attackAtTick: Int? = if let threatTier,
            threatTier >= 2,
            entry.kind == .drone {
            entry.tick + descentEnemyAttackDelayTicks(
                objectID: entry.objectID,
                threatTier: threatTier
            )
        } else {
            nil
        }
        return DescentObject(
            id: entry.objectID,
            kind: entry.kind,
            lane: entry.lane,
            yQ: descentQ(fromPoints: descentSpawnY),
            hitPoints: hitPoints,
            maximumHitPoints: hitPoints,
            fallSpeedQPerTick: Int64(profile.baseFallSpeed)
                * Int64(entry.kind.fallSpeedPercent)
                * descentCoordinateScale
                / (100 * Int64(descentTickRate)),
            spawnedAtTick: entry.tick,
            dropKind: entry.dropKind,
            enemyAttackAtTick: attackAtTick
        )
    }

    private static func descentLanes(
        seed: UInt64,
        sequence: Int,
        pattern: DescentSpawnPattern
    ) -> [Int] {
        let hash = descentHash(
            seed
                ^ descentLaneSalt
                ^ (UInt64(truncatingIfNeeded: sequence) &* 0x9E37_79B9_7F4A_7C15)
        )
        let base = Int(hash % UInt64(descentLaneXPoints.count))
        switch pattern {
        case .singleRain:
            return [base]
        case .splitPair:
            return [base, (base + 2) % descentLaneXPoints.count].sorted()
        case .stairSequence:
            return [base, (base + 1) % descentLaneXPoints.count].sorted()
        case .clusterGate:
            return [
                base,
                (base + 1) % descentLaneXPoints.count,
                (base + 2) % descentLaneXPoints.count
            ].sorted()
        }
    }

    private static func descentRegularObjectKind(
        seed: UInt64,
        objectID: Int,
        threatTier: Int? = nil
    ) -> DescentObjectKind {
        let hash = descentHash(
            seed
                ^ descentObjectSalt
                ^ (UInt64(truncatingIfNeeded: objectID) &* 0xBF58_476D_1CE4_E5B9)
        )
        if let threatTier, threatTier >= 1 {
            let bruteChance = min(20, 8 + threatTier * 2)
            if Int(hash % 100) < bruteChance { return .brute }
        }
        // Normal objects remain the visual and DPS baseline. The heavier roles
        // are deterministic but intentionally bounded so a no-ad run never
        // depends on obtaining a particular skill rotation.
        switch Int(hash % 20) {
        case 0..<10: return .normal
        case 10..<13: return .armored
        case 13..<17: return .spike
        default: return .drone
        }
    }

    private static func descentForcedCarrierLane(seed: UInt64, index: Int) -> Int {
        let hash = descentHash(
            seed
                ^ descentLaneSalt
                ^ (UInt64(index + 1) &* 0x94D0_49BB_1331_11EB)
        )
        return Int(hash % UInt64(descentLaneXPoints.count))
    }

    private static func descentEndlessForcedCarrierLane(
        seed: UInt64,
        levelIndex: Int,
        index: Int
    ) -> Int {
        let ordinal = levelIndex * descentForcedCarrierTicks.count + index + 1
        let hash = descentHash(
            seed
                ^ descentLaneSalt
                ^ (UInt64(truncatingIfNeeded: ordinal) &* 0x94D0_49BB_1331_11EB)
        )
        return Int(hash % UInt64(descentLaneXPoints.count))
    }

    private static func descentDropKind(
        seed: UInt64,
        objectID: Int
    ) -> DescentSkillKind {
        let rotation = Int(descentHash(seed ^ descentDropSalt) % 5)
        let ordinal = max(0, objectID - descentForcedObjectIDBase)
        return DescentSkillKind(rawValue: (rotation + ordinal) % 5) ?? .fire
    }

    private static func descentEndlessDropKind(
        seed: UInt64,
        ordinal: Int
    ) -> DescentSkillKind {
        let rotation = Int(descentHash(seed ^ descentDropSalt) % 5)
        return DescentSkillKind(
            rawValue: (rotation + max(0, ordinal - 1)) % DescentSkillKind.allCases.count
        ) ?? .fire
    }

    private static func descentHash(_ input: UInt64) -> UInt64 {
        var value = input &+ 0x9E37_79B9_7F4A_7C15
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    private static func descentSaturatingAdd(_ lhs: Int, _ rhs: Int) -> Int {
        let (value, overflow) = lhs.addingReportingOverflow(rhs)
        guard overflow else { return value }
        return rhs >= 0 ? Int.max : Int.min
    }

    private static func descentSaturatingAdd(_ lhs: Int64, _ rhs: Int64) -> Int64 {
        let (value, overflow) = lhs.addingReportingOverflow(rhs)
        guard overflow else { return value }
        return rhs >= 0 ? Int64.max : Int64.min
    }

    private static func descentNearestLane(toXQ xQ: Int64) -> Int {
        descentLaneXPoints.indices.min { lhs, rhs in
            let left = abs(descentLaneXQ(lhs) - xQ)
            let right = abs(descentLaneXQ(rhs) - xQ)
            if left != right { return left < right }
            return lhs < rhs
        } ?? 2
    }

    private static func descentLaneXQ(_ lane: Int) -> Int64 {
        let bounded = min(descentLaneXPoints.count - 1, max(0, lane))
        return descentQ(fromPoints: Double(descentLaneXPoints[bounded]))
    }

    private static func descentImpactSort(_ lhs: DescentImpact, _ rhs: DescentImpact) -> Bool {
        let left = lhs.numerator * rhs.denominator
        let right = rhs.numerator * lhs.denominator
        if left != right { return left < right }
        if lhs.objectID != rhs.objectID { return lhs.objectID < rhs.objectID }
        return lhs.projectileID < rhs.projectileID
    }
}
