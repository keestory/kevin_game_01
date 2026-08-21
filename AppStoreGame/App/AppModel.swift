import Combine
import Foundation
import SpriteKit

struct DescentCleanRankRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let score: Int
    let survivalTicks: Int
    let level: Int
    let maxCombo: Int
    let dangerSaves: Int
    let shipKind: DescentShipKind
    let combatChecksum: UInt64
}

@MainActor
final class AppModel: ObservableObject, GameSceneDelegate, DescentGameSceneDelegate {
    @Published private(set) var route: AppRoute = .home
    @Published private(set) var snapshot = RunSnapshot()
    @Published private(set) var profile: PlayerProfile
    @Published var showTutorial = false
    @Published var showSettings = false
    @Published private(set) var currentScene: GameScene?
    @Published private(set) var currentDescentScene: DescentGameScene?
    @Published private(set) var descentBestScore: Int
    @Published private(set) var descentCleanTop10: [DescentCleanRankRecord]
    @Published private(set) var descentAssistedBestScore: Int
    @Published private(set) var descentExtraLives: Int
    @Published private(set) var selectedDescentBooster: DescentEndlessBoosterKind?
    @Published private(set) var isRequestingDescentReward = false
    @Published private(set) var descentAssistMessage: String? = nil
    @Published private(set) var selectedDescentShip: DescentShipKind
    @Published private(set) var descentResearchRuntimeError: String? = nil

    let visualVariant = VisualVariant.current

    private let persistence: PersistenceService
    private let haptics = HapticService()
    private let audio = GameAudioService()
    private let seed: UInt64
    private let skipTutorialForTesting: Bool
    private let isUITesting: Bool
    private let descentResearchConfiguration: DescentResearchConfiguration
    private let descentResearchSink: any DescentResearchEventSink
    private let rewardedAdService: any RewardedAdServing
    private let descentResearchSessionID = UUID()
    private var activeRunID: UUID?
    private var currentDescentResearchSession: DescentResearchSession?
    private var descentResearchRunIndex = 0

    var descentResearchBlockingMessage: String? {
        if let descentResearchRuntimeError { return descentResearchRuntimeError }
        guard descentResearchConfiguration.isEnabled,
              !isUITesting,
              let issue = descentResearchConfiguration.assignmentIssue else { return nil }
        return issue.operatorMessage
    }

    var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.haptics") as? Bool ?? true
    }

    var soundEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.sound") as? Bool ?? true
    }

    init(
        persistence: PersistenceService = .shared,
        seed: UInt64 = DailySeed.current()
    ) {
        let arguments = ProcessInfo.processInfo.arguments
        let researchConfiguration = DescentResearchConfiguration.current(arguments: arguments)
        self.persistence = persistence
        self.isUITesting = arguments.contains("-uiTesting")
        self.profile = arguments.contains("-uiTesting") ? PlayerProfile() : persistence.load()
        self.seed = arguments.contains("-uiTesting") ? 42 : seed
        self.skipTutorialForTesting = arguments.contains("-skipTutorial")
        self.descentResearchConfiguration = researchConfiguration
#if DEBUG
        self.descentResearchSink = researchConfiguration.isDataCollectionEnabled
            ? LocalResearchEventStore()
            : NoopDescentResearchEventSink()
#else
        self.descentResearchSink = NoopDescentResearchEventSink()
#endif
        self.descentBestScore = arguments.contains("-uiTesting") || researchConfiguration.isEnabled
            ? 0
            : UserDefaults.standard.integer(forKey: "descent.bestScore")
        self.descentCleanTop10 = arguments.contains("-uiTesting")
            ? []
            : Self.loadDescentCleanTop10()
        self.descentAssistedBestScore = arguments.contains("-uiTesting")
            ? 0
            : UserDefaults.standard.integer(forKey: "descent.endless.assistedBest")
#if DEBUG
        let defaultExtraLives = 1
        self.rewardedAdService = MockRewardedAdService()
#else
        let defaultExtraLives = 0
        self.rewardedAdService = UnavailableRewardedAdService()
#endif
        if arguments.contains("-uiTesting") {
            self.descentExtraLives = 1
        } else if UserDefaults.standard.object(forKey: "descent.endless.extraLives") == nil {
            self.descentExtraLives = defaultExtraLives
        } else {
            self.descentExtraLives = UserDefaults.standard.integer(forKey: "descent.endless.extraLives")
        }
        self.selectedDescentBooster = nil
        self.selectedDescentShip = arguments.contains("-uiTesting")
            ? .interceptor
            : DescentShipKind(
                rawValue: UserDefaults.standard.integer(forKey: "descent.selectedShip")
            ) ?? .interceptor
        haptics.prepare()
    }

    var descentCleanBestScore: Int {
        descentCleanTop10.first?.score ?? 0
    }

    var canOfferMockDescentReward: Bool {
        rewardedAdService.isReady && !isRequestingDescentReward
    }

    func startGame() {
        closeDescentResearchForReplacementIfNeeded()
        activeRunID = UUID()
        let newScene = GameScene(
            size: CGSize(width: 390, height: 844),
            seed: seed,
            bestScore: profile.bestScore,
            bestHeight: profile.bestHeight,
            visualVariant: visualVariant
        )
        newScene.gameDelegate = self
        var initialSnapshot = RunSnapshot()
        initialSnapshot.bestScore = profile.bestScore
        initialSnapshot.bestHeight = profile.bestHeight
        snapshot = initialSnapshot
        showTutorial = !profile.tutorialSeen && !skipTutorialForTesting
        currentScene = newScene
        currentDescentScene = nil
        route = .game
    }

    func startDescent() {
        let arguments = ProcessInfo.processInfo.arguments
        let requiresRevision5Path = descentResearchConfiguration.isEnabled
            || arguments.contains("-uiTestingDescentFastFinish")
            || arguments.contains("-uiTestingChoiceArena")
            || arguments.contains("-uiTestingDescentRecordingDemo")
        if requiresRevision5Path {
            startRevision5Descent()
        } else {
            startRankedEndless()
        }
    }

    private func startRevision5Descent() {
        guard descentResearchBlockingMessage == nil else { return }
        closeDescentResearchForRetryOrReplacementIfNeeded()
        currentScene?.removeAllActions()
        currentScene = nil
        let runID = UUID()
        activeRunID = runID
        descentResearchRunIndex += 1
        let runSeed = descentResearchConfiguration.assignedSeed
            ?? (seed ^ 0xD35C_EA71_2026_0819)
        let researchSession: DescentResearchSession? = if descentResearchConfiguration.isDataCollectionEnabled {
            DescentResearchSession(
                context: DescentResearchContext(
                    researchSessionID: descentResearchSessionID,
                    runID: runID,
                    participantSlot: descentResearchConfiguration.participantSlot,
                    orderIndex: descentResearchConfiguration.orderIndex,
                    variant: descentResearchConfiguration.variant,
                    seed: runSeed,
                    ship: selectedDescentShip,
                    runIndex: descentResearchRunIndex,
                    bestScoreBefore: descentBestScore,
                    rulesVersion: DescentResearchRules.currentVersion
                ),
                sink: descentResearchSink
            )
        } else {
            nil
        }
        currentDescentResearchSession = researchSession
        // Persist the run-start envelope immediately. If the process exits before
        // a terminal event, the research QA pass can identify the incomplete run
        // instead of silently losing the entire session.
        researchSession?.flush()
        if researchSession?.lastPersistenceError != nil {
            activeRunID = nil
            currentDescentResearchSession = nil
            descentResearchRuntimeError = "연구 데이터를 저장하지 못했습니다. 이 런은 시작하지 않았습니다. Research Console에서 DQ와 저장 용량을 확인하세요."
            return
        }
        let scene = DescentGameScene(
            size: CGSize(width: GameRules.descentFieldWidth, height: GameRules.descentFieldHeight),
            seed: runSeed,
            ship: selectedDescentShip,
            researchSession: researchSession,
            researchVariant: descentResearchConfiguration.variant
        )
        scene.gameDelegate = self
        currentDescentScene = scene
        showTutorial = false
        route = .descent
    }

    func startRankedEndless() {
        closeDescentResearchForRetryOrReplacementIfNeeded()
        currentScene?.removeAllActions()
        currentScene = nil
        let runID = UUID()
        activeRunID = runID
        currentDescentResearchSession = nil
        descentAssistMessage = nil

        // Every attempt on the same daily seed receives the same authoritative
        // pattern so the local score comparison rewards execution, not rerolling.
        let runSeed = seed ^ 0xE11D_1E55_2026_0821
        let boosterSnapshot = selectedDescentBooster.map {
            DescentEndlessBoosterSnapshot(
                grantID: Self.stableGrantID("booster-\(runID.uuidString)"),
                kind: $0
            )
        }
        selectedDescentBooster = nil

        let scene = DescentGameScene(
            size: CGSize(width: GameRules.descentFieldWidth, height: GameRules.descentFieldHeight),
            seed: runSeed,
            ship: selectedDescentShip,
            mode: .rankedEndless(booster: boosterSnapshot)
        )
        scene.gameDelegate = self
        currentDescentScene = scene
        showTutorial = false
        route = .descent
    }

    func selectDescentBooster(_ booster: DescentEndlessBoosterKind?) {
        selectedDescentBooster = booster
    }

    func selectDescentShip(_ ship: DescentShipKind) {
        selectedDescentShip = ship
        guard !ProcessInfo.processInfo.arguments.contains("-uiTesting") else { return }
        UserDefaults.standard.set(ship.rawValue, forKey: "descent.selectedShip")
    }

    func requestRewardedDescentRevive() async {
        guard let scene = currentDescentScene,
              scene.snapshot.awaitingRevive,
              canOfferMockDescentReward else { return }
        isRequestingDescentReward = true
        descentAssistMessage = "보상 확인 중…"
        let outcome = await rewardedAdService.showRescueAd()
        guard scene === currentDescentScene,
              scene.snapshot.awaitingRevive else {
            isRequestingDescentReward = false
            descentAssistMessage = nil
            return
        }
        switch outcome {
        case .rewarded(let impressionID):
            let accepted = scene.scheduleVerifiedMockRevive(
                grantID: Self.stableGrantID(impressionID)
            )
            descentAssistMessage = accepted
                ? "테스트 보상 확인 · Assisted로 재개"
                : "이미 처리된 보상입니다"
        case .dismissed:
            descentAssistMessage = "광고를 끝까지 보면 1회 부활합니다"
        case .unavailable:
            descentAssistMessage = "현재 보상 광고를 사용할 수 없습니다"
        case .failed:
            descentAssistMessage = "보상 확인에 실패했습니다"
        }
        isRequestingDescentReward = false
    }

    func useDescentExtraLife() {
        guard descentExtraLives > 0,
              let scene = currentDescentScene,
              scene.snapshot.awaitingRevive else { return }
        let grantID = Self.stableGrantID("extra-life-\(activeRunID?.uuidString ?? "none")")
        guard scene.scheduleVerifiedMockRevive(grantID: grantID) else { return }
        descentExtraLives -= 1
        descentAssistMessage = "보유 목숨 사용 · Assisted로 재개"
        guard !isUITesting else { return }
        UserDefaults.standard.set(descentExtraLives, forKey: "descent.endless.extraLives")
    }

    func finalizeDescentRun() {
        currentDescentScene?.declineEndlessRevive()
    }

    func dismissTutorial() {
        showTutorial = false
        profile.tutorialSeen = true
        persistence.save(profile)
    }

    func pause() {
        switch route {
        case .descent: currentDescentScene?.setRunPaused(true)
        default: currentScene?.setRunPaused(true)
        }
    }

    func resume() {
        switch route {
        case .descent: currentDescentScene?.setRunPaused(false)
        default: currentScene?.setRunPaused(false)
        }
    }

    func goHome() {
        closeDescentResearchForHomeIfNeeded()
        currentScene?.removeAllActions()
        currentDescentScene?.removeAllActions()
        currentScene = nil
        currentDescentScene = nil
        activeRunID = nil
        route = .home
    }

    func setApplicationActive(_ isActive: Bool) {
        currentDescentResearchSession?.setApplicationActive(isActive)
        if !isActive {
            switch route {
            case .game, .descent:
                audio.stop()
                pause()
            default:
                break
            }
        }
    }

    func descentGameScene(_ scene: DescentGameScene, didEmit event: DescentSceneEvent) {
        guard scene === currentDescentScene, activeRunID != nil, case .descent = route else { return }
        switch event {
        case .snapshot:
            break
        case .objectDestroyed:
            haptics.perfect(enabled: hapticsEnabled)
            audio.play(.doors, enabled: soundEnabled)
        case .skillCollected:
            haptics.match(enabled: hapticsEnabled)
            audio.play(.perfect, enabled: soundEnabled)
        case .reactorDamaged:
            haptics.overflow(enabled: hapticsEnabled)
            audio.play(.missed, enabled: soundEnabled)
        case .cleanCheckpoint(let checkpointSnapshot, let checkpoint, let verified):
            guard verified, checkpoint.rankedClass == .clean,
                  let runID = activeRunID else {
                descentAssistMessage = "기록 재검증 실패 · Clean Top 10 미반영"
                break
            }
            commitDescentCleanRecord(
                DescentCleanRankRecord(
                    id: runID,
                    score: Int(clamping: checkpoint.score),
                    survivalTicks: checkpoint.tick,
                    level: checkpointSnapshot.level,
                    maxCombo: checkpointSnapshot.maxCombo,
                    dangerSaves: checkpointSnapshot.dangerSaves,
                    shipKind: checkpointSnapshot.shipKind,
                    combatChecksum: checkpoint.combatChecksum
                )
            )
            descentAssistMessage = "Clean 기록이 로컬 Top 10에 확정됐습니다"
        case .rankedClassChanged(let rankedClass):
            if rankedClass == .assisted {
                descentAssistMessage = "Assisted 전환 · Clean 기록은 그대로 보존됩니다"
            }
        case .finished(let finalSnapshot, _):
            if scene.researchPersistenceError != nil {
                descentResearchRuntimeError = "연구 저장에 실패해 이 참가자 런은 무효입니다. 다음 런을 시작하지 말고 Research Console에서 원자료를 확인하세요."
            }
            if finalSnapshot.isRankedEndless {
                if finalSnapshot.rankedClass == .assisted {
                    descentAssistedBestScore = max(descentAssistedBestScore, finalSnapshot.score)
                    if !isUITesting {
                        UserDefaults.standard.set(
                            descentAssistedBestScore,
                            forKey: "descent.endless.assistedBest"
                        )
                    }
                }
            } else {
                descentBestScore = max(descentBestScore, finalSnapshot.score)
                if !ProcessInfo.processInfo.arguments.contains("-uiTesting"),
                   !descentResearchConfiguration.isEnabled {
                    UserDefaults.standard.set(descentBestScore, forKey: "descent.bestScore")
                }
            }
            activeRunID = nil
        }
    }

    private func commitDescentCleanRecord(_ record: DescentCleanRankRecord) {
        guard !descentCleanTop10.contains(where: { $0.id == record.id }) else { return }
        descentCleanTop10.append(record)
        descentCleanTop10.sort {
            if $0.score != $1.score { return $0.score > $1.score }
            if $0.survivalTicks != $1.survivalTicks { return $0.survivalTicks > $1.survivalTicks }
            if $0.maxCombo != $1.maxCombo { return $0.maxCombo > $1.maxCombo }
            return $0.dangerSaves > $1.dangerSaves
        }
        descentCleanTop10 = Array(descentCleanTop10.prefix(10))
        guard !isUITesting,
              let data = try? JSONEncoder().encode(descentCleanTop10) else { return }
        UserDefaults.standard.set(data, forKey: "descent.endless.cleanTop10.v1")
    }

    private func closeDescentResearchForRetryOrReplacementIfNeeded() {
        guard let session = currentDescentResearchSession else { return }
        if session.hasTerminalEvent {
            session.recordResultAction(.retry)
        } else {
            session.record(.runAbandoned(
                tick: currentDescentScene.map { Int($0.snapshot.elapsedSeconds * 120) } ?? 0,
                reason: .replacedRun
            ))
        }
        session.flush()
        captureResearchPersistenceFailure(from: session)
        currentDescentResearchSession = nil
    }

    private func closeDescentResearchForReplacementIfNeeded() {
        guard let session = currentDescentResearchSession else { return }
        if !session.hasTerminalEvent {
            session.record(.runAbandoned(
                tick: currentDescentScene.map { Int($0.snapshot.elapsedSeconds * 120) } ?? 0,
                reason: .replacedRun
            ))
        }
        session.flush()
        captureResearchPersistenceFailure(from: session)
        currentDescentResearchSession = nil
    }

    private func closeDescentResearchForHomeIfNeeded() {
        guard let session = currentDescentResearchSession else { return }
        if session.hasTerminalEvent {
            session.recordResultAction(.home)
        } else {
            session.record(.runAbandoned(
                tick: currentDescentScene.map { Int($0.snapshot.elapsedSeconds * 120) } ?? 0,
                reason: .home
            ))
        }
        session.flush()
        captureResearchPersistenceFailure(from: session)
        currentDescentResearchSession = nil
    }

    private func captureResearchPersistenceFailure(from session: DescentResearchSession) {
        guard session.lastPersistenceError != nil else { return }
        descentResearchRuntimeError = "연구 저장에 실패해 현재 런은 무효입니다. 다음 런을 시작하지 말고 Research Console에서 원자료를 확인하세요."
    }

    func gameScene(_ scene: GameScene, didEmit event: GameEvent) {
        guard scene === currentScene, activeRunID != nil, case .game = route else { return }
        switch event {
        case .snapshot(let value):
            snapshot = value
        case .paddleReturn(let edgeShot):
            if showTutorial { dismissTutorial() }
            if edgeShot {
                haptics.brake(enabled: hapticsEnabled)
                audio.play(.departure, enabled: soundEnabled)
            } else {
                haptics.perfect(enabled: hapticsEnabled)
                audio.play(.brake, enabled: soundEnabled)
            }
        case .brickDestroyed:
            haptics.perfect(enabled: hapticsEnabled)
            audio.play(.doors, enabled: soundEnabled)
        case .powerActivated:
            haptics.match(enabled: hapticsEnabled)
            audio.play(.perfect, enabled: soundEnabled)
        case .itemCollected:
            haptics.match(enabled: hapticsEnabled)
            audio.play(.departure, enabled: soundEnabled)
        case .negativeHit:
            haptics.overflow(enabled: hapticsEnabled)
            audio.play(.missed, enabled: soundEnabled)
        case .cleanDrop:
            haptics.match(enabled: hapticsEnabled)
            audio.play(.departure, enabled: soundEnabled)
        case .finished(let result):
            profile.bestScore = max(profile.bestScore, result.score)
            profile.bestHeight = max(profile.bestHeight, result.height)
            profile.bestCombo = max(profile.bestCombo, result.maxCombo)
            profile.bestLink = max(profile.bestLink, result.maxLink)
            profile.totalRuns += 1
            persistence.save(profile)
            activeRunID = nil
            currentScene = nil
            route = .result(result)
        }
    }

    private static func loadDescentCleanTop10() -> [DescentCleanRankRecord] {
        guard let data = UserDefaults.standard.data(forKey: "descent.endless.cleanTop10.v1"),
              let records = try? JSONDecoder().decode([DescentCleanRankRecord].self, from: data) else {
            return []
        }
        return Array(records.prefix(10))
    }

    private static func stableGrantID(_ source: String) -> UInt64 {
        source.utf8.reduce(14_695_981_039_346_656_037) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }
}
