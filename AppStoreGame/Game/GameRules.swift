import Foundation

enum GameRules {
    static let tickRate = 120
    static let tickDuration = 1.0 / Double(tickRate)
    static let fieldWidth = 390.0
    static let fieldHeight = 844.0
    static let sideWall = 22.0
    // The reserved HUD/coachmark band begins above this boundary on every
    // supported portrait size, so the authoritative ball can never pass behind UI.
    static let topWall = 540.0
    static let missLine = 42.0
    static let paddleY = 92.0
    static let paddleWidth = 108.0
    static let paddleHeight = 18.0
    static let maximumPaddleSpeed = 720.0
    static let powerDurationTicks = 6 * tickRate
    static let comboGraceDurationTicks = Int(1.6 * Double(tickRate))
    static let overdriveEchoDelayTicks = 15
    static let maximumPierceCharges = 6
    private static let itemSeedSalt: UInt64 = 0xA771_ACED_17E5_4A11
    private static let levelEntrySpeeds = [370.0, 388.0, 407.0, 425.0, 444.0]

    private enum CollisionKind: Equatable {
        case wall
        case paddle
        case brick(Int)
    }

    private struct Collision: Equatable {
        let time: Double
        let normal: ShotVector
        let kind: CollisionKind
        let priority: Int
        let stableID: Int
    }

    private struct AttackWaveResolution {
        let events: [ShotSimulationEvent]
        let didAwardCombo: Bool
    }

    static func initialReturnShotState(seed: UInt64) -> ReturnShotState {
        let speed = difficultyProfile(segment: 0).entryBallSpeed
        let direction = ShotVector(x: 0.18, y: 0.98).normalized()
        return ReturnShotState(
            seed: seed,
            ball: ShotBall(
                position: ShotVector(x: fieldWidth / 2, y: 190),
                velocity: direction.scaled(by: speed),
                radius: 10
            ),
            paddleX: fieldWidth / 2,
            paddleTargetX: fieldWidth / 2,
            bricks: returnShotBricks(seed: seed, segment: 0)
        )
    }

    static func difficultyProfile(segment: Int) -> DifficultyProfile {
        let boundedSegment = max(0, segment)
        let level = boundedSegment + 1
        let entryBallSpeed: Double
        if level <= levelEntrySpeeds.count {
            entryBallSpeed = levelEntrySpeeds[level - 1]
        } else {
            entryBallSpeed = min(
                518,
                levelEntrySpeeds[levelEntrySpeeds.count - 1]
                    + Double(level - levelEntrySpeeds.count) * 15
            )
        }

        let armorLayers: Int
        switch level {
        case 1...3: armorLayers = 0
        case 4...6: armorLayers = 1
        default: armorLayers = 2
        }

        let prismCount: Int
        let negativeCount: Int
        switch level {
        case 1:
            prismCount = 0
            negativeCount = 0
        case 2:
            prismCount = 1
            negativeCount = 0
        case 3:
            prismCount = 1
            negativeCount = 1
        default:
            prismCount = 2
            negativeCount = 2
        }

        return DifficultyProfile(
            level: level,
            entryBallSpeed: entryBallSpeed,
            armorLayers: armorLayers,
            prismCount: prismCount,
            negativeCount: negativeCount
        )
    }

    static func stageArmor(segment: Int) -> Int {
        difficultyProfile(segment: segment).armorLayers
    }

    static func returnShotBricks(seed: UInt64, segment: Int) -> [ShotBrick] {
        let segmentSalt = UInt64(truncatingIfNeeded: segment) &* 0xD1B5_4A32_D192_ED03
        var rng = SeededRandom(seed: seed ^ segmentSalt)
        let columnCount = 6
        let rowCount = 5
        let startX = 49.0
        let startY = 280.0
        let spacingX = 58.0
        let spacingY = 52.0

        var bricks: [ShotBrick] = []
        let profile = difficultyProfile(segment: segment)
        let armor = profile.armorLayers
        let prismSlots = [(row: 2, column: 1), (row: 4, column: 2)]
        let negativeSlots = [(row: 3, column: 4), (row: 4, column: 5)]
        for row in 0..<rowCount {
            for column in 0..<columnCount {
                let id = segment * 1_000 + row * 10 + column
                let role: ShotBrickRole
                if row == 0 {
                    role = .support
                } else if let slot = prismSlots.firstIndex(where: {
                    $0.row == row && $0.column == column
                }), slot < profile.prismCount {
                    role = .prism
                } else if let slot = negativeSlots.firstIndex(where: {
                    $0.row == row && $0.column == column
                }), slot < profile.negativeCount {
                    role = .negative
                } else {
                    role = .normal
                }

                let signature: BrickSignature?
                if role == .support || role == .negative {
                    signature = nil
                } else if segment == 0, row <= 2 {
                    signature = BrickSignature(
                        color: .mint,
                        pattern: BrickPattern.allCases[(row + column) % BrickPattern.allCases.count],
                        mark: BrickMark.allCases[(row * 2 + column) % BrickMark.allCases.count]
                    )
                } else {
                    signature = BrickSignature(
                        color: BrickColor.allCases[rng.int(in: 0...(BrickColor.allCases.count - 1))],
                        pattern: BrickPattern.allCases[rng.int(in: 0...(BrickPattern.allCases.count - 1))],
                        mark: BrickMark.allCases[rng.int(in: 0...(BrickMark.allCases.count - 1))]
                    )
                }

                let maximumHitPoints: Int
                switch role {
                case .normal: maximumHitPoints = 1
                case .support: maximumHitPoints = 2
                case .prism: maximumHitPoints = 3
                case .negative: maximumHitPoints = Int.max
                }

                var supportIDs: [Int] = []
                if row > 0 {
                    supportIDs.append(segment * 1_000 + (row - 1) * 10 + column)
                    let adjacentColumn = column == 0 ? 1 : column - 1
                    supportIDs.append(segment * 1_000 + (row - 1) * 10 + adjacentColumn)
                }

                bricks.append(
                    ShotBrick(
                        id: id,
                        rect: ShotRect(
                            center: ShotVector(
                                x: startX + Double(column) * spacingX,
                                y: startY + Double(row) * spacingY
                            ),
                            width: role == .support ? 50 : 48,
                            height: role == .support ? 28 : 38
                        ),
                        signature: signature,
                        role: role,
                        maximumHitPoints: maximumHitPoints,
                        hitPoints: maximumHitPoints,
                        supportIDs: Array(Set(supportIDs)).sorted(),
                        anchored: row == 0,
                        embeddedItem: nil,
                        maximumArmor: role == .negative ? 0 : armor,
                        armor: role == .negative ? 0 : armor
                    )
                )
            }
        }

        let carrierCandidates = bricks.indices.filter { bricks[$0].role == .normal }
        if !carrierCandidates.isEmpty {
            var itemRNG = SeededRandom(
                seed: seed
                    ^ itemSeedSalt
                    ^ (UInt64(truncatingIfNeeded: segment) &* 0x94D0_49BB_1331_11EB)
            )
            let selected = carrierCandidates[itemRNG.int(in: 0...(carrierCandidates.count - 1))]
            bricks[selected].embeddedItem = AttackItemKind(
                rawValue: segment % AttackItemKind.allCases.count
            )
        }
        return bricks.sorted { $0.id < $1.id }
    }

    /// 권위 시뮬레이션을 정확히 한 120Hz tick 진행한다.
    @discardableResult
    static func stepReturnShot(
        state: inout ReturnShotState,
        paddleTargetX: Double
    ) -> [ShotSimulationEvent] {
        guard state.phase == .playing else { return [] }
        var events: [ShotSimulationEvent] = []
        state.tick += 1

        let clampedTarget = min(
            fieldWidth - sideWall - paddleWidth / 2,
            max(sideWall + paddleWidth / 2, paddleTargetX)
        )
        state.paddleTargetX = clampedTarget
        let maximumPaddleDelta = maximumPaddleSpeed * tickDuration
        let desiredDelta = clampedTarget - state.paddleX
        let paddleDelta = min(maximumPaddleDelta, max(-maximumPaddleDelta, desiredDelta))
        state.paddleX += paddleDelta
        state.paddleVelocity = paddleDelta / tickDuration

        if state.comboGraceTicks > 0 {
            state.comboGraceTicks -= 1
            if state.comboGraceTicks == 0, state.combo > 0 {
                state.combo = 0
                events.append(.comboChanged(0))
            }
        }
        if state.returnShotTicks > 0 { state.returnShotTicks -= 1 }
        if state.powerTicks > 0 {
            state.powerTicks -= 1
            if state.powerTicks == 0 {
                state.link = AttributeLinkState()
                state.feedback = "폭주 종료 · 새 LINK 시작"
                events.append(.powerExpired)
                events.append(.linkChanged(state.link))
            }
        }
        events.append(contentsOf: resolveDueAttackEchoes(state: &state))

        var remainingTime = tickDuration
        var collisionIterations = 0
        while remainingTime > 0.000_000_1, collisionIterations < 8 {
            collisionIterations += 1
            let movement = state.ball.velocity.scaled(by: remainingTime)
            guard let collision = firstCollision(state: state, movement: movement) else {
                state.ball.position.x += movement.x
                state.ball.position.y += movement.y
                remainingTime = 0
                break
            }

            state.ball.position.x += movement.x * collision.time
            state.ball.position.y += movement.y * collision.time
            remainingTime *= max(0, 1 - collision.time)

            switch collision.kind {
            case .wall:
                reflect(velocity: &state.ball.velocity, normal: collision.normal)
                normalizeBallSpeed(state: &state)
                nudgeBall(state: &state, normal: collision.normal)
            case .paddle:
                let edgeShot = reflectFromPaddle(state: &state)
                events.append(.paddleReturn(edgeShot: edgeShot))
                nudgeBall(state: &state, normal: ShotVector(x: 0, y: 1))
            case .brick(let brickID):
                let outcome = resolveDirectBrickContact(state: &state, brickID: brickID)
                events.append(contentsOf: outcome.events)
                if outcome.shouldReflect {
                    reflect(velocity: &state.ball.velocity, normal: collision.normal)
                    normalizeBallSpeed(state: &state)
                    nudgeBall(state: &state, normal: collision.normal)
                } else {
                    let direction = state.ball.velocity.normalized()
                    state.ball.position.x += direction.x * 0.05
                    state.ball.position.y += direction.y * 0.05
                }
            }
        }

        if state.ball.position.y + state.ball.radius < missLine {
            state.phase = .finished
            state.feedback = "공이 패들 아래로 떨어졌어요"
            events.append(.missed)
        }

        let hasPendingEchoInCurrentSegment = state.attackItems.pendingEchoes.contains {
            $0.segment == state.segment
        }
        if state.phase == .playing,
           !hasPendingEchoInCurrentSegment,
           !state.bricks.contains(where: { !$0.isRemoved && $0.role != .negative }) {
            state.segment += 1
            state.height += 10
            state.bricks = returnShotBricks(seed: state.seed, segment: state.segment)
            normalizeBallSpeed(state: &state)
            let profile = difficultyProfile(segment: state.segment)
            state.feedback = "LEVEL \(profile.level) · SPEED \(Int(profile.entryBallSpeed))"
            events.append(.segmentAdvanced(state.segment))
            events.append(.levelAdvanced(profile))
        }

        return events
    }

    static func reflectionVelocity(
        contactOffset: Double,
        paddleVelocity: Double,
        speed: Double
    ) -> ShotVector {
        let clampedOffset = min(1, max(-1, contactOffset))
        let normalizedPaddleVelocity = min(1, max(-1, paddleVelocity / maximumPaddleSpeed))
        let angleDegrees = min(62, max(-62, clampedOffset * 42 + normalizedPaddleVelocity * 20))
        let radians = angleDegrees * .pi / 180
        return ShotVector(
            x: sin(radians) * speed,
            y: max(cos(radians) * speed, speed * 0.46)
        ).normalized().scaled(by: speed)
    }

    @discardableResult
    static func updateAttributeLink(
        state: inout ReturnShotState,
        signature: BrickSignature
    ) -> Int {
        let previous = state.link.previousSignature
        let colorMatched = previous?.color == signature.color
        let patternMatched = previous?.pattern == signature.pattern
        let markMatched = previous?.mark == signature.mark

        state.link.colorCount = colorMatched ? state.link.colorCount + 1 : 1
        state.link.patternCount = patternMatched ? state.link.patternCount + 1 : 1
        state.link.markCount = markMatched ? state.link.markCount + 1 : 1
        state.link.previousSignature = signature
        state.maxLink = max(state.maxLink, state.link.highestCount)

        if !state.isPowerActive,
           state.link.colorCount == 5 || state.link.patternCount == 5 || state.link.markCount == 5 {
            state.powerTicks = powerDurationTicks
            state.powerActivations += 1
            state.feedback = "공명 폭주! 6초 관통"
        }

        return [colorMatched, patternMatched, markMatched].filter { $0 }.count
    }

    /// 테스트와 scene이 동일한 contact transaction을 사용한다.
    static func resolveDirectBrickContact(
        state: inout ReturnShotState,
        brickID: Int
    ) -> (events: [ShotSimulationEvent], shouldReflect: Bool) {
        guard let index = state.bricks.firstIndex(where: { $0.id == brickID && !$0.isRemoved }) else {
            return ([], false)
        }

        if state.bricks[index].role == .negative {
            return resolveNegativeContact(state: &state, index: index)
        }

        var events: [ShotSimulationEvent] = []
        let role = state.bricks[index].role
        let embeddedItem = state.bricks[index].embeddedItem
        let sourceCenter = state.bricks[index].rect.center
        let firstEligibleContact = state.bricks[index].signature != nil
            && !state.bricks[index].eligibleContactRecorded
        var attributeMatchCount = 0
        if firstEligibleContact, let signature = state.bricks[index].signature {
            attributeMatchCount = updateAttributeLink(state: &state, signature: signature)
            state.bricks[index].eligibleContactRecorded = true
            events.append(.linkChanged(state.link))
            if state.powerTicks == powerDurationTicks {
                events.append(.powerActivated)
            }
        }

        let usedPierce = state.attackItems.pierceCharges > 0
        if usedPierce {
            state.attackItems.pierceCharges -= 1
            events.append(.pierceChargesChanged(state.attackItems.pierceCharges))
        }

        let hitNumber = state.bricks[index].maximumHitPoints - state.bricks[index].hitPoints + 1
        let damage = state.isPowerActive && (role == .support || role == .prism) ? 2 : 1
        let damageResult = applyArmorAndCoreDamage(
            state: &state,
            index: index,
            amount: damage
        )
        events.append(contentsOf: damageResult.events)

        let contactPoints: Int
        if damageResult.coreDamage == 0 {
            contactPoints = 0
        } else {
            switch role {
            case .normal:
                contactPoints = 0
            case .support:
                contactPoints = 40
            case .prism:
                contactPoints = [80, 140, 240][min(2, max(0, hitNumber - 1))]
            case .negative:
                contactPoints = 0
            }
        }
        let directPoints = scoredDirectPoints(
            base: contactPoints,
            attributeMatchCount: attributeMatchCount,
            state: state
        )
        state.score += Int64(directPoints)

        var removedDirectly = false
        if damageResult.coreDamage > 0, state.bricks[index].hitPoints == 0 {
            state.bricks[index].isRemoved = true
            removedDirectly = true
            let completionBase: Int
            switch role {
            case .normal: completionBase = 50
            case .support: completionBase = 120
            case .prism: completionBase = 300
            case .negative: completionBase = 0
            }
            advanceCombo(state: &state, events: &events)
            let completionPoints = scoredDirectPoints(
                base: completionBase,
                attributeMatchCount: attributeMatchCount,
                state: state
            )
            state.score += Int64(completionPoints)
            state.height += role == .support ? 2 : 1
            state.destroyedBrickCount += 1
            state.feedback = role == .prism
                ? "프리즘 완파 +\(completionPoints)"
                : "콤보 ×\(state.combo) · +\(completionPoints)"
            events.append(.brickRemoved(id: brickID, cause: .direct, points: completionPoints))
            events.append(contentsOf: collapseUnsupported(state: &state))
        } else if damageResult.coreDamage == 0 {
            state.feedback = "방어력 \(state.bricks[index].armor) 남음"
        } else if role == .prism {
            state.feedback = "프리즘 \(state.bricks[index].hitPoints)겹 남음"
        } else if role == .support {
            state.feedback = "지지점 \(state.bricks[index].hitPoints)회 남음"
        }

        if state.isPowerActive {
            events.append(contentsOf: applyPowerShockwave(state: &state, around: brickID))
        }

        if removedDirectly, let embeddedItem {
            events.append(
                contentsOf: collectAndActivateItem(
                    state: &state,
                    kind: embeddedItem,
                    carrierID: brickID,
                    sourceCenter: sourceCenter
                )
            )
        }

        let shouldReflect = !usedPierce
            && !(state.isPowerActive && role == .normal && removedDirectly)
        return (events, shouldReflect)
    }

    private static func applyArmorAndCoreDamage(
        state: inout ReturnShotState,
        index: Int,
        amount: Int
    ) -> (events: [ShotSimulationEvent], coreDamage: Int) {
        guard amount > 0, state.bricks.indices.contains(index), !state.bricks[index].isRemoved else {
            return ([], 0)
        }

        var events: [ShotSimulationEvent] = []
        var remainingDamage = amount
        if state.bricks[index].armor > 0 {
            let absorbed = min(state.bricks[index].armor, remainingDamage)
            state.bricks[index].armor -= absorbed
            remainingDamage -= absorbed
            events.append(
                .armorChanged(
                    id: state.bricks[index].id,
                    remainingArmor: state.bricks[index].armor
                )
            )
        }

        let coreDamage = min(state.bricks[index].hitPoints, remainingDamage)
        if coreDamage > 0 {
            state.bricks[index].hitPoints -= coreDamage
            events.append(
                .brickHit(
                    id: state.bricks[index].id,
                    remainingHitPoints: state.bricks[index].hitPoints
                )
            )
        }
        return (events, coreDamage)
    }

    private static func collectAndActivateItem(
        state: inout ReturnShotState,
        kind: AttackItemKind,
        carrierID: Int,
        sourceCenter: ShotVector
    ) -> [ShotSimulationEvent] {
        let upgrade = registerAttackCollection(state: &state.attackItems, kind: kind)
        let level = upgrade.rank
        state.feedback = upgrade.isOverdrive
            ? "\(kind.name) MAX OVERDRIVE 충전!"
            : "\(kind.name) 코어 LV\(level) 발동!"
        var events: [ShotSimulationEvent] = [
            .itemCollected(kind: kind, level: level, carrierID: carrierID)
        ]

        if kind == .pierce {
            state.attackItems.pierceCharges = min(
                maximumPierceCharges,
                state.attackItems.pierceCharges + level
            )
            state.feedback = "관통 LV\(level) · \(state.attackItems.pierceCharges)회 충전"
            events.append(.pierceChargesChanged(state.attackItems.pierceCharges))
            if case .overdrive(_, let activation) = upgrade {
                let pending = PendingAttackEcho(
                    sequence: activation,
                    triggerTick: state.tick + overdriveEchoDelayTicks,
                    segment: state.segment,
                    kind: kind,
                    carrierID: carrierID,
                    targetIDs: [],
                    canAwardCombo: false
                )
                state.attackItems.pendingEchoes.append(pending)
                state.attackItems.pendingEchoes.sort(by: pendingEchoSort)
                events.append(
                    .itemOverdriveScheduled(
                        kind: kind,
                        rank: level,
                        activation: activation,
                        carrierID: carrierID,
                        triggerTick: pending.triggerTick
                    )
                )
            }
            return events
        }

        let targets = attackItemTargets(
            state: state,
            kind: kind,
            level: level,
            carrierID: carrierID,
            sourceCenter: sourceCenter
        )
        let primary = applyAttackItemWave(
            state: &state,
            kind: kind,
            targetIndices: targets,
            awardsCombo: true
        )
        events.append(contentsOf: primary.events)

        if case .overdrive(_, let activation) = upgrade {
            let targetIDs = targets
                .map { state.bricks[$0].id }
                .sorted()
            let pending = PendingAttackEcho(
                sequence: activation,
                triggerTick: state.tick + overdriveEchoDelayTicks,
                segment: state.segment,
                kind: kind,
                carrierID: carrierID,
                targetIDs: targetIDs,
                canAwardCombo: !primary.didAwardCombo
            )
            state.attackItems.pendingEchoes.append(pending)
            state.attackItems.pendingEchoes.sort(by: pendingEchoSort)
            events.append(
                .itemOverdriveScheduled(
                    kind: kind,
                    rank: level,
                    activation: activation,
                    carrierID: carrierID,
                    triggerTick: pending.triggerTick
                )
            )
        }
        return events
    }

    @discardableResult
    static func registerAttackCollection(
        state: inout AttackItemState,
        kind: AttackItemKind
    ) -> AttackUpgradeOutcome {
        let previous = state.levels.level(for: kind)
        let current = state.levels.levelUp(kind)
        state.totalCollected += 1
        state.lastCollected = kind
        if previous >= AttackItemLevels.maximumRank {
            state.overdriveCount += 1
            return .overdrive(rank: current, activation: state.overdriveCount)
        }
        return .rankedUp(previous: previous, current: current)
    }

    private static func attackItemTargets(
        state: ReturnShotState,
        kind: AttackItemKind,
        level: Int,
        carrierID: Int,
        sourceCenter: ShotVector
    ) -> [Int] {
        let boundedLevel = min(3, max(1, level))
        let candidates = state.bricks.indices.filter { index in
            let brick = state.bricks[index]
            return !brick.isRemoved
                && brick.id != carrierID
                && brick.role != .negative
                && brick.embeddedItem == nil
        }

        switch kind {
        case .lightning:
            return candidates.sorted { lhs, rhs in
                let left = squaredDistance(state.bricks[lhs].rect.center, sourceCenter)
                let right = squaredDistance(state.bricks[rhs].rect.center, sourceCenter)
                if abs(left - right) > 0.000_001 { return left < right }
                return state.bricks[lhs].id < state.bricks[rhs].id
            }
            .prefix(boundedLevel)
            .map { $0 }

        case .flame:
            let radii = [72.0, 92.0, 112.0]
            let limits = [3, 5, 7]
            let radiusSquared = radii[boundedLevel - 1] * radii[boundedLevel - 1]
            return candidates.filter { index in
                squaredDistance(state.bricks[index].rect.center, sourceCenter) <= radiusSquared
            }
            .sorted { lhs, rhs in
                let left = squaredDistance(state.bricks[lhs].rect.center, sourceCenter)
                let right = squaredDistance(state.bricks[rhs].rect.center, sourceCenter)
                if abs(left - right) > 0.000_001 { return left < right }
                return state.bricks[lhs].id < state.bricks[rhs].id
            }
            .prefix(limits[boundedLevel - 1])
            .map { $0 }

        case .wind:
            return candidates.filter { state.bricks[$0].rect.center.y > sourceCenter.y }
                .sorted { lhs, rhs in
                    let left = state.bricks[lhs]
                    let right = state.bricks[rhs]
                    if abs(left.rect.center.y - right.rect.center.y) > 0.000_001 {
                        return left.rect.center.y < right.rect.center.y
                    }
                    let leftX = abs(left.rect.center.x - sourceCenter.x)
                    let rightX = abs(right.rect.center.x - sourceCenter.x)
                    if abs(leftX - rightX) > 0.000_001 { return leftX < rightX }
                    return left.id < right.id
                }
                .prefix(boundedLevel + 1)
                .map { $0 }

        case .pierce:
            return []
        }
    }

    private static func applyAttackItemWave(
        state: inout ReturnShotState,
        kind: AttackItemKind,
        targetIndices: [Int],
        awardsCombo: Bool
    ) -> AttackWaveResolution {
        var events: [ShotSimulationEvent] = []
        var removedAny = false

        for index in targetIndices {
            guard state.bricks.indices.contains(index), !state.bricks[index].isRemoved else { continue }
            let damageResult = applyArmorAndCoreDamage(state: &state, index: index, amount: 1)
            events.append(contentsOf: damageResult.events)
            guard damageResult.coreDamage > 0, state.bricks[index].hitPoints == 0 else { continue }

            state.bricks[index].isRemoved = true
            state.score += 60
            state.height += 1
            state.destroyedBrickCount += 1
            removedAny = true
            events.append(
                .brickRemoved(
                    id: state.bricks[index].id,
                    cause: .attackItem(kind),
                    points: 60
                )
            )
        }

        var didAwardCombo = false
        if removedAny, awardsCombo {
            advanceCombo(state: &state, events: &events)
            didAwardCombo = true
        }
        if removedAny {
            events.append(contentsOf: collapseUnsupported(state: &state, awardsCombo: false))
        }
        return AttackWaveResolution(events: events, didAwardCombo: didAwardCombo)
    }

    private static func resolveDueAttackEchoes(
        state: inout ReturnShotState
    ) -> [ShotSimulationEvent] {
        let due = state.attackItems.pendingEchoes
            .filter { $0.triggerTick <= state.tick }
            .sorted(by: pendingEchoSort)
        guard !due.isEmpty else { return [] }

        let dueSequences = Set(due.map(\.sequence))
        state.attackItems.pendingEchoes.removeAll { dueSequences.contains($0.sequence) }

        var events: [ShotSimulationEvent] = []
        for echo in due where echo.segment == state.segment {
            events.append(
                .itemOverdriveActivated(
                    kind: echo.kind,
                    rank: AttackItemLevels.maximumRank,
                    activation: echo.sequence,
                    carrierID: echo.carrierID
                )
            )

            if echo.kind == .pierce {
                state.attackItems.pierceCharges = min(
                    maximumPierceCharges,
                    state.attackItems.pierceCharges + AttackItemLevels.maximumRank
                )
                events.append(.pierceChargesChanged(state.attackItems.pierceCharges))
            } else {
                let targetIndices = echo.targetIDs.compactMap { targetID in
                    state.bricks.firstIndex { brick in
                        brick.id == targetID
                            && !brick.isRemoved
                            && brick.role != .negative
                            && brick.embeddedItem == nil
                    }
                }
                let resolution = applyAttackItemWave(
                    state: &state,
                    kind: echo.kind,
                    targetIndices: targetIndices,
                    awardsCombo: echo.canAwardCombo
                )
                events.append(contentsOf: resolution.events)
            }
            state.feedback = "\(echo.kind.name) MAX OVERDRIVE!"
        }
        return events
    }

    private static func pendingEchoSort(_ lhs: PendingAttackEcho, _ rhs: PendingAttackEcho) -> Bool {
        if lhs.triggerTick != rhs.triggerTick { return lhs.triggerTick < rhs.triggerTick }
        return lhs.sequence < rhs.sequence
    }

    private static func squaredDistance(_ lhs: ShotVector, _ rhs: ShotVector) -> Double {
        let dx = lhs.x - rhs.x
        let dy = lhs.y - rhs.y
        return dx * dx + dy * dy
    }

    static func collapseUnsupported(
        state: inout ReturnShotState,
        awardsCombo: Bool = true
    ) -> [ShotSimulationEvent] {
        var events: [ShotSimulationEvent] = []
        var fellAnyPositive = false

        while true {
            let removedIDs = Set(state.bricks.filter(\.isRemoved).map(\.id))
            let unsupportedIndices = state.bricks.indices
                .filter { index in
                    let brick = state.bricks[index]
                    return !brick.isRemoved
                        && !brick.anchored
                        && !brick.supportIDs.isEmpty
                        && brick.supportIDs.allSatisfy { removedIDs.contains($0) }
                }
                .sorted { state.bricks[$0].id < state.bricks[$1].id }
            guard !unsupportedIndices.isEmpty else { break }

            for index in unsupportedIndices {
                guard !state.bricks[index].isRemoved else { continue }
                state.bricks[index].isRemoved = true
                state.destroyedBrickCount += 1
                let role = state.bricks[index].role
                let points: Int
                switch role {
                case .negative:
                    points = 120
                    state.height += 3
                    state.feedback = "위험 제거 +120"
                    events.append(.cleanDrop(id: state.bricks[index].id, points: points))
                case .prism:
                    points = 120
                    state.height += 2
                    fellAnyPositive = true
                case .normal, .support:
                    points = 45
                    state.height += 1
                    fellAnyPositive = true
                }
                state.score += Int64(points)
                events.append(
                    .brickRemoved(
                        id: state.bricks[index].id,
                        cause: .unsupportedFall,
                        points: points
                    )
                )
            }
        }

        if fellAnyPositive, awardsCombo {
            advanceCombo(state: &state, events: &events)
        }
        return events
    }

    static func checksum(_ state: ReturnShotState) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        func mix(_ value: UInt64) {
            hash ^= value
            hash &*= 0x1000_0000_01b3
        }
        func mixInt(_ value: Int) {
            mix(UInt64(bitPattern: Int64(value)))
        }
        func mixDouble(_ value: Double) {
            mix(UInt64(bitPattern: Int64((value * 1_000).rounded())))
        }

        mix(state.seed)
        mix(UInt64(state.tick))
        mixDouble(state.ball.position.x)
        mixDouble(state.ball.position.y)
        mixDouble(state.ball.velocity.x)
        mixDouble(state.ball.velocity.y)
        mixDouble(state.ball.radius)
        mixDouble(state.paddleX)
        mixDouble(state.paddleTargetX)
        mixDouble(state.paddleVelocity)
        mix(UInt64(bitPattern: state.score))
        mixInt(state.height)
        mixInt(state.combo)
        mixInt(state.maxCombo)
        mixInt(state.comboGraceTicks)
        if let signature = state.link.previousSignature {
            mix(UInt64(signature.color.rawValue))
            mix(UInt64(signature.pattern.rawValue))
            mix(UInt64(signature.mark.rawValue))
        } else {
            mix(UInt64.max)
        }
        mixInt(state.link.colorCount)
        mixInt(state.link.patternCount)
        mixInt(state.link.markCount)
        mixInt(state.maxLink)
        mixInt(state.powerTicks)
        mixInt(state.powerActivations)
        mixInt(state.returnShotTicks)
        mixInt(state.segment)
        mixInt(state.destroyedBrickCount)
        mixInt(state.attackItems.levels.lightning)
        mixInt(state.attackItems.levels.flame)
        mixInt(state.attackItems.levels.wind)
        mixInt(state.attackItems.levels.pierce)
        mixInt(state.attackItems.pierceCharges)
        mixInt(state.attackItems.totalCollected)
        mix(state.attackItems.lastCollected.map { UInt64($0.rawValue) } ?? UInt64.max)
        mixInt(state.attackItems.overdriveCount)
        let pendingEchoes = state.attackItems.pendingEchoes.sorted(by: pendingEchoSort)
        mixInt(pendingEchoes.count)
        for echo in pendingEchoes {
            mixInt(echo.sequence)
            mixInt(echo.triggerTick)
            mixInt(echo.segment)
            mix(UInt64(echo.kind.rawValue))
            mixInt(echo.carrierID)
            mix(echo.canAwardCombo ? 1 : 0)
            mixInt(echo.targetIDs.count)
            for targetID in echo.targetIDs {
                mixInt(targetID)
            }
        }
        let phaseValue: UInt64 = switch state.phase {
        case .ready: 0
        case .playing: 1
        case .paused: 2
        case .finished: 3
        }
        mix(phaseValue)

        for brick in state.bricks.sorted(by: { $0.id < $1.id }) {
            mixInt(brick.id)
            mixDouble(brick.rect.center.x)
            mixDouble(brick.rect.center.y)
            mixDouble(brick.rect.width)
            mixDouble(brick.rect.height)
            let roleValue: UInt64 = switch brick.role {
            case .normal: 0
            case .support: 1
            case .prism: 2
            case .negative: 3
            }
            mix(roleValue)
            if let signature = brick.signature {
                mix(UInt64(signature.color.rawValue))
                mix(UInt64(signature.pattern.rawValue))
                mix(UInt64(signature.mark.rawValue))
            } else {
                mix(UInt64.max)
            }
            mix(brick.maximumHitPoints == Int.max ? UInt64.max : UInt64(brick.maximumHitPoints))
            mix(brick.hitPoints == Int.max ? UInt64.max : UInt64(max(0, brick.hitPoints)))
            mixInt(brick.maximumArmor)
            mixInt(brick.armor)
            mix(brick.embeddedItem.map { UInt64($0.rawValue) } ?? UInt64.max)
            mix(brick.anchored ? 1 : 0)
            mix(brick.isRemoved ? 1 : 0)
            mixInt(brick.penaltyHits)
            mixInt(brick.lastPenaltyTick)
            mix(brick.eligibleContactRecorded ? 1 : 0)
            mixInt(brick.supportIDs.count)
            for supportID in brick.supportIDs.sorted() {
                mixInt(supportID)
            }
        }
        return hash
    }

    private static func firstCollision(
        state: ReturnShotState,
        movement: ShotVector
    ) -> Collision? {
        var candidates: [Collision] = []
        let radius = state.ball.radius
        let start = state.ball.position

        if movement.x < 0 {
            let time = (sideWall + radius - start.x) / movement.x
            if (0...1).contains(time) {
                candidates.append(
                    Collision(time: time, normal: ShotVector(x: 1, y: 0), kind: .wall, priority: 2, stableID: 0)
                )
            }
        } else if movement.x > 0 {
            let time = (fieldWidth - sideWall - radius - start.x) / movement.x
            if (0...1).contains(time) {
                candidates.append(
                    Collision(time: time, normal: ShotVector(x: -1, y: 0), kind: .wall, priority: 2, stableID: 1)
                )
            }
        }
        if movement.y > 0 {
            let time = (topWall - radius - start.y) / movement.y
            if (0...1).contains(time) {
                candidates.append(
                    Collision(time: time, normal: ShotVector(x: 0, y: -1), kind: .wall, priority: 2, stableID: 2)
                )
            }
        }

        if movement.y < 0 {
            let paddleRect = ShotRect(
                center: ShotVector(x: state.paddleX, y: paddleY),
                width: paddleWidth,
                height: paddleHeight
            ).expanded(by: radius)
            if let hit = sweptPointAgainstRect(start: start, movement: movement, rect: paddleRect) {
                candidates.append(
                    Collision(time: hit.time, normal: hit.normal, kind: .paddle, priority: 0, stableID: 0)
                )
            }
        }

        for brick in state.bricks where !brick.isRemoved {
            if let hit = sweptPointAgainstRect(
                start: start,
                movement: movement,
                rect: brick.rect.expanded(by: radius)
            ) {
                candidates.append(
                    Collision(
                        time: hit.time,
                        normal: hit.normal,
                        kind: .brick(brick.id),
                        priority: 1,
                        stableID: brick.id
                    )
                )
            }
        }

        return candidates.min { lhs, rhs in
            if abs(lhs.time - rhs.time) > 0.000_000_1 { return lhs.time < rhs.time }
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.stableID < rhs.stableID
        }
    }

    private static func sweptPointAgainstRect(
        start: ShotVector,
        movement: ShotVector,
        rect: ShotRect
    ) -> (time: Double, normal: ShotVector)? {
        let nearX: Double
        let farX: Double
        if abs(movement.x) < 0.000_000_1 {
            guard (rect.minX...rect.maxX).contains(start.x) else { return nil }
            nearX = -.infinity
            farX = .infinity
        } else {
            let first = (rect.minX - start.x) / movement.x
            let second = (rect.maxX - start.x) / movement.x
            nearX = min(first, second)
            farX = max(first, second)
        }

        let nearY: Double
        let farY: Double
        if abs(movement.y) < 0.000_000_1 {
            guard (rect.minY...rect.maxY).contains(start.y) else { return nil }
            nearY = -.infinity
            farY = .infinity
        } else {
            let first = (rect.minY - start.y) / movement.y
            let second = (rect.maxY - start.y) / movement.y
            nearY = min(first, second)
            farY = max(first, second)
        }

        let nearTime = max(nearX, nearY)
        let farTime = min(farX, farY)
        guard nearTime <= farTime, farTime >= 0, nearTime >= 0, nearTime <= 1 else { return nil }

        let normal: ShotVector
        if nearX > nearY {
            normal = ShotVector(x: movement.x < 0 ? 1 : -1, y: 0)
        } else {
            normal = ShotVector(x: 0, y: movement.y < 0 ? 1 : -1)
        }
        return (nearTime, normal)
    }

    private static func resolveNegativeContact(
        state: inout ReturnShotState,
        index: Int
    ) -> (events: [ShotSimulationEvent], shouldReflect: Bool) {
        let cooldownTicks = Int(0.75 * Double(tickRate))
        let canPenalize = state.bricks[index].penaltyHits < 2
            && state.tick - state.bricks[index].lastPenaltyTick >= cooldownTicks
        guard canPenalize else { return ([], true) }

        state.bricks[index].penaltyHits += 1
        state.bricks[index].lastPenaltyTick = state.tick
        state.score = max(0, state.score - 250)
        state.combo = 0
        state.comboGraceTicks = 0
        state.link = AttributeLinkState()
        state.powerTicks = max(0, state.powerTicks - 2 * tickRate)
        state.feedback = "−250 직접 적중 · 지지점을 노리세요"
        return (
            [
                .negativeHit(id: state.bricks[index].id, penalty: 250),
                .comboChanged(0),
                .linkChanged(state.link)
            ],
            true
        )
    }

    private static func applyPowerShockwave(
        state: inout ReturnShotState,
        around brickID: Int
    ) -> [ShotSimulationEvent] {
        guard let source = state.bricks.first(where: { $0.id == brickID }) else { return [] }
        let candidates = state.bricks.indices
            .filter { index in
                let brick = state.bricks[index]
                guard !brick.isRemoved, brick.id != brickID, brick.role != .negative else { return false }
                let dx = brick.rect.center.x - source.rect.center.x
                let dy = brick.rect.center.y - source.rect.center.y
                return hypot(dx, dy) <= 88
            }
            .sorted { lhs, rhs in
                let left = state.bricks[lhs]
                let right = state.bricks[rhs]
                let leftDistance = hypot(
                    left.rect.center.x - source.rect.center.x,
                    left.rect.center.y - source.rect.center.y
                )
                let rightDistance = hypot(
                    right.rect.center.x - source.rect.center.x,
                    right.rect.center.y - source.rect.center.y
                )
                if abs(leftDistance - rightDistance) > 0.001 { return leftDistance < rightDistance }
                return left.id < right.id
            }
            .prefix(2)

        var events: [ShotSimulationEvent] = []
        for index in candidates {
            guard !state.bricks[index].isRemoved else { continue }
            let damageResult = applyArmorAndCoreDamage(state: &state, index: index, amount: 1)
            events.append(contentsOf: damageResult.events)
            if damageResult.coreDamage > 0, state.bricks[index].hitPoints == 0 {
                state.bricks[index].isRemoved = true
                state.score += 60
                state.height += 1
                state.destroyedBrickCount += 1
                advanceCombo(state: &state, events: &events)
                events.append(
                    .brickRemoved(
                        id: state.bricks[index].id,
                        cause: .shockwave,
                        points: 60
                    )
                )
            }
        }
        events.append(contentsOf: collapseUnsupported(state: &state))
        return events
    }

    private static func advanceCombo(
        state: inout ReturnShotState,
        events: inout [ShotSimulationEvent]
    ) {
        state.combo = state.comboGraceTicks > 0 ? state.combo + 1 : 1
        state.comboGraceTicks = comboGraceDurationTicks
        state.maxCombo = max(state.maxCombo, state.combo)
        events.append(.comboChanged(state.combo))
    }

    private static func scoredDirectPoints(
        base: Int,
        attributeMatchCount: Int,
        state: ReturnShotState
    ) -> Int {
        guard base > 0 else { return 0 }
        let attributeMultiplier: Double = switch attributeMatchCount {
        case 3: 2.0
        case 2: 1.5
        case 1: 1.25
        default: 1.0
        }
        let comboMultiplier = min(2.5, 1 + Double(max(0, state.combo - 1)) * 0.15)
        let powerMultiplier = state.isPowerActive ? 2.0 : 1.0
        let returnMultiplier = state.returnShotTicks > 0 ? 2.0 : 1.0
        return Int((Double(base) * attributeMultiplier * comboMultiplier * powerMultiplier * returnMultiplier).rounded())
    }

    private static func reflectFromPaddle(state: inout ReturnShotState) -> Bool {
        let offset = (state.ball.position.x - state.paddleX) / (paddleWidth / 2)
        let speed = desiredBallSpeed(state: state)
        state.ball.velocity = reflectionVelocity(
            contactOffset: offset,
            paddleVelocity: state.paddleVelocity,
            speed: speed
        )
        let edgeShot = abs(offset) >= 0.65 && abs(state.paddleVelocity) >= 220
        if edgeShot {
            state.returnShotTicks = Int(1.8 * Double(tickRate))
            state.feedback = "리턴 샷! 1.8초 ×2"
        }
        return edgeShot
    }

    private static func desiredBallSpeed(state: ReturnShotState) -> Double {
        let base = difficultyProfile(segment: state.segment).entryBallSpeed
        return base * (state.isPowerActive ? 1.12 : 1)
    }

    private static func normalizeBallSpeed(state: inout ReturnShotState) {
        let direction = state.ball.velocity.normalized()
        state.ball.velocity = direction.scaled(by: desiredBallSpeed(state: state))
        let minimumVertical = desiredBallSpeed(state: state) * 0.32
        if abs(state.ball.velocity.y) < minimumVertical {
            state.ball.velocity.y = state.ball.velocity.y < 0 ? -minimumVertical : minimumVertical
            state.ball.velocity = state.ball.velocity.normalized().scaled(by: desiredBallSpeed(state: state))
        }
    }

    private static func reflect(velocity: inout ShotVector, normal: ShotVector) {
        let dot = velocity.x * normal.x + velocity.y * normal.y
        velocity.x -= 2 * dot * normal.x
        velocity.y -= 2 * dot * normal.y
    }

    private static func nudgeBall(state: inout ReturnShotState, normal: ShotVector) {
        state.ball.position.x += normal.x * 0.02
        state.ball.position.y += normal.y * 0.02
    }
}
