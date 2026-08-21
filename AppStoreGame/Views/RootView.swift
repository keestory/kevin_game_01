import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    private var opensDesignSystemGallery: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-designGallery")
#else
        false
#endif
    }

    private var opensResearchConsole: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-descentResearchConsole")
#else
        false
#endif
    }

    private var usesResearchConsoleSample: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uiTestingResearchConsoleSample")
#else
        false
#endif
    }

    var body: some View {
        Group {
            if opensDesignSystemGallery {
                DesignSystemGalleryView()
            } else if opensResearchConsole {
#if DEBUG
                DescentResearchConsoleView(usesSampleData: usesResearchConsoleSample)
#endif
            } else if let message = model.descentResearchBlockingMessage {
                researchAssignmentError(message: message)
            } else {
                productFlow
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard !opensDesignSystemGallery, !opensResearchConsole else { return }
            model.setApplicationActive(phase == .active)
        }
    }

    private func researchAssignmentError(message: String) -> some View {
        ZStack {
            GamePalette.canvas.ignoresSafeArea()
            VStack(spacing: GameSpacing.large) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(GamePalette.danger)
                Text("RESEARCH ASSIGNMENT BLOCKED")
                    .font(.system(.headline, design: .monospaced, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text(message)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(GameSpacing.xLarge)
            .glassCard()
            .padding(GameSpacing.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("researchAssignmentError")
    }

    @ViewBuilder
    private var productFlow: some View {
        ZStack {
            switch model.route {
            case .home:
                HomeView(model: model)
                    .transition(.opacity)
            case .game:
                if let scene = model.currentScene {
                    GameContainerView(model: model, scene: scene)
                        .transition(.opacity)
                }
            case .descent:
                if let scene = model.currentDescentScene {
                    DescentGameContainerView(
                        scene: scene,
                        bestScore: scene.snapshot.isRankedEndless
                            ? model.descentCleanBestScore
                            : model.descentBestScore,
                        assistedBestScore: model.descentAssistedBestScore,
                        extraLives: model.descentExtraLives,
                        canOfferReward: model.canOfferMockDescentReward,
                        isRequestingReward: model.isRequestingDescentReward,
                        assistMessage: model.descentAssistMessage,
                        requestRewardedRevive: {
                            Task { await model.requestRewardedDescentRevive() }
                        },
                        useExtraLife: model.useDescentExtraLife,
                        finalizeRun: model.finalizeDescentRun,
                        retry: model.startDescent,
                        home: model.goHome
                    )
                    .transition(.opacity)
                }
            case .result(let result):
                ResultView(model: model, result: result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.route)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-autoStartRankedEndless"), case .home = model.route {
                model.startRankedEndless()
            } else if ProcessInfo.processInfo.arguments.contains("-autoStartDescent"), case .home = model.route {
                model.startDescent()
            } else if ProcessInfo.processInfo.arguments.contains("-autoStart"), case .home = model.route {
                model.startGame()
            }
        }
    }
}
