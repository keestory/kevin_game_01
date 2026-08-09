import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
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
            case .result(let result):
                ResultView(model: model, result: result)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.route)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-autoStart"), case .home = model.route {
                model.startGame()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            model.setApplicationActive(phase == .active)
        }
    }
}
