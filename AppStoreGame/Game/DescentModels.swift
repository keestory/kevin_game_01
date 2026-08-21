import Foundation

enum DescentSkillKind: Int, CaseIterable, Codable, Equatable, Hashable {
    case fire
    case electric
    case pierce
    case wind
    case explosion
}

/// A run's ship is selected before simulation starts and cannot change mid-run.
/// Ranked Endless gives every craft an explicit strength and drawback while
/// Revision 5 keeps its frozen research loadouts.
enum DescentShipKind: Int, CaseIterable, Codable, Equatable, Hashable {
    case interceptor
    case striker
    case guardian
}

enum DescentMissileKind: Int, CaseIterable, Codable, Equatable, Hashable {
    case pulse
    case lance
    case salvo
}

enum DescentArenaChoice: Int, CaseIterable, Codable, Equatable, Hashable {
    case steady
    case redline
}

enum DescentFlowMode: Int, Codable, Equatable {
    case calm
    case frenzy
}

struct DescentFrenzyState: Codable, Equatable {
    var mode: DescentFlowMode = .calm
    var directChainCount = 0
    var maxDirectChain = 0
    var lastDirectDestructionTick: Int?
    var pendingStartTick: Int?
    var expiresAtTick: Int?
    var activationCount = 0
    var activeTickCount = 0
    var bonusScore: Int64 = 0
}

struct DescentChoiceArenaState: Codable, Equatable {
    var wasPresented = false
    var isAwaitingChoice = false
    var selectedChoice: DescentArenaChoice?
    var selectedAtTick: Int?
    var redlineBonusScore: Int64 = 0
}

struct DescentLoadout: Codable, Equatable {
    let shipKind: DescentShipKind
    let missileKind: DescentMissileKind
    let fireIntervalTicks: Int
    let projectilesPerVolley: Int
    let projectileSpeed: Int
    let damage: Int
    let maximumPlayerSpeed: Int
    let centerProjectileCarriesEffectsOnly: Bool
}

enum DescentObjectKind: Int, CaseIterable, Codable, Equatable, Hashable {
    case normal
    case armored
    case spike
    case drone
    case core
    case brute

    var hitPoints: Int {
        switch self {
        case .normal: 1
        case .armored: 3
        case .spike, .drone, .core: 2
        case .brute: 8
        }
    }

    var fallSpeedPercent: Int {
        switch self {
        case .normal: 100
        case .armored: 78
        case .spike: 122
        case .drone: 108
        case .core: 90
        case .brute: 70
        }
    }

    var baseScore: Int {
        switch self {
        case .normal: 100
        case .armored: 300
        case .spike: 220
        case .drone: 250
        case .core: 250
        case .brute: 700
        }
    }
}

enum DescentSpawnPattern: Int, Codable, Equatable {
    case singleRain
    case splitPair
    case stairSequence
    case clusterGate
}

struct DescentDifficultyProfile: Codable, Equatable {
    let tier: Int
    let startTick: Int
    let baseFallSpeed: Int
    let spawnIntervalTicks: Int
    let pattern: DescentSpawnPattern
    let objectCap: Int
    let projectileCap: Int
    let dropCap: Int
}

struct DescentInput: Codable, Equatable {
    let targetXPoints: Int

    init(targetX: Double) {
        targetXPoints = Int(targetX.rounded())
    }

    init(targetXPoints: Int) {
        self.targetXPoints = targetXPoints
    }
}

struct DescentPlayerState: Codable, Equatable {
    var xQ: Int64
    var targetXQ: Int64
    var reactorHP: Int
    var nextBreachDamageTick: Int
}

struct DescentObject: Codable, Equatable, Identifiable {
    let id: Int
    let kind: DescentObjectKind
    let lane: Int
    var yQ: Int64
    var hitPoints: Int
    let maximumHitPoints: Int
    let fallSpeedQPerTick: Int64
    let spawnedAtTick: Int
    let dropKind: DescentSkillKind?
    var enemyAttackAtTick: Int?
}

struct DescentEnemyProjectile: Codable, Equatable, Identifiable {
    let id: Int
    let sourceObjectID: Int
    let lane: Int
    var yQ: Int64
    let velocityQPerTick: Int64
    let damage: Int
    let spawnedAtTick: Int
}

/// Immutable coordinates captured by the rules engine for presentation only.
/// SpriteKit never uses these cues to decide damage, score, or targets.
struct DescentEffectPoint: Equatable {
    let objectID: Int?
    let xQ: Int64
    let yQ: Int64
}

struct DescentSkillActivationCue: Equatable {
    let kind: DescentSkillKind
    let level: Int
    let activationID: Int
    let origin: DescentEffectPoint
    let targets: [DescentEffectPoint]
}

struct DescentProjectile: Codable, Equatable, Identifiable {
    let id: Int
    let lane: Int
    let missileKind: DescentMissileKind
    let effectSnapshot: DescentProjectileEffectSnapshot
    var yQ: Int64
    let velocityQPerTick: Int64
    let damage: Int
    var remainingHits: Int
    var hitObjectIDs: [Int]

    init(
        id: Int,
        lane: Int,
        missileKind: DescentMissileKind = .pulse,
        effectSnapshot: DescentProjectileEffectSnapshot = .empty,
        yQ: Int64,
        velocityQPerTick: Int64,
        damage: Int,
        remainingHits: Int,
        hitObjectIDs: [Int]
    ) {
        self.id = id
        self.lane = lane
        self.missileKind = missileKind
        self.effectSnapshot = effectSnapshot
        self.yQ = yQ
        self.velocityQPerTick = velocityQPerTick
        self.damage = damage
        self.remainingHits = remainingHits
        self.hitObjectIDs = hitObjectIDs
    }
}

struct DescentDrop: Codable, Equatable, Identifiable {
    let id: Int
    let sourceObjectID: Int
    let kind: DescentSkillKind
    let lane: Int
    var yQ: Int64
    let spawnedAtTick: Int
}

struct DescentSkillLevels: Codable, Equatable {
    static let maximumRank = 3

    var fire = 0
    var electric = 0
    var pierce = 0
    var wind = 0
    var explosion = 0

    func level(for kind: DescentSkillKind) -> Int {
        switch kind {
        case .fire: fire
        case .electric: electric
        case .pierce: pierce
        case .wind: wind
        case .explosion: explosion
        }
    }

    @discardableResult
    mutating func levelUp(_ kind: DescentSkillKind) -> Int {
        let next = min(Self.maximumRank, level(for: kind) + 1)
        switch kind {
        case .fire: fire = next
        case .electric: electric = next
        case .pierce: pierce = next
        case .wind: wind = next
        case .explosion: explosion = next
        }
        return next
    }
}

struct DescentProjectileEffectSnapshot: Codable, Equatable {
    static let empty = DescentProjectileEffectSnapshot(
        shotEventID: 0,
        loadoutVersion: 0,
        dominantEffect: nil,
        levels: DescentSkillLevels()
    )

    let shotEventID: Int
    let loadoutVersion: Int
    let dominantEffect: DescentSkillKind?
    let levels: DescentSkillLevels
}

enum DescentEffectLevelDisplay: String, Codable, Equatable {
    case plusOne = "+1"
    case plusTwo = "+2"
    case plusThree = "+3"
    case maximum = "MAX"

    static func make(level: Int, wasAlreadyMaximum: Bool) -> Self {
        if wasAlreadyMaximum { return .maximum }
        switch level {
        case 1: return .plusOne
        case 2: return .plusTwo
        default: return .plusThree
        }
    }
}

struct DescentPendingFireEcho: Codable, Equatable {
    let activationID: Int
    let projectileID: Int
    let shotEventID: Int
    let triggerTick: Int
    let targetIDs: [Int]
    let comboAwardsRemaining: Int
}

struct DescentSkillState: Codable, Equatable {
    var levels = DescentSkillLevels()
    var loadoutVersion = 0
    var latestEffect: DescentSkillKind?
    var activationCount = 0
    var pendingFireEchoes: [DescentPendingFireEcho] = []
    var pierceShotsRemaining = 0
    var pierceHitCapacity = 1
    var pierceExpiresTick = 0
    var windLevel = 0
    var windMultiplierPercent = 100
    var windExpiresTick = 0
}

struct DescentSpawnPlanEntry: Codable, Equatable {
    let tick: Int
    let objectID: Int
    let kind: DescentObjectKind
    let lane: Int
    let dropKind: DescentSkillKind?
}

enum DescentDamageCause: Codable, Equatable {
    case projectile(id: Int)
    case skill(kind: DescentSkillKind, activationID: Int)
    case fireEcho(activationID: Int)
}

enum DescentEndReason: String, Codable, Equatable {
    case reactorDestroyed
    case survivedSixtySeconds
}

enum DescentSimulationEvent: Equatable {
    case objectSpawned(DescentObject)
    case projectileFired(DescentProjectile)
    case objectDamaged(id: Int, remainingHitPoints: Int, cause: DescentDamageCause)
    case objectDestroyed(id: Int, cause: DescentDamageCause, points: Int)
    case dangerSave(id: Int, bonus: Int)
    case dropSpawned(DescentDrop)
    case dropCollected(
        id: Int,
        kind: DescentSkillKind,
        level: Int,
        display: DescentEffectLevelDisplay,
        loadoutVersion: Int
    )
    case skillActivated(
        kind: DescentSkillKind,
        level: Int,
        activationID: Int,
        targetIDs: [Int]
    )
    case skillCue(DescentSkillActivationCue)
    case enemyProjectileFired(DescentEnemyProjectile)
    case enemyProjectileResolved(id: Int, hitPlayer: Bool, reactorDamaged: Bool)
    case fireEchoScheduled(activationID: Int, triggerTick: Int, targetIDs: [Int])
    case fireEchoActivated(activationID: Int, targetIDs: [Int])
    case comboChanged(Int)
    case frenzyChargeChanged(Int)
    case frenzyStarted(activationID: Int, expiresAtTick: Int)
    case frenzyExtended(activationID: Int, expiresAtTick: Int)
    case frenzyEnded(activationID: Int)
    case frenzyBonus(objectID: Int, points: Int)
    case objectBreached(id: Int, reactorDamaged: Bool)
    case reactorChanged(Int)
    case difficultyAdvanced(DescentDifficultyProfile)
    case choiceArenaPresented(tick: Int)
    case choiceArenaResolved(DescentArenaChoice)
    case finished(DescentEndReason)
}

struct DescentState: Codable, Equatable {
    let seed: UInt64
    let shipKind: DescentShipKind
    var tick: Int
    var player: DescentPlayerState
    var objects: [DescentObject]
    var projectiles: [DescentProjectile]
    var enemyProjectiles: [DescentEnemyProjectile]
    var drops: [DescentDrop]
    var skills: DescentSkillState
    var choiceArena: DescentChoiceArenaState
    var frenzy: DescentFrenzyState
    var nextObjectID: Int
    var nextProjectileID: Int
    var nextEnemyProjectileID: Int
    var nextShotEventID: Int
    var nextDropID: Int
    var spawnSequence: Int
    var nextSpawnTick: Int
    var forcedCarrierIndex: Int
    var score: Int64
    var skillScore: Int64
    var combo: Int
    var maxCombo: Int
    var lastDestructionTick: Int?
    var dangerSaves: Int
    var peakObjectCount: Int
    var peakProjectileCount: Int
    var peakDropCount: Int
    var phase: RunPhase
    var endReason: DescentEndReason?
}

/// Ranked Endless is an additive rules envelope around the proven 60-second
/// combat state. Keeping this classification outside `DescentState` prevents
/// revive or paid-assistance metadata from changing Revision 5 research runs.
enum DescentRankedClass: Int, Codable, Equatable {
    case clean
    case assisted
}

enum DescentEndlessBoosterKind: Codable, Equatable {
    case startingCore(DescentSkillKind)
    case reactorGuard
}

/// Captured once before an Endless run. Both properties are immutable so a
/// later StoreKit/UI refresh cannot retroactively change authoritative combat.
struct DescentEndlessBoosterSnapshot: Codable, Equatable {
    let grantID: UInt64
    let kind: DescentEndlessBoosterKind

    init(grantID: UInt64, kind: DescentEndlessBoosterKind) {
        self.grantID = grantID
        self.kind = kind
    }
}

enum DescentEndlessPhase: Int, Codable, Equatable {
    case playing
    case awaitingRevive
    case finished
}

/// Frozen after every fatal transaction. `combatChecksum` is captured after
/// hit/drop/breach ordering has completed, never before the fatal tick.
struct DescentEndlessFatalCheckpoint: Codable, Equatable {
    let tick: Int
    let score: Int64
    let combatChecksum: UInt64
    let rankedClass: DescentRankedClass
}

struct DescentEndlessPendingRevive: Codable, Equatable {
    let grantID: UInt64
    let applyAtTick: Int
}

struct DescentEndlessState: Codable, Equatable {
    var combat: DescentState
    var rankedClass: DescentRankedClass
    let boosterSnapshot: DescentEndlessBoosterSnapshot?
    var phase: DescentEndlessPhase
    var fatalCheckpoint: DescentEndlessFatalCheckpoint?
    var pendingRevive: DescentEndlessPendingRevive?
    var revivesUsed: Int

    var level: Int {
        1 + max(0, combat.tick) / GameRules.descentEndlessLevelDurationTicks
    }

    /// A score can only enter the clean board while the same authoritative run
    /// is still clean. Accepting a verified revive permanently makes it false.
    var canSubmitFatalScoreToCleanLeaderboard: Bool {
        rankedClass == .clean && fatalCheckpoint != nil
    }
}

enum DescentEndlessEvent: Equatable {
    case combat(DescentSimulationEvent)
    case levelAdvanced(Int)
    case fatalCheckpoint(DescentEndlessFatalCheckpoint)
    case reviveScheduled(grantID: UInt64, applyAtTick: Int)
    case revived(grantID: UInt64, tick: Int)
    case finished
}
