import Combine
import SpriteKit
import UIKit

enum DescentSceneMode: Equatable {
    case revision5Daily60
    case rankedEndless(booster: DescentEndlessBoosterSnapshot?)
}

struct DescentSceneSnapshot: Equatable {
    var phase: RunPhase = .ready
    var elapsedSeconds: Double = 0
    var remainingSeconds: Int = 60
    var score = 0
    var combo = 0
    var maxCombo = 0
    var reactorHP = 3
    var dangerSaves = 0
    var lane = 3
    var activeObjects = 0
    var shipKind: DescentShipKind = .interceptor
    var skills = DescentSkillLevels()
    var choiceArenaPresented = false
    var awaitingChoice = false
    var arenaChoice: DescentArenaChoice?
    var redlineBonusScore = 0
    var flowMode: DescentFlowMode = .calm
    var frenzyCharge = 0
    var frenzyRemainingTicks = 0
    var frenzyBonusScore = 0
    var frenzyActivationCount = 0
    var lastCollectedSkill: DescentSkillKind?
    var isRankedEndless = false
    var level = 1
    var threatTier = 0
    var enemyProjectileCount = 0
    var rankedClass: DescentRankedClass = .clean
    var awaitingRevive = false
    var revivesUsed = 0
    var fatalCheckpointScore: Int?
    var fatalCheckpointTick: Int?
    var fatalCheckpointVerified = false
    var feedback = "끌어서 조준 · 자동 발사"
}

enum DescentSceneEvent {
    case snapshot(DescentSceneSnapshot)
    case objectDestroyed(points: Int)
    case skillCollected(kind: DescentSkillKind, level: Int)
    case reactorDamaged(remainingHP: Int)
    case cleanCheckpoint(
        snapshot: DescentSceneSnapshot,
        checkpoint: DescentEndlessFatalCheckpoint,
        verified: Bool
    )
    case rankedClassChanged(DescentRankedClass)
    case finished(snapshot: DescentSceneSnapshot, reason: DescentEndReason)
}

@MainActor
protocol DescentGameSceneDelegate: AnyObject {
    func descentGameScene(_ scene: DescentGameScene, didEmit event: DescentSceneEvent)
}

/// Non-authoritative SpriteKit presentation for the deterministic Descent rules engine.
/// Procedural art is isolated behind `DescentProceduralArtFactory` so approved, transparent
/// named textures can replace it without changing simulation or scene coordination.
@MainActor
final class DescentGameScene: SKScene, ObservableObject {
    weak var gameDelegate: DescentGameSceneDelegate?
    @Published private(set) var snapshot = DescentSceneSnapshot()
    @Published private(set) var researchPersistenceError: String? = nil

    private let seed: UInt64
    private let mode: DescentSceneMode
    private var state: DescentState
    private var endlessState: DescentEndlessState?
    private var endlessInputTrace: [Int] = []
    private var fatalCheckpointVerified = false
    private var targetPlayerX = Double(GameRules.descentLaneXPoints[2])
    private var lastUpdateTime: TimeInterval = 0
    private var accumulator: TimeInterval = 0
    private var snapshotAccumulator: TimeInterval = 0
    private var runFinished = false
    private var reduceMotion = false
    private var lastCollectedSkill: DescentSkillKind?
    private let artFactory = DescentProceduralArtFactory()

    private let backgroundRoot = SKNode()
    private let laneRoot = SKNode()
    private let dangerRoot = SKNode()
    private let objectRoot = SKNode()
    private let skillCueRoot = SKNode()
    private let effectRoot = SKNode()
    private let projectileRoot = SKNode()
    private let enemyProjectileRoot = SKNode()
    private let dropRoot = SKNode()
    private let playerRoot = SKNode()
    private let warningRoot = SKNode()
    private let playerNode = SKNode()

    private var objectNodes: [Int: SKNode] = [:]
    private var projectileNodes: [Int: SKNode] = [:]
    private var enemyProjectileNodes: [Int: SKNode] = [:]
    private var dropNodes: [Int: SKNode] = [:]
    private var warningLane: Int?
    private var announcedHostileFire = false

    // Research telemetry is deliberately aggregate-only and never enters the
    // authoritative state/checksum. The session is absent in normal builds.
    private let researchSession: DescentResearchSession?
    private let researchVariant: DescentResearchVariant
    private var isResearchTouchActive = false
    private var activeTouchTicks = 0
    private var firstMoveTick: Int?
    private var confirmedResearchLane = 2
    private var candidateResearchLane: Int?
    private var candidateResearchLaneTick = 0
    private var meaningfulLaneChanges = 0
    private var researchDropsCollected = 0
    private var researchBreaches = 0
    private var choicePresentedUptime: TimeInterval?
    private var choiceSuspendedUptime: TimeInterval?
    private var choiceSuspendedDuration: TimeInterval = 0

    init(
        size: CGSize = CGSize(width: GameRules.descentFieldWidth, height: GameRules.descentFieldHeight),
        seed: UInt64,
        ship: DescentShipKind = .interceptor,
        researchSession: DescentResearchSession? = nil,
        researchVariant: DescentResearchVariant = .choiceArena,
        mode: DescentSceneMode = .revision5Daily60
    ) {
        self.seed = seed
        self.mode = mode
        switch mode {
        case .revision5Daily60:
            self.state = GameRules.initialDescentState(seed: seed, shipKind: ship)
            self.endlessState = nil
        case .rankedEndless(let booster):
            let endless = GameRules.initialDescentEndlessState(
                seed: seed,
                shipKind: ship,
                boosterSnapshot: booster
            )
            self.state = endless.combat
            self.endlessState = endless
        }
        self.researchSession = researchSession
        self.researchVariant = researchVariant
        super.init(size: size)
        // Preserve the complete authoritative 390×844 playfield on short devices.
        // Cropping either spawn or reactor space would change what the player can react to.
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = UIColor(hex: GamePalette.canvasHex)
#if DEBUG
        if case .rankedEndless = mode,
           ProcessInfo.processInfo.arguments.contains("-uiTestingEndlessFatal") {
            self.state.player.reactorHP = 1
            self.endlessState?.combat = self.state
        }
        if case .rankedEndless = mode,
           ProcessInfo.processInfo.arguments.contains("-uiTestingEndlessLevelBoundary") {
            self.state.tick = GameRules.descentEndlessLevelDurationTicks - 12
            self.state.nextSpawnTick = self.state.tick + 1
            self.state.player.reactorHP = 99
            self.endlessState?.combat = self.state
        }
        if case .rankedEndless = mode,
           ProcessInfo.processInfo.arguments.contains("-uiTestingEndlessCombatShowcase") {
            self.state.tick = GameRules.descentEndlessLevelDurationTicks - 1
            self.state.score = 25_000
            self.state.nextSpawnTick = .max
            self.state.forcedCarrierIndex = 3
            self.state.player.reactorHP = 99
            self.state.skills.levels.electric = 3
            self.state.skills.levels.wind = 3
            self.state.skills.latestEffect = .wind
            self.state.skills.loadoutVersion = 2
            let fallQ = GameRules.descentQ(fromPoints: 90.0 / Double(GameRules.descentTickRate))
            self.state.objects = [
                DescentObject(id: 101, kind: .brute, lane: 0,
                    yQ: GameRules.descentQ(fromPoints: 340), hitPoints: 99,
                    maximumHitPoints: 99, fallSpeedQPerTick: fallQ,
                    spawnedAtTick: self.state.tick, dropKind: nil, enemyAttackAtTick: nil),
                DescentObject(id: 102, kind: .armored, lane: 1,
                    yQ: GameRules.descentQ(fromPoints: 240), hitPoints: 99,
                    maximumHitPoints: 99, fallSpeedQPerTick: fallQ,
                    spawnedAtTick: self.state.tick, dropKind: nil, enemyAttackAtTick: nil),
                DescentObject(id: 103, kind: .normal, lane: 2,
                    yQ: GameRules.descentQ(fromPoints: 250), hitPoints: 99,
                    maximumHitPoints: 99, fallSpeedQPerTick: fallQ,
                    spawnedAtTick: self.state.tick, dropKind: nil, enemyAttackAtTick: nil),
                DescentObject(id: 104, kind: .normal, lane: 3,
                    yQ: GameRules.descentQ(fromPoints: 260), hitPoints: 99,
                    maximumHitPoints: 99, fallSpeedQPerTick: fallQ,
                    spawnedAtTick: self.state.tick, dropKind: nil, enemyAttackAtTick: nil),
                DescentObject(id: 105, kind: .core, lane: 4,
                    yQ: GameRules.descentQ(fromPoints: 230), hitPoints: 99,
                    maximumHitPoints: 99, fallSpeedQPerTick: fallQ,
                    spawnedAtTick: self.state.tick, dropKind: .electric, enemyAttackAtTick: nil),
                DescentObject(id: 106, kind: .drone, lane: 4,
                    yQ: GameRules.descentQ(fromPoints: 420), hitPoints: 99,
                    maximumHitPoints: 99, fallSpeedQPerTick: fallQ,
                    spawnedAtTick: self.state.tick, dropKind: nil,
                    enemyAttackAtTick: self.state.tick + GameRules.descentEnemyAttackTelegraphTicks)
            ]
            self.state.nextObjectID = 107
            self.endlessState?.combat = self.state
        }
#endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        guard backgroundRoot.parent == nil else { return }
        view.isMultipleTouchEnabled = false
        buildField()
        syncEntityNodes()
        syncSnapshot(feedback: "끌어서 조준 · 자동 발사")
        emitSnapshot()
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-uiTestingGPTAssetShowcase") {
            startGPTAssetVisualQA()
        }
#endif
    }

    override func update(_ currentTime: TimeInterval) {
        guard canAdvanceSimulation, !runFinished else { return }
        guard lastUpdateTime != 0 else {
            lastUpdateTime = currentTime
            return
        }

        let frameDelta = max(0, min(0.25, currentTime - lastUpdateTime))
        lastUpdateTime = currentTime
        accumulator += frameDelta
        snapshotAccumulator += frameDelta

        var simulationEvents: [DescentSimulationEvent] = []
        var steps = 0
        while accumulator >= GameRules.descentTickDuration, steps < 30 {
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-uiTestingDescentRecordingDemo") {
                targetPlayerX = recordingTargetX()
            }
#endif
            let input = DescentInput(targetX: targetPlayerX)
            switch mode {
            case .revision5Daily60:
                simulationEvents.append(
                    contentsOf: GameRules.stepDescent(state: &state, input: input)
                )
            case .rankedEndless:
                guard var endless = endlessState else { break }
                endlessInputTrace.append(input.targetXPoints)
                let endlessEvents = GameRules.stepDescentEndless(
                    state: &endless,
                    input: input
                )
                endlessState = endless
                state = endless.combat
                processEndless(endlessEvents)
#if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-uiTestingEndlessCombatShowcase") {
                    let anchors: [Int: Double] = [
                        101: 340, 102: 240, 103: 250,
                        104: 260, 105: 230, 106: 420
                    ]
                    for index in state.objects.indices {
                        if let y = anchors[state.objects[index].id] {
                            state.objects[index].yQ = GameRules.descentQ(fromPoints: y)
                        }
                        if state.objects[index].id == 106,
                           state.objects[index].enemyAttackAtTick == nil,
                           state.enemyProjectiles.isEmpty {
                            state.objects[index].enemyAttackAtTick = state.tick
                                + GameRules.descentEnemyAttackTelegraphTicks
                        }
                    }
                    // Keep the hostile bolt on-screen long enough for an accessibility
                    // snapshot and screenshot. Production projectile speed/resolution
                    // remains authoritative and is covered by GameRules tests.
                    let captureFloorQ = GameRules.descentQ(fromPoints: 250)
                    for index in state.enemyProjectiles.indices {
                        state.enemyProjectiles[index].yQ = max(
                            captureFloorQ,
                            state.enemyProjectiles[index].yQ
                        )
                    }
                    endless.combat = state
                    endlessState = endless
                }
#endif
            }
            if researchVariant == .noArena, state.choiceArena.isAwaitingChoice {
                simulationEvents.append(
                    contentsOf: GameRules.resolveDescentChoiceArena(
                        state: &state,
                        choice: .steady
                    )
                )
            }
            if isResearchTouchActive { activeTouchTicks += 1 }
            updateResearchLaneChanges()
            accumulator -= GameRules.descentTickDuration
            steps += 1
            if simulationShouldStopThisFrame { break }
        }
        if steps == 30 { accumulator = 0 }

#if DEBUG
        if mode == .revision5Daily60,
           ProcessInfo.processInfo.arguments.contains("-uiTestingChoiceArena"),
           state.phase == .playing,
           state.tick >= 2 * GameRules.descentTickRate,
           !state.choiceArena.wasPresented {
            simulationEvents.append(
                contentsOf: GameRules.presentDescentChoiceArena(state: &state)
            )
        }
#endif

        // The early UI-test hook presents outside the fixed-tick loop. Keep the
        // research control equally seamless by resolving that synthetic pause
        // before any frame is rendered.
        if researchVariant == .noArena, state.choiceArena.isAwaitingChoice {
            simulationEvents.append(
                contentsOf: GameRules.resolveDescentChoiceArena(
                    state: &state,
                    choice: .steady
                )
            )
        }

        process(simulationEvents)

#if DEBUG
        if mode == .revision5Daily60,
           ProcessInfo.processInfo.arguments.contains("-uiTestingDescentFastFinish"),
           state.phase == .playing,
           state.tick >= 8 * GameRules.descentTickRate {
            state.tick = 60 * GameRules.descentTickRate
            state.phase = .finished
            state.endReason = .survivedSixtySeconds
        }
#endif

        syncEntityNodes()
        updateDangerWarning()
        syncSnapshot()

        if snapshotAccumulator >= 0.05 {
            snapshotAccumulator = 0
            emitSnapshot()
        }
        if runReachedFinishedPhase { finishRun() }
    }

    private var canAdvanceSimulation: Bool {
        switch mode {
        case .revision5Daily60:
            return state.phase == .playing
        case .rankedEndless:
            guard let endlessState else { return false }
            return endlessState.phase == .playing
                || (endlessState.phase == .awaitingRevive && endlessState.pendingRevive != nil)
        }
    }

    private var simulationShouldStopThisFrame: Bool {
        switch mode {
        case .revision5Daily60:
            return state.phase == .finished
        case .rankedEndless:
            return endlessState?.phase != .playing
        }
    }

    private var runReachedFinishedPhase: Bool {
        switch mode {
        case .revision5Daily60:
            return state.phase == .finished
        case .rankedEndless:
            return endlessState?.phase == .finished
        }
    }

#if DEBUG
    /// Uses the same deterministic threat/drop priority as the core QA reference controller.
    /// This selects input only; spawn, collision, score, skills and failure remain authoritative.
    private func recordingTargetX() -> Double {
        let dangerQ = GameRules.descentQ(fromPoints: GameRules.descentDangerY)
        let playerYQ = GameRules.descentQ(fromPoints: GameRules.descentPlayerY)
        let projectileDelta = GameRules.descentQ(fromPoints: 780.0 / Double(GameRules.descentTickRate))
        let windPercent = Int64(state.skills.windMultiplierPercent)

        func slack(for object: DescentObject) -> Int64 {
            let fallDelta = max(1, object.fallSpeedQPerTick * windPercent / 100)
            let dangerTicks = max(0, object.yQ - dangerQ) / fallDelta
            let interceptTicks = max(0, object.yQ - playerYQ) / (projectileDelta + fallDelta)
            let followupTicks = Int64(max(0, object.hitPoints - 1) * GameRules.descentAutoFireIntervalTicks)
            return dangerTicks - interceptTicks - followupTicks
        }

        let threat = state.objects.min { lhs, rhs in
            let left = slack(for: lhs)
            let right = slack(for: rhs)
            return left == right ? lhs.id < rhs.id : left < right
        }
        let threatSlack = threat.map(slack) ?? .max
        let targetLane: Int
        if threatSlack > 90,
           let drop = state.drops.min(by: {
               $0.yQ == $1.yQ ? $0.id < $1.id : $0.yQ < $1.yQ
           }) {
            targetLane = drop.lane
        } else {
            targetLane = threat?.lane ?? 2
        }
        return Double(GameRules.descentLaneXPoints[targetLane])
    }
#endif

    func setReduceMotion(_ enabled: Bool) {
        reduceMotion = enabled
        if enabled {
            effectRoot.removeAllChildren()
            skillCueRoot.removeAllChildren()
            backgroundRoot.removeAction(forKey: "fieldDrift")
        } else {
            startFieldDrift()
        }
    }

    private func resetSimulationClock() {
        lastUpdateTime = 0
        accumulator = 0
        snapshotAccumulator = 0
    }

    func setRunPaused(_ paused: Bool) {
        guard !runFinished else { return }
        guard endlessState?.phase != .awaitingRevive else { return }
        if paused { isResearchTouchActive = false }
        if state.choiceArena.isAwaitingChoice {
            // Foregrounding alone must not resume a run hidden behind the Arena.
            // Resolving the explicit player choice is the only Arena resume gesture.
            if paused {
                isPaused = true
                if choiceSuspendedUptime == nil {
                    choiceSuspendedUptime = ProcessInfo.processInfo.systemUptime
                }
            }
            resetSimulationClock()
            syncSnapshot(feedback: "CHOICE ARENA · 기록을 걸까요?")
            emitSnapshot()
            return
        }
        if paused, state.phase == .playing {
            state.phase = .paused
            isPaused = true
        } else if !paused, state.phase == .paused {
            state.phase = .playing
            resetSimulationClock()
            isPaused = false
        }
        if var endless = endlessState {
            endless.combat = state
            endlessState = endless
        }
        syncSnapshot(feedback: paused ? "RUN PAUSED" : nil)
        emitSnapshot()
    }

    @discardableResult
    func scheduleVerifiedMockRevive(grantID: UInt64) -> Bool {
        guard var endless = endlessState else { return false }
        let previousClass = endless.rankedClass
        let events = GameRules.scheduleVerifiedMockDescentEndlessRevive(
            state: &endless,
            grantID: grantID
        )
        guard !events.isEmpty else { return false }
        endlessState = endless
        state = endless.combat
        if endless.rankedClass != previousClass {
            gameDelegate?.descentGameScene(
                self,
                didEmit: .rankedClassChanged(endless.rankedClass)
            )
        }
        processEndless(events)
        resetSimulationClock()
        syncSnapshot(feedback: "ASSISTED · 다음 틱부터 리액터 복구")
        emitSnapshot()
        return true
    }

    func declineEndlessRevive() {
        guard var endless = endlessState else { return }
        let events = GameRules.declineDescentEndlessRevive(state: &endless)
        guard !events.isEmpty else { return }
        endlessState = endless
        state = endless.combat
        processEndless(events)
        syncSnapshot(feedback: "CLEAN CHECKPOINT 확정")
        emitSnapshot()
        if endless.phase == .finished { finishRun() }
    }

    func resolveChoiceArena(_ choice: DescentArenaChoice) {
        guard mode == .revision5Daily60 else { return }
        guard state.phase == .playing, state.choiceArena.isAwaitingChoice else { return }
        let events = GameRules.resolveDescentChoiceArena(state: &state, choice: choice)
        guard !events.isEmpty else { return }
        process(events)
        targetPlayerX = GameRules.descentPoints(fromQ: state.player.xQ)
        resetSimulationClock()
        isPaused = false
        syncSnapshot(
            feedback: choice == .redline
                ? "REDLINE · 낙하 +18% · 기본탄 점수 +35%"
                : "안정 비행 · 현재 속도와 점수 유지"
        )
        emitSnapshot()
    }

    func movePlayerLane(by offset: Int) {
        guard state.phase == .playing,
              !runFinished,
              endlessState?.phase != .awaitingRevive,
              !state.choiceArena.isAwaitingChoice else { return }
        let current = nearestLane(to: targetPlayerX)
        let next = min(GameRules.descentLaneXPoints.count - 1, max(0, current + offset))
        recordFirstResearchInputIfNeeded()
        targetPlayerX = Double(GameRules.descentLaneXPoints[next])
        syncSnapshot(feedback: "(next + 1)번 레인으로 이동")
        emitSnapshot()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !state.choiceArena.isAwaitingChoice,
              endlessState?.phase != .awaitingRevive else { return }
        isResearchTouchActive = true
        updateTarget(from: touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !state.choiceArena.isAwaitingChoice else { return }
        updateTarget(from: touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isResearchTouchActive = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isResearchTouchActive = false
    }

    private func updateTarget(from touches: Set<UITouch>) {
        guard state.phase == .playing,
              !runFinished,
              endlessState?.phase != .awaitingRevive,
              !state.choiceArena.isAwaitingChoice,
              let touch = touches.first else { return }
        let point = touch.location(in: self)
        let previousTarget = targetPlayerX
        targetPlayerX = min(
            Double(GameRules.descentFieldWidth),
            max(0, Double(point.x.rounded()))
        )
        if abs(targetPlayerX - previousTarget) >= 1 {
            recordFirstResearchInputIfNeeded()
        }
    }

    private func process(_ events: [DescentSimulationEvent]) {
        for event in events {
            switch event {
            case .objectSpawned:
                break
            case .projectileFired:
                if !reduceMotion { animateMuzzleFlash() }
            case .objectDamaged(let id, _, let cause):
                animateObjectHit(id: id, cause: cause)
            case .objectDestroyed(let id, let cause, let points):
                researchSession?.record(.firstDestroy(tick: state.tick))
                animateObjectDestroyed(id: id, cause: cause)
                gameDelegate?.descentGameScene(self, didEmit: .objectDestroyed(points: points))
            case .dangerSave(let id, _):
                showFloatingText("DANGER SAVE +150", atObject: id, color: UIColor(hex: GamePalette.warningHex))
            case .dropSpawned:
                break
            case .dropCollected(let id, let kind, let level, let display, _):
                researchDropsCollected += 1
                researchSession?.record(.firstDropCollected(tick: state.tick, kind: kind))
                lastCollectedSkill = kind
                animateDropCollected(id: id, kind: kind, level: level, display: display)
                gameDelegate?.descentGameScene(self, didEmit: .skillCollected(kind: kind, level: level))
            case .skillActivated(let kind, let level, _, let targetIDs):
                if kind != .electric, kind != .wind {
                    animateSkill(kind: kind, level: level, targetIDs: targetIDs)
                }
            case .skillCue(let cue):
                animateSkillCue(cue)
            case .enemyProjectileFired(let projectile):
                animateEnemyFire(projectile)
                if !announcedHostileFire {
                    announcedHostileFire = true
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "공격 드론 출현. 붉은 예고 레인을 피하세요."
                    )
                }
            case .enemyProjectileResolved(_, let hitPlayer, _):
                if hitPlayer {
                    showFloatingText(
                        "HOSTILE HIT",
                        at: playerNode.position,
                        color: UIColor(hex: GamePalette.dangerHex)
                    )
                }
            case .fireEchoScheduled:
                break
            case .fireEchoActivated(_, let targetIDs):
                animateFireEcho(targetIDs: targetIDs)
            case .comboChanged(let combo):
                if [5, 10, 20].contains(combo) {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "CHAIN \(combo)"
                    )
                }
            case .frenzyChargeChanged:
                // The authoritative state is projected into the bounded HUD meter
                // during the next snapshot sync. No world-space effect is needed.
                break
            case .frenzyStarted:
                animateBreakFlowPulse()
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "BREAK FLOW 시작, 3초"
                )
            case .frenzyExtended:
                // Remaining time visibly refills in the HUD bar. Repeating the
                // world-space pulse at direct-hit cadence would become a strobe.
                break
            case .frenzyEnded:
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "BREAK FLOW 종료"
                )
            case .frenzyBonus:
                // Total bonus is shown in the HUD. Repeating world-space labels at
                // auto-fire cadence would hide the danger lane and lowest threat.
                break
            case .objectBreached(let id, let reactorDamaged):
                researchBreaches += 1
                animateBreach(id: id, reactorDamaged: reactorDamaged)
            case .reactorChanged(let hp):
                animateReactorDamage()
                gameDelegate?.descentGameScene(self, didEmit: .reactorDamaged(remainingHP: hp))
            case .difficultyAdvanced(let profile):
                showFloatingText("THREAT TIER \(profile.tier)", at: CGPoint(x: 195, y: 668), color: UIColor(hex: GamePalette.warningHex))
            case .choiceArenaPresented(let tick):
                // Cancel a drag target carried into the modal choice. The core player
                // coordinate remains the sole authority until a post-choice input arrives.
                targetPlayerX = GameRules.descentPoints(fromQ: state.player.xQ)
                isResearchTouchActive = false
                resetSimulationClock()
                if researchVariant == .choiceArena {
                    choicePresentedUptime = ProcessInfo.processInfo.systemUptime
                    choiceSuspendedUptime = nil
                    choiceSuspendedDuration = 0
                    researchSession?.record(.choicePresented(tick: tick, score: Int(clamping: state.score)))
                    flushResearchSession()
                    showFloatingText("CHOICE ARENA", at: CGPoint(x: 195, y: 520), color: UIColor(hex: GamePalette.warningHex))
                }
            case .choiceArenaResolved(let choice):
                if researchVariant == .choiceArena {
                    let now = ProcessInfo.processInfo.systemUptime
                    if let suspended = choiceSuspendedUptime {
                        choiceSuspendedDuration += max(0, now - suspended)
                        choiceSuspendedUptime = nil
                    }
                    let latency = choicePresentedUptime.map {
                        max(0, Int(((now - $0 - choiceSuspendedDuration) * 1_000).rounded()))
                    } ?? 0
                    researchSession?.record(.choiceSelected(
                        choice: choice,
                        activeLatencyMilliseconds: latency
                    ))
                    flushResearchSession()
                    showFloatingText(
                        choice == .redline ? "REDLINE ENGAGED" : "STEADY FLIGHT",
                        at: CGPoint(x: 195, y: 520),
                        color: UIColor(hex: choice == .redline ? GamePalette.fireHex : GamePalette.infoHex)
                    )
                }
            case .finished:
                break
            }
        }
    }

    private func processEndless(_ events: [DescentEndlessEvent]) {
        for event in events {
            switch event {
            case .combat(let combatEvent):
                process([combatEvent])
            case .levelAdvanced(let level):
                showFloatingText(
                    "LEVEL \(level)",
                    at: CGPoint(x: 195, y: 590),
                    color: UIColor(hex: GamePalette.warningHex)
                )
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "레벨 \(level), 위협 단계 상승"
                )
            case .fatalCheckpoint(let checkpoint):
                let verified = checkpoint.rankedClass == .clean
                    && verifyFatalCheckpointByReplay(checkpoint)
                fatalCheckpointVerified = verified
                syncSnapshot(
                    feedback: checkpoint.rankedClass == .clean
                        ? "CLEAN CHECKPOINT · 기록 봉인"
                        : "ASSISTED RUN 종료 지점"
                )
                emitSnapshot()
                if checkpoint.rankedClass == .clean {
                    gameDelegate?.descentGameScene(
                        self,
                        didEmit: .cleanCheckpoint(
                            snapshot: snapshot,
                            checkpoint: checkpoint,
                            verified: verified
                        )
                    )
                }
                UIAccessibility.post(
                    notification: .announcement,
                    argument: checkpoint.rankedClass == .clean
                        ? "Clean 기록 \(Int(clamping: checkpoint.score))점이 확정되었습니다. 부활 방법을 선택하세요."
                        : "Assisted 런이 종료되었습니다."
                )
            case .reviveScheduled:
                break
            case .revived:
                state = endlessState?.combat ?? state
                showFloatingText(
                    "ASSISTED RESCUE",
                    at: CGPoint(x: 195, y: 470),
                    color: UIColor(hex: GamePalette.infoHex)
                )
            case .finished:
                break
            }
        }
    }

    /// Ranked records are accepted only when the captured input trace reproduces
    /// the fatal tick and combat checksum from the same immutable seed/loadout.
    private func verifyFatalCheckpointByReplay(
        _ checkpoint: DescentEndlessFatalCheckpoint
    ) -> Bool {
        guard case .rankedEndless(let booster) = mode else { return false }
        var replay = GameRules.initialDescentEndlessState(
            seed: seed,
            shipKind: state.shipKind,
            boosterSnapshot: booster
        )
        for targetXPoints in endlessInputTrace {
            let events = GameRules.stepDescentEndless(
                state: &replay,
                input: DescentInput(targetXPoints: targetXPoints)
            )
            if let reproduced = events.compactMap({ event -> DescentEndlessFatalCheckpoint? in
                guard case .fatalCheckpoint(let value) = event else { return nil }
                return value
            }).first {
                return reproduced == checkpoint
                    && replay.combat.tick == checkpoint.tick
                    && GameRules.descentChecksum(replay.combat) == checkpoint.combatChecksum
            }
        }
        return false
    }

    private func buildField() {
        backgroundRoot.zPosition = -100
        laneRoot.zPosition = -50
        dangerRoot.zPosition = 0
        objectRoot.zPosition = 20
        effectRoot.zPosition = 25
        skillCueRoot.zPosition = 26
        projectileRoot.zPosition = 30
        enemyProjectileRoot.zPosition = 34
        dropRoot.zPosition = 35
        playerRoot.zPosition = 40
        warningRoot.zPosition = 50

        [backgroundRoot, laneRoot, dangerRoot, objectRoot, effectRoot, skillCueRoot, projectileRoot, enemyProjectileRoot, dropRoot, playerRoot, warningRoot]
            .forEach(addChild)

        let backdrop = SKShapeNode(rectOf: CGSize(width: 390, height: 844))
        backdrop.position = CGPoint(x: 195, y: 422)
        backdrop.fillColor = UIColor(hex: GamePalette.canvasHex)
        backdrop.strokeColor = .clear
        backgroundRoot.addChild(backdrop)

        let lowerGlow = SKShapeNode(ellipseOf: CGSize(width: 330, height: 180))
        lowerGlow.position = CGPoint(x: 195, y: 90)
        lowerGlow.fillColor = UIColor(hex: GamePalette.fireHex, alpha: 0.075)
        lowerGlow.strokeColor = UIColor(hex: GamePalette.fireHex, alpha: 0.18)
        lowerGlow.glowWidth = 16
        backgroundRoot.addChild(lowerGlow)

        for index in 0..<18 {
            let streak = SKShapeNode(rectOf: CGSize(width: 1.2, height: CGFloat(22 + (index % 4) * 12)))
            streak.position = CGPoint(x: CGFloat(14 + (index * 43) % 370), y: CGFloat(158 + (index * 97) % 620))
            streak.fillColor = UIColor(hex: index.isMultiple(of: 4) ? GamePalette.fireHex : GamePalette.infoHex, alpha: 0.10)
            streak.strokeColor = .clear
            backgroundRoot.addChild(streak)
        }

        for lane in GameRules.descentLaneXPoints {
            let laneGuide = SKShapeNode(rectOf: CGSize(width: 68, height: 620), cornerRadius: 8)
            laneGuide.position = CGPoint(x: lane, y: 430)
            laneGuide.fillColor = UIColor(hex: GamePalette.surface1Hex, alpha: 0.16)
            laneGuide.strokeColor = UIColor(hex: GamePalette.infoHex, alpha: 0.12)
            laneGuide.lineWidth = 1
            laneRoot.addChild(laneGuide)

            let center = SKShapeNode(rectOf: CGSize(width: 1, height: 600))
            center.position = CGPoint(x: lane, y: 430)
            center.fillColor = UIColor(hex: GamePalette.infoHex, alpha: 0.09)
            center.strokeColor = .clear
            laneRoot.addChild(center)
        }

        buildDangerLine()
        playerNode.addChild(artFactory.makePlayer(ship: state.shipKind))
        playerNode.position = CGPoint(x: 195, y: GameRules.descentPlayerY)
        playerRoot.addChild(playerNode)
        startFieldDrift()
    }

    private func buildDangerLine() {
        let line = SKShapeNode(rectOf: CGSize(width: 390, height: 2))
        line.position = CGPoint(x: 195, y: GameRules.descentDangerY)
        line.fillColor = UIColor(hex: GamePalette.dangerHex, alpha: 0.86)
        line.strokeColor = .clear
        line.glowWidth = 4
        dangerRoot.addChild(line)

        for x in stride(from: -10, through: 390, by: 22) {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(x), y: CGFloat(GameRules.descentDangerY - 9)))
            path.addLine(to: CGPoint(x: CGFloat(x + 11), y: CGFloat(GameRules.descentDangerY + 9)))
            let hatch = SKShapeNode(path: path)
            hatch.strokeColor = UIColor(hex: GamePalette.dangerHex, alpha: 0.33)
            hatch.lineWidth = 2
            dangerRoot.addChild(hatch)
        }

        let dangerLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        dangerLabel.text = "DANGER  //  REACTOR LINE"
        dangerLabel.fontSize = 9
        dangerLabel.fontColor = UIColor(hex: GamePalette.dangerHex)
        dangerLabel.horizontalAlignmentMode = .left
        dangerLabel.position = CGPoint(x: 12, y: CGFloat(GameRules.descentDangerY + 10))
        dangerRoot.addChild(dangerLabel)
    }

    private func startFieldDrift() {
        guard !reduceMotion, backgroundRoot.action(forKey: "fieldDrift") == nil else { return }
        backgroundRoot.run(
            .repeatForever(.sequence([
                .moveBy(x: 0, y: -4, duration: 2.4),
                .moveBy(x: 0, y: 4, duration: 0)
            ])),
            withKey: "fieldDrift"
        )
    }

    private func syncEntityNodes() {
        let objectIDs = Set(state.objects.map(\.id))
        for object in state.objects {
            let node = objectNodes[object.id] ?? {
                let node = artFactory.makeObject(object)
                objectRoot.addChild(node)
                objectNodes[object.id] = node
                return node
            }()
            node.position = CGPoint(x: laneX(object.lane), y: points(object.yQ))
            artFactory.updateObject(
                node,
                object: object,
                currentTick: state.tick,
                threatTier: endlessState.map {
                    GameRules.descentEndlessThreatTier(
                        score: $0.combat.score,
                        tick: $0.combat.tick
                    )
                }
            )
        }
        for id in Set(objectNodes.keys).subtracting(objectIDs) {
            guard let node = objectNodes[id] else { continue }
            if node.parent === objectRoot { node.removeFromParent() }
            objectNodes[id] = nil
        }

        let projectileIDs = Set(state.projectiles.map(\.id))
        for projectile in state.projectiles {
            let node = projectileNodes[projectile.id] ?? {
                let node = artFactory.makeProjectile(projectile)
                projectileRoot.addChild(node)
                projectileNodes[projectile.id] = node
                return node
            }()
            node.position = CGPoint(x: laneX(projectile.lane), y: points(projectile.yQ))
        }
        for id in Set(projectileNodes.keys).subtracting(projectileIDs) {
            guard let node = projectileNodes[id] else { continue }
            node.removeFromParent()
            projectileNodes[id] = nil
        }

        let enemyProjectileIDs = Set(state.enemyProjectiles.map(\.id))
        for projectile in state.enemyProjectiles {
            let node = enemyProjectileNodes[projectile.id] ?? {
                let node = artFactory.makeEnemyProjectile()
                enemyProjectileRoot.addChild(node)
                enemyProjectileNodes[projectile.id] = node
                return node
            }()
            node.position = CGPoint(x: laneX(projectile.lane), y: points(projectile.yQ))
        }
        for id in Set(enemyProjectileNodes.keys).subtracting(enemyProjectileIDs) {
            enemyProjectileNodes[id]?.removeFromParent()
            enemyProjectileNodes[id] = nil
        }

        let dropIDs = Set(state.drops.map(\.id))
        for drop in state.drops {
            let node = dropNodes[drop.id] ?? {
                let node = artFactory.makeDrop(drop.kind)
                dropRoot.addChild(node)
                dropNodes[drop.id] = node
                if !reduceMotion {
                    node.run(.repeatForever(.sequence([
                        .scale(to: 1.08, duration: 0.36),
                        .scale(to: 0.96, duration: 0.36)
                    ])), withKey: "pulse")
                }
                return node
            }()
            node.position = CGPoint(x: laneX(drop.lane), y: points(drop.yQ))
        }
        for id in Set(dropNodes.keys).subtracting(dropIDs) {
            guard let node = dropNodes[id] else { continue }
            if node.parent === dropRoot { node.removeFromParent() }
            dropNodes[id] = nil
        }

        playerNode.position = CGPoint(x: points(state.player.xQ), y: GameRules.descentPlayerY)
    }

    private func updateDangerWarning() {
        let threat = state.objects
            .filter { points($0.yQ) < Double(GameRules.descentDangerY + 96) }
            .min { lhs, rhs in
                if lhs.yQ != rhs.yQ { return lhs.yQ < rhs.yQ }
                return lhs.id < rhs.id
            }
        guard threat?.lane != warningLane else { return }
        warningRoot.removeAllChildren()
        warningLane = threat?.lane
        guard let lane = threat?.lane else { return }
        let chevron = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        chevron.text = "▼"
        chevron.fontSize = 22
        chevron.fontColor = UIColor(hex: GamePalette.dangerHex)
        chevron.position = CGPoint(x: laneX(lane), y: GameRules.descentDangerY + 24)
        warningRoot.addChild(chevron)
        if !reduceMotion {
            chevron.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.45, duration: 0.28),
                .fadeAlpha(to: 1, duration: 0.28)
            ])))
        }
    }

    private func animateObjectHit(id: Int, cause: DescentDamageCause) {
        guard let source = objectNodes[id] else { return }
        if !reduceMotion {
            source.removeAction(forKey: "hit")
            source.run(.sequence([
                .scale(to: 1.10, duration: 0.035),
                .scale(to: 1, duration: 0.035)
            ]), withKey: "hit")
        }
        let color = color(for: cause)
        for index in 0..<(reduceMotion ? 1 : 4) {
            let spark = SKShapeNode(rectOf: CGSize(width: 2, height: 8), cornerRadius: 1)
            spark.position = source.position
            spark.zRotation = CGFloat(index) * .pi / 2
            spark.fillColor = color
            spark.strokeColor = .clear
            addTransient(spark)
            spark.run(.sequence([
                .group([
                    .moveBy(x: cos(spark.zRotation) * 16, y: sin(spark.zRotation) * 16, duration: 0.14),
                    .fadeOut(withDuration: 0.14)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func animateObjectDestroyed(id: Int, cause: DescentDamageCause) {
        guard let source = objectNodes.removeValue(forKey: id) else { return }
        let position = source.position
        source.removeFromParent()
        let color = color(for: cause)
        let ring = SKShapeNode(circleOfRadius: 18)
        ring.position = position
        ring.strokeColor = color
        ring.fillColor = UIColor(hex: GamePalette.surface0Hex, alpha: 0.18)
        ring.lineWidth = 3
        addTransient(ring)
        ring.run(.sequence([
            .group([
                .scale(to: reduceMotion ? 1.1 : 2.0, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
        if !reduceMotion {
            for index in 0..<8 {
                let fragment = SKShapeNode(rectOf: CGSize(width: 5, height: 5), cornerRadius: 1)
                fragment.position = position
                fragment.fillColor = index.isMultiple(of: 2) ? color : UIColor(hex: GamePalette.borderStrongHex)
                fragment.strokeColor = .clear
                addTransient(fragment)
                let angle = CGFloat(index) * .pi / 4
                fragment.run(.sequence([
                    .group([
                        .moveBy(x: cos(angle) * 30, y: sin(angle) * 30, duration: 0.2),
                        .rotate(byAngle: .pi, duration: 0.2),
                        .fadeOut(withDuration: 0.2)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
    }

    private func animateDropCollected(
        id: Int,
        kind: DescentSkillKind,
        level: Int,
        display: DescentEffectLevelDisplay
    ) {
        let pickupNode = dropNodes.removeValue(forKey: id)
        let color = color(for: kind)
        if let pickupNode {
            pickupNode.run(.sequence([
                .group([
                    .move(to: playerNode.position, duration: reduceMotion ? 0.06 : 0.12),
                    .scale(to: 0.25, duration: reduceMotion ? 0.06 : 0.12),
                    .fadeOut(withDuration: reduceMotion ? 0.06 : 0.12)
                ]),
                .removeFromParent()
            ]))
        }

        let ringCount = reduceMotion ? 1 : 3
        for index in 0..<ringCount {
            let ring = SKShapeNode(circleOfRadius: 18 + CGFloat(index * 4))
            ring.position = playerNode.position
            ring.strokeColor = color.withAlphaComponent(0.88 - CGFloat(index) * 0.14)
            ring.fillColor = .clear
            ring.lineWidth = index == 0 ? 4 : 2
            addTransient(ring)
            let delay = reduceMotion ? 0 : Double(index) * 0.065
            ring.run(.sequence([
                .wait(forDuration: delay),
                .group([
                    .scale(to: reduceMotion ? 1.35 : 2.75, duration: reduceMotion ? 0.16 : 0.38),
                    .fadeOut(withDuration: reduceMotion ? 0.16 : 0.38)
                ]),
                .removeFromParent()
            ]))
        }

        let motif = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.skillTexture(for: kind),
            size: CGSize(width: 38, height: 38),
            zPosition: 0
        )
        motif.position = playerNode.position
        motif.alpha = 0.9
        addTransient(motif)
        motif.run(.sequence([
            .group([
                .scale(to: reduceMotion ? 1.05 : 1.55, duration: 0.2),
                .fadeOut(withDuration: reduceMotion ? 0.2 : 0.34)
            ]),
            .removeFromParent()
        ]))

        if !reduceMotion {
            for index in 0..<12 {
                let particle = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 2.4 : 1.4)
                particle.position = playerNode.position
                particle.fillColor = color
                particle.strokeColor = .clear
                addTransient(particle)
                let angle = CGFloat(index) * .pi * 2 / 12
                let distance: CGFloat = index.isMultiple(of: 2) ? 48 : 36
                particle.run(.sequence([
                    .group([
                        .moveBy(
                            x: cos(angle) * distance,
                            y: sin(angle) * distance,
                            duration: 0.32
                        ),
                        .fadeOut(withDuration: 0.32)
                    ]),
                    .removeFromParent()
                ]))
            }
        }

        let displayText = display == .maximum ? "MAX" : display.rawValue
        showFloatingText(
            "\(skillName(kind)) \(displayText)",
            at: CGPoint(x: playerNode.position.x, y: playerNode.position.y + 52),
            color: color
        )
    }

    private func animateSkill(kind: DescentSkillKind, level: Int, targetIDs: [Int]) {
        let color = color(for: kind)
        let positions = targetIDs.compactMap { objectNodes[$0]?.position }
        let catalogPosition = positions.first ?? CGPoint(x: playerNode.position.x, y: 300)
        let catalogVFX = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.skillVFXTexture(for: kind),
            size: CGSize(width: kind == .wind ? 138 : 108, height: kind == .wind ? 154 : 138),
            zPosition: 0
        )
        catalogVFX.position = catalogPosition
        catalogVFX.alpha = reduceMotion ? 0.42 : 0.58
        addTransient(catalogVFX)
        catalogVFX.run(.sequence([
            .group([
                .scale(to: reduceMotion ? 1.02 : 1.12, duration: reduceMotion ? 0.06 : 0.09),
                .fadeOut(withDuration: reduceMotion ? 0.06 : 0.09)
            ]),
            .removeFromParent()
        ]))
        switch kind {
        case .fire:
            for position in positions.prefix(5) { addVerticalBeam(at: position, color: color, width: 8) }
        case .electric:
            guard !positions.isEmpty else { return }
            let path = CGMutablePath()
            path.move(to: playerNode.position)
            for (index, position) in positions.prefix(5).enumerated() {
                let jitter: CGFloat = index.isMultiple(of: 2) ? 7 : -7
                path.addLine(to: CGPoint(x: position.x + jitter, y: position.y - 10))
                path.addLine(to: position)
            }
            let bolt = SKShapeNode(path: path)
            bolt.strokeColor = color
            bolt.lineWidth = 3
            bolt.glowWidth = 5
            addTransient(bolt)
            bolt.run(.sequence([.wait(forDuration: reduceMotion ? 0.06 : 0.14), .removeFromParent()]))
        case .pierce:
            addVerticalBeam(at: CGPoint(x: playerNode.position.x, y: 420), color: color, width: CGFloat(3 + level))
        case .wind:
            for offset: CGFloat in [-18, 0, 18] {
                let arc = SKShapeNode(ellipseOf: CGSize(width: 250 + offset, height: 72 + offset / 2))
                arc.position = CGPoint(x: 195, y: 360 + offset * 2)
                arc.strokeColor = color.withAlphaComponent(0.72)
                arc.fillColor = .clear
                arc.lineWidth = 3
                addTransient(arc)
                arc.run(.sequence([
                    .group([
                        .moveBy(x: 0, y: reduceMotion ? 8 : 64, duration: 0.25),
                        .fadeOut(withDuration: 0.25)
                    ]),
                    .removeFromParent()
                ]))
            }
        case .explosion:
            let center = positions.first ?? CGPoint(x: playerNode.position.x, y: 280)
            let ring = SKShapeNode(circleOfRadius: CGFloat(36 + level * 8))
            ring.position = center
            ring.strokeColor = color
            ring.fillColor = color.withAlphaComponent(0.13)
            ring.lineWidth = 5
            addTransient(ring)
            ring.run(.sequence([
                .group([
                    .scale(to: reduceMotion ? 1.1 : 1.65, duration: 0.22),
                    .fadeOut(withDuration: 0.22)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func animateSkillCue(_ cue: DescentSkillActivationCue) {
        switch cue.kind {
        case .electric:
            renderElectricCue(cue)
        case .wind:
            renderWindCue(cue)
        default:
            break
        }
    }

#if DEBUG
    /// Deterministic presentation-only harness for Imagegen + Vision review.
    /// It never enters `GameRules`, mutates score, or changes authoritative targets.
    private func startGPTAssetVisualQA() {
        let point: (Int) -> DescentEffectPoint? = { [weak self] objectID in
            guard let self,
                  let object = self.state.objects.first(where: { $0.id == objectID }) else {
                return nil
            }
            return DescentEffectPoint(
                objectID: object.id,
                xQ: GameRules.descentQ(fromPoints: Double(self.laneX(object.lane))),
                yQ: object.yQ
            )
        }
        guard let origin = point(103) else { return }
        let electricTargets = [101, 102, 104, 105, 106].compactMap(point)
        let windTargets = [102, 103, 104].compactMap(point)

        run(
            .repeatForever(
                .sequence([
                    .run { [weak self] in
                        self?.renderElectricCue(
                            DescentSkillActivationCue(
                                kind: .electric,
                                level: 3,
                                activationID: 90_001,
                                origin: origin,
                                targets: electricTargets
                            )
                        )
                        self?.renderWindCue(
                            DescentSkillActivationCue(
                                kind: .wind,
                                level: 3,
                                activationID: 90_002,
                                origin: origin,
                                targets: windTargets
                            )
                        )
                    },
                    .wait(forDuration: 0.85)
                ])
            ),
            withKey: "descent.gptAssetVisualQA"
        )
    }
#endif

    private func renderElectricCue(_ cue: DescentSkillActivationCue) {
        let root = SKNode()
        let origin = CGPoint(x: points(cue.origin.xQ), y: points(cue.origin.yQ))
        let targets = cue.targets.prefix(7).map {
            CGPoint(x: points($0.xQ), y: points($0.yQ))
        }
        let impactCore = DescentArtCatalog.makeAdditiveSprite(
            texture: DescentArtCatalog.skillVFXTexture(for: .electric),
            size: CGSize(width: 64, height: 64),
            zPosition: -1,
            alpha: reduceMotion ? 0.18 : 0.32
        )
        impactCore.position = origin
        root.addChild(impactCore)
        var branchStart = origin
        for (index, target) in targets.enumerated() {
            let path = CGMutablePath()
            addElectricBranch(
                to: path,
                from: branchStart,
                to: target,
                seed: cue.activationID &* 31 &+ index
            )

            let underlay = SKShapeNode(path: path)
            underlay.strokeColor = color(for: .electric).withAlphaComponent(0.28)
            underlay.lineWidth = reduceMotion ? 4 : 8
            underlay.glowWidth = reduceMotion ? 0 : 2
            root.addChild(underlay)

            let core = SKShapeNode(path: path)
            core.strokeColor = UIColor(hex: GamePalette.textPrimaryHex, alpha: 0.92)
            core.lineWidth = reduceMotion ? 2 : 2.5
            root.addChild(core)

            if !reduceMotion {
                for pulseIndex in 0..<2 {
                    let pulse = SKShapeNode(circleOfRadius: pulseIndex == 0 ? 3.5 : 2.5)
                    pulse.fillColor = UIColor(hex: GamePalette.textPrimaryHex, alpha: 0.95)
                    pulse.strokeColor = color(for: .electric)
                    pulse.glowWidth = 2
                    pulse.position = branchStart
                    root.addChild(pulse)
                    pulse.run(.sequence([
                        .wait(forDuration: Double(index) * 0.018 + Double(pulseIndex) * 0.055),
                        .follow(
                            path,
                            asOffset: false,
                            orientToPath: false,
                            duration: 0.14
                        ),
                        .fadeOut(withDuration: 0.035),
                        .removeFromParent()
                    ]))
                }
            }
            branchStart = target
        }

        for target in [origin] + targets {
            let marker = SKShapeNode(rectOf: CGSize(width: 13, height: 13), cornerRadius: 2)
            marker.position = target
            marker.zRotation = .pi / 4
            marker.strokeColor = color(for: .electric)
            marker.fillColor = UIColor(hex: GamePalette.surface0Hex, alpha: 0.18)
            marker.lineWidth = 2
            root.addChild(marker)
        }

        guard addBoundedSkillCue(root, cue: cue) else { return }
        root.run(.sequence([
            .wait(forDuration: reduceMotion ? 0.18 : 0.22),
            .fadeOut(withDuration: reduceMotion ? 0.06 : 0.08),
            .removeFromParent()
        ]))
    }

    private func addElectricBranch(
        to path: CGMutablePath,
        from start: CGPoint,
        to end: CGPoint,
        seed: Int
    ) {
        path.move(to: start)
        let segments = reduceMotion ? 2 : 6
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        let perpendicular = CGVector(dx: -dy / length, dy: dx / length)
        for segment in 1..<segments {
            let progress = CGFloat(segment) / CGFloat(segments)
            let base = CGPoint(x: start.x + dx * progress, y: start.y + dy * progress)
            let signed = ((seed &+ segment * 17).isMultiple(of: 2) ? CGFloat(1) : -1)
            let jitter = reduceMotion ? 0 : signed * CGFloat(4 + (seed &+ segment) % 5)
            path.addLine(
                to: CGPoint(
                    x: base.x + perpendicular.dx * jitter,
                    y: base.y + perpendicular.dy * jitter
                )
            )
        }
        path.addLine(to: end)
    }

    private func renderWindCue(_ cue: DescentSkillActivationCue) {
        let root = SKNode()
        let origin = CGPoint(x: points(cue.origin.xQ), y: points(cue.origin.yQ))
        let targets = cue.targets.prefix(5).map {
            CGPoint(x: points($0.xQ), y: points($0.yQ))
        }
        for (index, target) in targets.enumerated() {
            let streamPath = CGMutablePath()
            streamPath.move(to: origin)
            let lateral = CGFloat(index.isMultiple(of: 2) ? 22 : -22)
            streamPath.addCurve(
                to: target,
                control1: CGPoint(x: origin.x + lateral, y: origin.y + 42),
                control2: CGPoint(x: target.x - lateral, y: target.y - 34)
            )
            let underlay = SKShapeNode(path: streamPath)
            underlay.strokeColor = color(for: .wind).withAlphaComponent(0.20)
            underlay.lineWidth = reduceMotion ? 5 : 11
            root.addChild(underlay)
            let core = SKShapeNode(path: streamPath)
            core.strokeColor = color(for: .wind).withAlphaComponent(0.78)
            core.lineWidth = reduceMotion ? 2 : 3
            root.addChild(core)

            if !reduceMotion {
                for flowIndex in 0..<2 {
                    let flow = SKShapeNode(ellipseOf: CGSize(width: 8, height: 4))
                    flow.fillColor = color(for: .wind).withAlphaComponent(0.88)
                    flow.strokeColor = UIColor(hex: GamePalette.textPrimaryHex, alpha: 0.74)
                    flow.lineWidth = 1
                    flow.glowWidth = 1
                    flow.position = origin
                    root.addChild(flow)
                    flow.run(.sequence([
                        .wait(forDuration: Double(index) * 0.018 + Double(flowIndex) * 0.075),
                        .follow(
                            streamPath,
                            asOffset: false,
                            orientToPath: true,
                            duration: 0.25
                        ),
                        .fadeOut(withDuration: 0.05),
                        .removeFromParent()
                    ]))
                }
            }
        }

        let motif = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.skillVFXTexture(for: .wind),
            size: CGSize(width: 82, height: 104),
            zPosition: -1
        )
        motif.position = origin
        motif.blendMode = .add
        motif.alpha = reduceMotion ? 0.20 : 0.36
        root.addChild(motif)

        for target in targets {
            let spiral = SKShapeNode(ellipseOf: CGSize(width: 30, height: 13))
            spiral.position = target
            spiral.strokeColor = color(for: .wind)
            spiral.fillColor = .clear
            spiral.lineWidth = 2
            let arrow = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            arrow.text = "↑"
            arrow.fontSize = 16
            arrow.fontColor = color(for: .wind)
            arrow.position = CGPoint(x: target.x, y: target.y + 9)
            root.addChild(spiral)
            root.addChild(arrow)
        }

        guard addBoundedSkillCue(root, cue: cue) else { return }
        if reduceMotion {
            root.run(.sequence([
                .wait(forDuration: 0.20),
                .fadeOut(withDuration: 0.06),
                .removeFromParent()
            ]))
        } else {
            root.run(.sequence([
                .wait(forDuration: 0.30),
                .fadeOut(withDuration: 0.08),
                .removeFromParent()
            ]))
        }
    }

    @discardableResult
    private func addBoundedSkillCue(
        _ node: SKNode,
        cue: DescentSkillActivationCue
    ) -> Bool {
        // Skill cues are isolated from hit sparks and fragments. A saturated
        // budget can omit a cue before its first frame, but never cut an attack
        // the player is already tracking.
        guard skillCueRoot.children.count < 8 else { return false }
        node.name = "descent.skillCue.\(cue.kind.rawValue).\(cue.activationID)"
        node.zPosition = cue.kind == .electric ? 2 : 1
        skillCueRoot.addChild(node)
        return true
    }

    private func animateEnemyFire(_ projectile: DescentEnemyProjectile) {
        let lanePoint = CGPoint(x: laneX(projectile.lane), y: points(projectile.yQ))
        let pulse = SKShapeNode(circleOfRadius: 18)
        pulse.position = lanePoint
        pulse.strokeColor = UIColor(hex: GamePalette.dangerHex)
        pulse.fillColor = UIColor(hex: GamePalette.dangerHex, alpha: 0.12)
        pulse.lineWidth = 3
        addTransient(pulse)
        pulse.run(.sequence([
            .scale(to: reduceMotion ? 1.05 : 1.5, duration: 0.12),
            .fadeOut(withDuration: 0.10),
            .removeFromParent()
        ]))
    }

    private func animateFireEcho(targetIDs: [Int]) {
        for position in targetIDs.compactMap({ objectNodes[$0]?.position }).prefix(5) {
            let ring = SKShapeNode(circleOfRadius: 14)
            ring.position = position
            ring.strokeColor = UIColor(hex: GamePalette.fireCoreHex)
            ring.fillColor = UIColor(hex: GamePalette.fireHex, alpha: 0.12)
            ring.lineWidth = 3
            addTransient(ring)
            ring.run(.sequence([
                .group([.scale(to: 1.6, duration: 0.16), .fadeOut(withDuration: 0.16)]),
                .removeFromParent()
            ]))
        }
    }

    private func animateBreach(id: Int, reactorDamaged: Bool) {
        if let node = objectNodes.removeValue(forKey: id) {
            showFloatingText(reactorDamaged ? "BREACH" : "BLOCKED", at: node.position, color: UIColor(hex: GamePalette.dangerHex))
            node.removeFromParent()
        }
    }

    private func animateReactorDamage() {
        let damagePulse = SKShapeNode(circleOfRadius: 42)
        damagePulse.position = playerNode.position
        damagePulse.fillColor = UIColor(hex: GamePalette.dangerHex, alpha: 0.08)
        damagePulse.strokeColor = UIColor(hex: GamePalette.dangerHex)
        damagePulse.lineWidth = 4
        addTransient(damagePulse)
        damagePulse.run(.sequence([
            .fadeOut(withDuration: reduceMotion ? 0.12 : 0.28),
            .removeFromParent()
        ]))
        guard !reduceMotion else { return }
        rootShake(by: 4)
    }

    /// A single outline pulse communicates the mode change without filling the
    /// playfield or obscuring the danger line, drops, projectiles, or objects.
    private func animateBreakFlowPulse() {
        let frame = SKShapeNode(
            rectOf: CGSize(width: 372, height: 608),
            cornerRadius: 18
        )
        frame.position = CGPoint(x: 195, y: 430)
        frame.fillColor = .clear
        frame.strokeColor = UIColor(hex: GamePalette.warningHex)
            .withAlphaComponent(0.82)
        frame.lineWidth = 4
        addTransient(frame)
        frame.run(.sequence([
            .fadeOut(withDuration: reduceMotion ? 0.12 : 0.24),
            .removeFromParent()
        ]))
    }

    private func animateMuzzleFlash() {
        let flash = SKShapeNode(circleOfRadius: 7)
        flash.position = CGPoint(x: playerNode.position.x, y: playerNode.position.y + 26)
        flash.fillColor = UIColor(hex: GamePalette.fireCoreHex)
        flash.strokeColor = UIColor(hex: GamePalette.textPrimaryHex)
        flash.glowWidth = 5
        addTransient(flash)
        flash.run(.sequence([.fadeOut(withDuration: 0.07), .removeFromParent()]))
    }

    private func addVerticalBeam(at point: CGPoint, color: UIColor, width: CGFloat) {
        let beam = SKShapeNode(rectOf: CGSize(width: width, height: 150), cornerRadius: width / 2)
        beam.position = point
        beam.fillColor = color.withAlphaComponent(0.72)
        beam.strokeColor = color
        beam.glowWidth = 7
        addTransient(beam)
        beam.run(.sequence([
            .fadeAlpha(to: 0.15, duration: reduceMotion ? 0.07 : 0.16),
            .removeFromParent()
        ]))
    }

    private func showFloatingText(_ text: String, atObject id: Int, color: UIColor) {
        showFloatingText(text, at: objectNodes[id]?.position ?? CGPoint(x: 195, y: 190), color: color)
    }

    private func showFloatingText(_ text: String, at position: CGPoint, color: UIColor) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 16
        label.fontColor = color
        label.position = position
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        addTransient(label)
        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: reduceMotion ? 8 : 28, duration: 0.38),
                .fadeOut(withDuration: 0.38)
            ]),
            .removeFromParent()
        ]))
    }

    private func rootShake(by points: CGFloat) {
        let roots = [
            backgroundRoot,
            laneRoot,
            dangerRoot,
            objectRoot,
            effectRoot,
            skillCueRoot,
            projectileRoot,
            enemyProjectileRoot,
            dropRoot,
            playerRoot
        ]
        roots.forEach {
            $0.removeAction(forKey: "shake")
            $0.run(.sequence([
                .moveBy(x: points, y: 0, duration: 0.03),
                .moveBy(x: -points * 2, y: 0, duration: 0.04),
                .moveBy(x: points, y: 0, duration: 0.03)
            ]), withKey: "shake")
        }
    }

    private func addTransient(_ node: SKNode) {
        while effectRoot.children.count >= 64 {
            effectRoot.children.first?.removeFromParent()
        }
        node.zPosition = 0
        effectRoot.addChild(node)
    }

    private func syncSnapshot(feedback: String? = nil) {
        let elapsed = Double(state.tick) / Double(GameRules.descentTickRate)
        var next = snapshot
        if let endless = endlessState {
            next.phase = endless.phase == .finished ? .finished : state.phase == .paused ? .paused : .playing
            next.isRankedEndless = true
            next.level = endless.level
            next.threatTier = GameRules.descentEndlessThreatTier(
                score: state.score,
                tick: state.tick
            )
            next.enemyProjectileCount = state.enemyProjectiles.count
            next.rankedClass = endless.rankedClass
            next.awaitingRevive = endless.phase == .awaitingRevive
            next.revivesUsed = endless.revivesUsed
            next.fatalCheckpointScore = endless.fatalCheckpoint.map { Int(clamping: $0.score) }
            next.fatalCheckpointTick = endless.fatalCheckpoint?.tick
            next.fatalCheckpointVerified = fatalCheckpointVerified
        } else {
            next.phase = state.phase
            next.isRankedEndless = false
            next.level = 1
            next.threatTier = 0
            next.enemyProjectileCount = 0
            next.rankedClass = .clean
            next.awaitingRevive = false
            next.revivesUsed = 0
            next.fatalCheckpointScore = nil
            next.fatalCheckpointTick = nil
            next.fatalCheckpointVerified = false
        }
        next.elapsedSeconds = elapsed
        next.remainingSeconds = next.isRankedEndless
            ? 0
            : max(0, 60 - Int(elapsed.rounded(.down)))
        next.score = Int(clamping: state.score)
        next.combo = state.combo
        next.maxCombo = state.maxCombo
        next.reactorHP = state.player.reactorHP
        next.dangerSaves = state.dangerSaves
        next.lane = nearestLane(to: points(state.player.xQ)) + 1
        next.activeObjects = state.objects.count
        next.shipKind = state.shipKind
        next.skills = state.skills.levels
        next.choiceArenaPresented = !next.isRankedEndless && researchVariant == .choiceArena && state.choiceArena.wasPresented
        next.awaitingChoice = !next.isRankedEndless && researchVariant == .choiceArena && state.choiceArena.isAwaitingChoice
        next.arenaChoice = !next.isRankedEndless && researchVariant == .choiceArena ? state.choiceArena.selectedChoice : nil
        next.redlineBonusScore = Int(clamping: state.choiceArena.redlineBonusScore)
        next.flowMode = state.frenzy.mode
        next.frenzyCharge = min(
            GameRules.descentFrenzyThreshold,
            max(0, state.frenzy.directChainCount)
        )
        next.frenzyRemainingTicks = state.frenzy.expiresAtTick.map {
            max(0, $0 - state.tick)
        } ?? 0
        next.frenzyBonusScore = Int(clamping: state.frenzy.bonusScore)
        next.frenzyActivationCount = state.frenzy.activationCount
        next.lastCollectedSkill = lastCollectedSkill
        if let feedback {
            next.feedback = feedback
        } else if next.awaitingRevive {
            next.feedback = next.rankedClass == .clean
                ? "CLEAN 기록 봉인 · 부활 선택"
                : "ASSISTED RUN 종료"
        } else if state.choiceArena.isAwaitingChoice {
            next.feedback = "CHOICE ARENA · 기록을 걸까요?"
        } else if let lastCollectedSkill {
            let level = state.skills.levels.level(for: lastCollectedSkill)
            next.feedback = "\(skillName(lastCollectedSkill)) L\(level) · 다음 미사일부터 지속"
        } else if state.objects.contains(where: { points($0.yQ) < Double(GameRules.descentDangerY + 96) }) {
            next.feedback = "DANGER · 빨간 선 전에 파괴"
        } else if state.choiceArena.selectedChoice == .redline {
            next.feedback = "REDLINE · 기본탄 점수 +35%"
        } else {
            next.feedback = state.tick < 1_440 ? "끌어서 조준 · 자동 발사" : "아이템 쪽으로 이동"
        }
        if next != snapshot { snapshot = next }
    }

    private func emitSnapshot() {
        gameDelegate?.descentGameScene(self, didEmit: .snapshot(snapshot))
    }

    private func finishRun() {
        let reason = state.endReason ?? .reactorDestroyed
        guard !runFinished, runReachedFinishedPhase else { return }
        runFinished = true
        isResearchTouchActive = false
        isUserInteractionEnabled = false
        syncSnapshot(
            feedback: snapshot.isRankedEndless
                ? (snapshot.rankedClass == .clean ? "CLEAN RUN 확정" : "ASSISTED RUN 완료")
                : (reason == .survivedSixtySeconds ? "60초 생존 완료" : "REACTOR OFFLINE")
        )
        if reason == .survivedSixtySeconds, !snapshot.isRankedEndless {
            snapshot.elapsedSeconds = 60
            snapshot.remainingSeconds = 0
        }
        emitSnapshot()
        let activePlayMilliseconds = state.tick * 1_000 / GameRules.descentTickRate
        researchSession?.record(.inputSummary(DescentResearchInputSummary(
            firstMoveMilliseconds: firstMoveTick.map {
                $0 * 1_000 / GameRules.descentTickRate
            },
            activeTouchMilliseconds: activeTouchTicks * 1_000 / GameRules.descentTickRate,
            activePlayMilliseconds: activePlayMilliseconds,
            meaningfulLaneChanges: meaningfulLaneChanges
        )))
        if researchSession?.context.runIndex == 2 {
            researchSession?.record(.optionalRetryWindowOpened(durationMilliseconds: 60_000))
        }
        researchSession?.record(.runFinished(DescentResearchRunSummary(
            tick: state.tick,
            score: Int(clamping: state.score),
            previousBestScore: researchSession?.context.bestScoreBefore ?? 0,
            maxCombo: state.maxCombo,
            dangerSaves: state.dangerSaves,
            dropsCollected: researchDropsCollected,
            breaches: researchBreaches,
            redlineBonusScore: Int(clamping: state.choiceArena.redlineBonusScore),
            frenzyBonusScore: Int(clamping: state.frenzy.bonusScore),
            frenzyTriggerCount: state.frenzy.activationCount,
            frenzyActiveTicks: state.frenzy.activeTickCount,
            maxDirectChain: state.frenzy.maxDirectChain,
            endReason: reason
        )))
        flushResearchSession()
        gameDelegate?.descentGameScene(self, didEmit: .finished(snapshot: snapshot, reason: reason))
    }

    private func flushResearchSession() {
        researchSession?.flush()
        if researchSession?.lastPersistenceError != nil {
            researchPersistenceError = "연구 데이터 저장 실패"
        }
    }

    private func recordFirstResearchInputIfNeeded() {
        guard firstMoveTick == nil else { return }
        firstMoveTick = state.tick
        researchSession?.record(.firstInput(
            tick: state.tick,
            elapsedMilliseconds: state.tick * 1_000 / GameRules.descentTickRate
        ))
    }

    /// A lane change only counts after the player remains in the new nearest
    /// lane for 15 authoritative ticks. Fast jitter therefore cannot inflate
    /// the interaction driver.
    private func updateResearchLaneChanges() {
        let lane = nearestLane(to: GameRules.descentPoints(fromQ: state.player.xQ))
        guard lane != confirmedResearchLane else {
            candidateResearchLane = nil
            return
        }
        if candidateResearchLane != lane {
            candidateResearchLane = lane
            candidateResearchLaneTick = state.tick
            return
        }
        guard state.tick - candidateResearchLaneTick >= 15 else { return }
        confirmedResearchLane = lane
        candidateResearchLane = nil
        meaningfulLaneChanges += 1
    }

    private func points(_ value: Int64) -> Double {
        GameRules.descentPoints(fromQ: value)
    }

    private func laneX(_ lane: Int) -> CGFloat {
        CGFloat(GameRules.descentLaneXPoints[min(4, max(0, lane))])
    }

    private func nearestLane(to x: Double) -> Int {
        GameRules.descentLaneXPoints.enumerated().min { lhs, rhs in
            abs(Double(lhs.element) - x) < abs(Double(rhs.element) - x)
        }?.offset ?? 2
    }

    private func skillName(_ kind: DescentSkillKind) -> String {
        switch kind {
        case .fire: "화염"
        case .electric: "전기"
        case .pierce: "관통"
        case .wind: "바람"
        case .explosion: "폭발"
        }
    }

    private func color(for kind: DescentSkillKind) -> UIColor {
        switch kind {
        case .fire: UIColor(hex: GamePalette.fireHex)
        case .electric: UIColor(hex: GamePalette.electricHex)
        case .pierce: UIColor(hex: GamePalette.successHex)
        case .wind: UIColor(hex: GamePalette.infoHex)
        case .explosion: UIColor(hex: GamePalette.warningHex)
        }
    }

    private func color(for cause: DescentDamageCause) -> UIColor {
        switch cause {
        case .projectile: UIColor(hex: GamePalette.fireCoreHex)
        case .skill(let kind, _): color(for: kind)
        case .fireEcho: UIColor(hex: GamePalette.fireHex)
        }
    }
}

@MainActor
private final class DescentProceduralArtFactory {
    private enum NodeName {
        static let hp = "descent.hp"
        static let attack = "descent.attack"
    }

    func makeObject(_ object: DescentObject) -> SKNode {
        let root = SKNode()
        let size: CGSize = switch object.kind {
        case .normal: CGSize(width: 48, height: 48)
        case .armored: CGSize(width: 50, height: 50)
        case .spike: CGSize(width: 52, height: 52)
        case .drone: CGSize(width: 58, height: 44)
        case .core: CGSize(width: 52, height: 58)
        case .brute: CGSize(width: 70, height: 76)
        }
        let art = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.objectTexture(for: object.kind),
            size: size,
            zPosition: 0
        )
        root.addChild(art)
        if object.kind == .core, let skill = object.dropKind {
            let symbol = symbolNode(systemName: systemImage(skill), color: skillColor(skill), pointSize: 10)
            symbol.position = CGPoint(x: 0, y: -2)
            symbol.zPosition = 4
            root.addChild(symbol)
        }
        let hp = SKNode()
        hp.name = NodeName.hp
        hp.position = CGPoint(x: 0, y: -30)
        hp.zPosition = 8
        root.addChild(hp)
        let attack = SKNode()
        attack.name = NodeName.attack
        attack.zPosition = 9
        root.addChild(attack)
        updateObject(root, object: object, currentTick: object.spawnedAtTick, threatTier: nil)
        return root
    }

    func updateObject(
        _ node: SKNode,
        object: DescentObject,
        currentTick: Int,
        threatTier: Int?
    ) {
        guard let hp = node.childNode(withName: NodeName.hp) else { return }
        hp.removeAllChildren()
        if object.maximumHitPoints > 8 {
            let track = SKShapeNode(rectOf: CGSize(width: 46, height: 6), cornerRadius: 3)
            track.fillColor = UIColor(hex: GamePalette.surface3Hex)
            track.strokeColor = UIColor(hex: GamePalette.borderStrongHex)
            track.lineWidth = 0.8
            hp.addChild(track)
            let ratio = CGFloat(max(0, object.hitPoints)) / CGFloat(object.maximumHitPoints)
            let fill = SKShapeNode(rectOf: CGSize(width: max(2, 42 * ratio), height: 3), cornerRadius: 1.5)
            fill.position = CGPoint(x: -21 + max(2, 42 * ratio) / 2, y: 0)
            fill.fillColor = UIColor(hex: GamePalette.warningHex)
            fill.strokeColor = .clear
            hp.addChild(fill)
            let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
            label.text = "\(object.hitPoints)"
            label.fontSize = 8
            label.fontColor = UIColor(hex: GamePalette.textPrimaryHex)
            label.position = CGPoint(x: 0, y: -12)
            label.verticalAlignmentMode = .center
            hp.addChild(label)
        } else if object.maximumHitPoints > 1 {
            let totalWidth = CGFloat(object.maximumHitPoints * 9 - 3)
            for index in 0..<object.maximumHitPoints {
                let pip = SKShapeNode(rectOf: CGSize(width: 6, height: 4), cornerRadius: 1.5)
                pip.position = CGPoint(x: -totalWidth / 2 + CGFloat(index * 9) + 3, y: 0)
                pip.fillColor = index < object.hitPoints
                    ? UIColor(hex: GamePalette.warningHex)
                    : UIColor(hex: GamePalette.surface3Hex)
                pip.strokeColor = UIColor(hex: GamePalette.borderStrongHex)
                pip.lineWidth = 0.6
                hp.addChild(pip)
            }
        }

        guard let attack = node.childNode(withName: NodeName.attack) else { return }
        attack.removeAllChildren()
        guard object.kind == .drone,
              let attackAtTick = object.enemyAttackAtTick,
              attackAtTick > currentTick else { return }
        let remaining = attackAtTick - currentTick
        let telegraph = max(1, GameRules.descentEnemyAttackTelegraphTicks)
        guard remaining <= telegraph else { return }
        let progress = 1 - CGFloat(remaining) / CGFloat(telegraph)
        let ring = SKShapeNode(circleOfRadius: 27)
        ring.strokeColor = UIColor(hex: GamePalette.dangerHex, alpha: 0.55 + progress * 0.35)
        ring.fillColor = .clear
        ring.lineWidth = 2 + progress * 2
        attack.addChild(ring)
        let marker = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        marker.text = "!"
        marker.fontSize = 15
        marker.fontColor = UIColor(hex: GamePalette.dangerHex)
        marker.position = CGPoint(x: 0, y: 21)
        marker.verticalAlignmentMode = .center
        attack.addChild(marker)
        if let threatTier {
            attack.alpha = min(1, 0.68 + CGFloat(threatTier) * 0.04)
        }
    }

    func makeEnemyProjectile() -> SKNode {
        let root = SKNode()
        let bolt = SKShapeNode(rectOf: CGSize(width: 8, height: 24), cornerRadius: 4)
        bolt.fillColor = UIColor(hex: GamePalette.dangerHex)
        bolt.strokeColor = UIColor(hex: GamePalette.warningHex)
        bolt.lineWidth = 1.5
        bolt.glowWidth = 3
        root.addChild(bolt)
        let chevron = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        chevron.text = "▼"
        chevron.fontSize = 10
        chevron.fontColor = UIColor(hex: GamePalette.textPrimaryHex)
        chevron.position = CGPoint(x: 0, y: -2)
        chevron.verticalAlignmentMode = .center
        root.addChild(chevron)
        return root
    }

    func makeProjectile(_ projectile: DescentProjectile) -> SKNode {
        let root = SKNode()
        let missile = projectile.missileKind
        let color = missileColor(missile)
        let dominantColor = projectile.effectSnapshot.dominantEffect.map(skillColor) ?? color
        let hasPierce = projectile.effectSnapshot.levels.pierce > 0
        let trail = SKShapeNode(
            rectOf: CGSize(
                width: hasPierce ? 5 : (missile == .salvo ? 7 : 4),
                height: hasPierce ? 31 : 24
            ),
            cornerRadius: 2
        )
        trail.position = CGPoint(x: 0, y: -7)
        trail.fillColor = dominantColor.withAlphaComponent(0.38)
        trail.strokeColor = .clear
        root.addChild(trail)
        let bolt = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.missileTexture(for: missile),
            size: missileSize(missile),
            zPosition: 1
        )
        root.addChild(bolt)
        if projectile.effectSnapshot.levels.explosion > 0 {
            let payload = SKShapeNode(circleOfRadius: 7)
            payload.strokeColor = skillColor(.explosion).withAlphaComponent(0.9)
            payload.fillColor = .clear
            payload.lineWidth = 1.5
            root.addChild(payload)
        }
        if projectile.effectSnapshot.levels.electric > 0 {
            let arc = SKShapeNode(rectOf: CGSize(width: 12, height: 2), cornerRadius: 1)
            arc.strokeColor = .clear
            arc.fillColor = skillColor(.electric).withAlphaComponent(0.82)
            arc.zRotation = .pi / 4
            root.addChild(arc)
        }
        return root
    }

    func makeDrop(_ kind: DescentSkillKind) -> SKNode {
        let root = SKNode()
        let color = skillColor(kind)
        let art = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.skillTexture(for: kind),
            size: CGSize(width: 40, height: 40),
            zPosition: 1
        )
        root.addChild(art)
        let outer = SKShapeNode(circleOfRadius: 16)
        outer.fillColor = UIColor(hex: GamePalette.surface0Hex, alpha: 0.12)
        outer.strokeColor = color
        outer.lineWidth = 3
        outer.glowWidth = 7
        root.addChild(outer)
        return root
    }

    func makePlayer(ship: DescentShipKind) -> SKNode {
        let root = SKNode()
        let reactorAura = DescentArtCatalog.makeAdditiveSprite(
            texture: DescentArtCatalog.playerAuraTexture(),
            size: CGSize(width: 118, height: 72),
            zPosition: -2,
            alpha: 0.34
        )
        reactorAura.position = CGPoint(x: 0, y: -12)
        root.addChild(reactorAura)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 80, height: 18))
        shadow.position = CGPoint(x: 0, y: -18)
        shadow.fillColor = UIColor(hex: GamePalette.infoHex, alpha: 0.13)
        shadow.strokeColor = UIColor(hex: GamePalette.infoHex, alpha: 0.26)
        shadow.glowWidth = 7
        root.addChild(shadow)
        let shipSprite = DescentArtCatalog.makeSprite(
            texture: DescentArtCatalog.playerTexture(for: ship),
            size: CGSize(width: 82, height: 76),
            zPosition: 2
        )
        root.addChild(shipSprite)
        return root
    }

    private func missileSize(_ missile: DescentMissileKind) -> CGSize {
        switch missile {
        case .pulse: CGSize(width: 10, height: 34)
        case .lance: CGSize(width: 12, height: 38)
        case .salvo: CGSize(width: 22, height: 34)
        }
    }

    private func missileColor(_ missile: DescentMissileKind) -> UIColor {
        switch missile {
        case .pulse: UIColor(hex: GamePalette.fireHex)
        case .lance: UIColor(hex: GamePalette.successHex)
        case .salvo: UIColor(hex: GamePalette.warningHex)
        }
    }

    private func symbolNode(systemName: String, color: UIColor, pointSize: CGFloat) -> SKSpriteNode {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .black)
        let image = UIImage(systemName: systemName, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
        let node = SKSpriteNode(texture: image.map(SKTexture.init(image:)))
        node.size = CGSize(width: pointSize + 4, height: pointSize + 4)
        return node
    }

    private func systemImage(_ kind: DescentSkillKind) -> String {
        switch kind {
        case .fire: "flame.fill"
        case .electric: "bolt.fill"
        case .pierce: "arrow.up"
        case .wind: "wind"
        case .explosion: "burst.fill"
        }
    }

    private func skillColor(_ kind: DescentSkillKind) -> UIColor {
        switch kind {
        case .fire: UIColor(hex: GamePalette.fireHex)
        case .electric: UIColor(hex: GamePalette.electricHex)
        case .pierce: UIColor(hex: GamePalette.successHex)
        case .wind: UIColor(hex: GamePalette.infoHex)
        case .explosion: UIColor(hex: GamePalette.warningHex)
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
