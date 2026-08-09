import SpriteKit
import SwiftUI

struct GameContainerView: View {
    @ObservedObject var model: AppModel
    let scene: GameScene
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            SpriteView(
                scene: scene,
                preferredFramesPerSecond: 60,
                options: [.ignoresSiblingOrder]
            )
            .ignoresSafeArea()
            .accessibilityLabel("만원열차 퍼즐 보드")
            .accessibilityHint("노란 문이 원하는 칸에 왔을 때 화면을 탭하세요")

            VStack(spacing: 0) {
                GameHUD(snapshot: model.snapshot) {
                    model.pause()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                Spacer()
                QueuePreview(snapshot: model.snapshot)
                    .padding(.bottom, 12)
                    .allowsHitTesting(false)
            }

            if model.showTutorial {
                TutorialOverlay {
                    model.dismissTutorial()
                }
                .transition(.opacity)
            } else if model.showRescueOffer {
                RescueOverlay(model: model)
                    .transition(.opacity)
            } else if model.snapshot.phase == .paused {
                PauseOverlay(
                    resume: { model.resume() },
                    home: { model.goHome() }
                )
                .transition(.opacity)
            }
        }
        .task {
            if model.showTutorial {
                try? await Task.sleep(for: .milliseconds(80))
                scene.setRunPaused(true)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.showTutorial)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.snapshot.phase)
    }
}

private struct GameHUD: View {
    let snapshot: RunSnapshot
    let pause: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("\(snapshot.stage)역  ·  목표 \(snapshot.targetScore.formatted())")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                Text("\(snapshot.score.formatted()) / \(snapshot.targetScore.formatted())")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: 1 - snapshot.progress)
                    .stroke(Color.safetyYellow, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(snapshot.timeText)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 57, height: 57)
            .accessibilityLabel("남은 시간 \(snapshot.timeText)초")

            HStack(spacing: 7) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(snapshot.assisted ? "도움 운행" : "안전 손잡이")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                    Text("×\(snapshot.safetyHandles)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                }
                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .black))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .foregroundStyle(.white)
                .accessibilityLabel("일시정지")
                .accessibilityIdentifier("pauseButton")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.76), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct RescueOverlay: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color.trainNavy.opacity(0.90).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lifepreserver.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.alertCoral)

                Text("한 칸만 비웠다면 출발!")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .multilineTextAlignment(.center)

                Text("가장 높은 두 칸에서 2명씩 하차하고\n제한 시간을 15초 늘려드려요.")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.66))
                    .multilineTextAlignment(.center)

                if let message = model.rescueErrorMessage {
                    Text(message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.alertCoral)
                        .multilineTextAlignment(.center)
                }

                if model.rescueOfferIsFree || model.isRewardedAdAvailable || model.hasPendingRescueReward {
                    Button {
                        Task { await model.acceptRescue() }
                    } label: {
                        HStack {
                            if model.isRescueLoading {
                                ProgressView().tint(Color.trainNavy)
                            } else {
                                Image(systemName: model.hasPendingRescueReward ? "checkmark.seal.fill" : (model.rescueOfferIsFree ? "cross.case.fill" : "play.rectangle.fill"))
                            }
                            Text(
                                model.hasPendingRescueReward
                                    ? "받은 보상으로 구조 계속"
                                    : (model.rescueOfferIsFree ? "첫 운행 무료 구조" : "광고 1회 보고 구조 요청")
                            )
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(model.isRescueLoading)
                    .accessibilityIdentifier("acceptRescueButton")
                }

                Button("결과 보고 새 운행 시작") {
                    model.declineRescue()
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
                .padding(.vertical, 12)
                .disabled(model.isRescueLoading)
                .accessibilityIdentifier("declineRescueButton")
            }
            .padding(28)
        }
    }
}

private struct QueuePreview: View {
    let snapshot: RunSnapshot

    var body: some View {
        HStack(spacing: 10) {
            Label("다음", systemImage: "person.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.55))
            ForEach(Array(snapshot.upcoming.enumerated()), id: \.offset) { index, kind in
                Text(kind.badge)
                    .font(.system(size: index == 0 ? 18 : 14, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: kind.tintHex))
                    .frame(width: index == 0 ? 34 : 29, height: index == 0 ? 34 : 29)
                    .background(Color.white.opacity(index == 0 ? 0.11 : 0.07), in: Circle())
                    .opacity(index == 0 ? 1 : 0.65)
            }
            Text("\(snapshot.station)/4역")
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .foregroundStyle(Color.exitMint)
                .padding(.leading, 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.ultraThinMaterial.opacity(0.70), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("다음 승객 \(snapshot.upcoming.map(\.name).joined(separator: ", "))")
    }
}

private struct TutorialOverlay: View {
    let start: () -> Void

    var body: some View {
        ZStack {
            Color.trainNavy.opacity(0.90).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("탭 한 번이면 출발!")
                    .font(.system(size: 30, weight: .black, design: .rounded))

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.warmIvory)
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.left.and.right")
                            .foregroundStyle(Color.trainNavy.opacity(0.45))
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.safetyYellow)
                                .frame(width: 66, height: 62)
                            Text("★")
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(Color(hex: PassengerKind.star.tintHex))
                        }
                        Image(systemName: "hand.tap.fill")
                            .font(.title)
                            .foregroundStyle(Color.trainNavy)
                    }
                }
                .frame(height: 126)

                VStack(alignment: .leading, spacing: 16) {
                    tutorialRow(number: "1", text: "노란 문이 원하는 칸에 오면 아무 곳이나 탭")
                    tutorialRow(number: "2", text: "같은 배지 3명을 연결하면 함께 하차")
                    tutorialRow(number: "3", text: "안전 손잡이를 활용해 목표 점수를 달성")
                }

                Button("연습 없이 바로 출발") { start() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("dismissTutorialButton")
            }
            .padding(24)
        }
    }

    private func tutorialRow(number: String, text: String) -> some View {
        HStack(spacing: 13) {
            Text(number)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(Color.trainNavy)
                .frame(width: 34, height: 34)
                .background(Color.exitMint, in: Circle())
            Text(text)
                .font(.system(.body, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct PauseOverlay: View {
    let resume: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Color.trainNavy.opacity(0.84).ignoresSafeArea()
            VStack(spacing: 17) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.safetyYellow)
                Text("잠시 정차 중")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                Text("준비되면 다시 출발하세요")
                    .foregroundStyle(.white.opacity(0.60))
                Button("계속 운행") { resume() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("resumeButton")
                Button("오늘은 여기까지") { home() }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.vertical, 12)
            }
            .padding(28)
        }
    }
}
