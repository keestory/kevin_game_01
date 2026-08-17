import Combine
import Foundation
import SpriteKit

@MainActor
final class AppModel: ObservableObject, GameSceneDelegate {
    @Published private(set) var route: AppRoute = .home
    @Published private(set) var snapshot = RunSnapshot()
    @Published private(set) var profile: PlayerProfile
    @Published var showTutorial = false
    @Published var showSettings = false
    @Published private(set) var currentScene: GameScene?

    let visualVariant = VisualVariant.current

    private let persistence: PersistenceService
    private let haptics = HapticService()
    private let audio = GameAudioService()
    private let seed: UInt64
    private let skipTutorialForTesting: Bool
    private var activeRunID: UUID?

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
        self.persistence = persistence
        self.profile = arguments.contains("-uiTesting") ? PlayerProfile() : persistence.load()
        self.seed = arguments.contains("-uiTesting") ? 42 : seed
        self.skipTutorialForTesting = arguments.contains("-skipTutorial")
        haptics.prepare()
    }

    func startGame() {
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
        route = .game
    }

    func dismissTutorial() {
        showTutorial = false
        profile.tutorialSeen = true
        persistence.save(profile)
    }

    func pause() {
        currentScene?.setRunPaused(true)
    }

    func resume() {
        currentScene?.setRunPaused(false)
    }

    func goHome() {
        currentScene?.removeAllActions()
        currentScene = nil
        activeRunID = nil
        route = .home
    }

    func setApplicationActive(_ isActive: Bool) {
        if !isActive, case .game = route {
            audio.stop()
            pause()
        }
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
}
