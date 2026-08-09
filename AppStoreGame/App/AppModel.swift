import Combine
import Foundation
import SpriteKit

@MainActor
final class AppModel: ObservableObject, TrainGameSceneDelegate {
    @Published private(set) var route: AppRoute = .home
    @Published private(set) var snapshot = RunSnapshot()
    @Published private(set) var profile: PlayerProfile
    @Published var showTutorial = false
    @Published var showSettings = false
    @Published private(set) var currentScene: GameScene?
    @Published private(set) var showRescueOffer = false
    @Published private(set) var isRescueLoading = false
    @Published var rescueErrorMessage: String?

    private let persistence: PersistenceService
    private let haptics = HapticService()
    private let seed: UInt64
    private let rewardedAdService: any RewardedAdServing
    private var processedImpressionIDs = Set<String>()
    private var activeRunID: UUID?
    private var pendingRewardRunID: UUID?
    private var appIsActive = true

    var hapticsEnabled: Bool {
        UserDefaults.standard.object(forKey: "settings.haptics") as? Bool ?? true
    }

    var currentDifficulty: StageDifficulty {
        GameRules.stageDifficulty(
            stage: profile.highestStage,
            consecutiveFailures: profile.consecutiveFailures
        )
    }

    var rescueOfferIsFree: Bool { !profile.freeRescueUsed }
    var isRewardedAdAvailable: Bool { rewardedAdService.isReady }
    var hasPendingRescueReward: Bool {
        pendingRewardRunID != nil && pendingRewardRunID == activeRunID
    }

    init(
        persistence: PersistenceService = .shared,
        seed: UInt64 = DailySeed.current(),
        rewardedAdService: (any RewardedAdServing)? = nil
    ) {
        self.persistence = persistence
        self.profile = persistence.load()
        self.seed = seed
        if let rewardedAdService {
            self.rewardedAdService = rewardedAdService
        } else {
#if DEBUG
            self.rewardedAdService = MockRewardedAdService()
#else
            self.rewardedAdService = UnavailableRewardedAdService()
#endif
        }
        haptics.prepare()
    }

    func startGame() {
        let difficulty = currentDifficulty
        activeRunID = UUID()
        pendingRewardRunID = nil
        let stageSeed = seed ^ (UInt64(difficulty.stage) &* 0x9E3779B97F4A7C15)
        let newScene = GameScene(
            size: CGSize(width: 390, height: 844),
            seed: stageSeed,
            difficulty: difficulty
        )
        newScene.gameDelegate = self
        route = .game
        snapshot = RunSnapshot()
        showTutorial = !profile.tutorialSeen
        showRescueOffer = false
        rescueErrorMessage = nil
        currentScene = newScene
    }

    func dismissTutorial() {
        showTutorial = false
        profile.tutorialSeen = true
        persistence.save(profile)
        currentScene?.setRunPaused(false)
    }

    func pause() {
        currentScene?.setRunPaused(true)
    }

    func resume() {
        currentScene?.setRunPaused(false)
    }

    func acceptRescue() async {
        guard showRescueOffer, !isRescueLoading else { return }

        if hasPendingRescueReward {
            completeRescueForActiveRun()
            return
        }

        if rescueOfferIsFree {
            profile.freeRescueUsed = true
            persistence.save(profile)
            showRescueOffer = false
            currentScene?.acceptRescue()
            return
        }

        guard rewardedAdService.isReady else {
            rescueErrorMessage = "지금은 광고를 불러올 수 없어요. 새 운행은 바로 시작할 수 있어요."
            return
        }

        guard let requestedRunID = activeRunID,
              let requestedScene = currentScene else { return }

        isRescueLoading = true
        rescueErrorMessage = nil
        let outcome = await rewardedAdService.showRescueAd()
        isRescueLoading = false

        guard activeRunID == requestedRunID,
              currentScene === requestedScene,
              case .game = route,
              showRescueOffer else { return }

        switch outcome {
        case .rewarded(let impressionID):
            guard processedImpressionIDs.insert(impressionID).inserted else { return }
            profile.rewardedContinuesUsedTotal += 1
            persistence.save(profile)
            if appIsActive {
                completeRescueForActiveRun()
            } else {
                pendingRewardRunID = requestedRunID
                rescueErrorMessage = "구조 보상을 받았어요. 앱으로 돌아와 계속 운행해 주세요."
            }
        case .dismissed:
            rescueErrorMessage = "광고를 끝까지 보면 구조를 받을 수 있어요."
        case .unavailable, .failed:
            rescueErrorMessage = "광고를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    func declineRescue() {
        guard showRescueOffer, !isRescueLoading else { return }
        showRescueOffer = false
        currentScene?.declineRescue()
    }

    func goHome() {
        currentScene?.removeAllActions()
        activeRunID = nil
        pendingRewardRunID = nil
        showRescueOffer = false
        route = .home
    }

    func setApplicationActive(_ isActive: Bool) {
        appIsActive = isActive
        if !isActive, case .game = route {
            pause()
        }
    }

    private func completeRescueForActiveRun() {
        guard appIsActive, activeRunID != nil else { return }
        pendingRewardRunID = nil
        showRescueOffer = false
        rescueErrorMessage = nil
        currentScene?.acceptRescue()
    }

    func gameScene(_ scene: GameScene, didEmit event: GameEvent) {
        switch event {
        case .snapshot(let value):
            snapshot = value
        case .perfect:
            haptics.perfect(enabled: hapticsEnabled)
        case .match:
            haptics.match(enabled: hapticsEnabled)
        case .overflow:
            haptics.overflow(enabled: hapticsEnabled)
        case .rescueRequested:
            showRescueOffer = true
        case .finished(let result):
            profile.bestScore = max(profile.bestScore, result.score)
            profile.totalRuns += 1
            profile.totalExited += result.exited
            if result.completed {
                profile.highestStage = max(profile.highestStage, result.stage + 1)
                profile.consecutiveFailures = 0
            } else {
                profile.consecutiveFailures += 1
            }
            persistence.save(profile)
            activeRunID = nil
            pendingRewardRunID = nil
            showRescueOffer = false
            route = .result(result)
        }
    }
}
