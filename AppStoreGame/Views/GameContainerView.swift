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
            .accessibilityLabel("실제 지하철 정차 게임")
            .accessibilityHint("노란 정차선에 가까워졌을 때 하단 제동 버튼을 누르세요")
            .accessibilityValue(gameAccessibilityValue)
            .accessibilityIdentifier("trainGameScene")

            VStack(spacing: 0) {
                GameHUD(snapshot: model.snapshot) {
                    model.pause()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                StationBanner(snapshot: model.snapshot)
                    .padding(.top, 9)

                Spacer()

                BrakePanel(snapshot: model.snapshot) {
                    scene.applyBrake()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }

            if model.showTutorial {
                VStack {
                    Spacer()
                    TutorialCoachmark()
                        .padding(.bottom, 174)
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            if model.showRescueOffer {
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
            scene.setReduceMotion(reduceMotion)
        }
        .onChange(of: reduceMotion) { _, enabled in
            scene.setReduceMotion(enabled)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.showTutorial)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.snapshot.phase)
    }

    private var gameAccessibilityValue: String {
        if model.snapshot.doorsOpen {
            return "승하차 중, 현재 \(model.snapshot.exited)명 하차"
        }
        if let grade = model.snapshot.lastBrakeGrade {
            let label = switch grade {
            case .perfect: "정위치"
            case .safe: "안전 정차"
            case .near: "가까움"
            case .missed: "역 통과"
            }
            return "제동 결과 \(label), 현재 \(model.snapshot.exited)명 하차"
        }
        if model.snapshot.canBrake {
            return "지금 제동, 정차선 접근 중"
        }
        return "역 접근 중, \(model.snapshot.timeText)초 남음"
    }
}

private struct GameHUD: View {
    let snapshot: RunSnapshot
    let pause: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("하차")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.46))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(snapshot.exited.formatted())
                        .foregroundStyle(Color.exitMint)
                    Text("/ \(snapshot.targetExited)명")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .font(.system(size: 24, weight: .black, design: .rounded))
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
                VStack(alignment: .trailing, spacing: 2) {
                    Text(snapshot.doorsOpen ? "승하차 중" : "운행 구간")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(snapshot.doorsOpen ? Color.exitMint : .white.opacity(0.46))
                    Text("\(snapshot.stopIndex)/\(snapshot.stationCount)역")
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
        .background(.ultraThinMaterial.opacity(0.78), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct StationBanner: View {
    let snapshot: RunSnapshot

    private let names = ["첫빛역", "구름역", "노을역", "별빛역", "달빛역"]
    private let exitDemands = [5, 6, 6, 7, 8]

    private var stationIndex: Int {
        min(names.count - 1, max(0, snapshot.stopIndex - 1))
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: snapshot.doorsOpen ? "door.left.hand.open" : "tram.fill")
                .foregroundStyle(snapshot.doorsOpen ? Color.exitMint : Color.safetyYellow)
            Text(snapshot.doorsOpen ? "문이 열렸어요 · 질서 있게 승하차" : "다음 \(names[stationIndex]) · 정위치 시 최대 \(exitDemands[stationIndex])명 하차")
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.trainNavy.opacity(0.78), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.10)))
        .accessibilityElement(children: .combine)
    }
}

private struct BrakePanel: View {
    let snapshot: RunSnapshot
    let brake: () -> Void

    var body: some View {
        VStack(spacing: 9) {
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(Color.safetyYellow.opacity(0.22))
                        .frame(width: 82)
                        .offset(x: width * 0.75 - 41)
                    Capsule()
                        .fill(Color.exitMint.opacity(0.82))
                        .frame(width: 28)
                        .offset(x: width * 0.75 - 14)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 3, height: 28)
                        .offset(x: width * 0.75 - 1.5)
                    ZStack {
                        Circle()
                            .fill(snapshot.canBrake ? Color.safetyYellow : Color.white.opacity(0.42))
                        Image(systemName: "tram.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(Color.trainNavy)
                    }
                    .frame(width: 28, height: 28)
                    .shadow(color: snapshot.canBrake ? Color.safetyYellow.opacity(0.6) : .clear, radius: 7)
                    .offset(x: min(width - 28, max(0, width * snapshot.approachProgress - 14)))
                }
            }
            .frame(height: 28)
            .accessibilityHidden(true)

            HStack {
                Spacer()
                Text("△ 정위치 정차선")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.76))
                Spacer()
                    .frame(width: 48)
            }
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            Button(action: brake) {
                HStack(spacing: 10) {
                    Image(systemName: snapshot.doorsOpen ? "door.left.hand.open" : "hand.tap.fill")
                    Text(snapshot.doorsOpen ? "승하차 중" : (snapshot.canBrake ? "지금 제동" : "역 접근 중"))
                    if snapshot.canBrake && !snapshot.doorsOpen {
                        Image(systemName: "exclamationmark")
                            .symbolEffect(.pulse)
                    }
                }
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(Color.trainNavy)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(
                    snapshot.canBrake ? Color.safetyYellow : Color.white.opacity(0.34),
                    in: RoundedRectangle(cornerRadius: 22)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(snapshot.canBrake ? 0.82 : 0.20), lineWidth: 3)
                )
            }
            .buttonStyle(.plain)
            .disabled(!snapshot.canBrake || snapshot.doorsOpen)
            .accessibilityLabel(snapshot.doorsOpen ? "승하차 중" : (snapshot.canBrake ? "지금 제동" : "역 접근 중"))
            .accessibilityHint("정차선에 열차 표시가 가까워졌을 때 누르세요")
            .accessibilityIdentifier("brakeButton")
        }
        .padding(12)
        .background(.ultraThinMaterial.opacity(0.84), in: RoundedRectangle(cornerRadius: 28))
    }
}

private struct TutorialCoachmark: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.to.line.compact")
                .font(.title3.weight(.black))
                .foregroundStyle(Color.safetyYellow)
            Text("노란 구간에서 ‘지금 제동’을 누르세요")
                .font(.system(.headline, design: .rounded, weight: .black))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(Color.trainNavy.opacity(0.94), in: Capsule())
        .overlay(Capsule().stroke(Color.safetyYellow.opacity(0.65), lineWidth: 2))
        .shadow(color: .black.opacity(0.28), radius: 14, y: 7)
    }
}

private struct RescueOverlay: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color.trainNavy.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "tram.fill.tunnel")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.alertCoral)

                Text("다음 역이면 도착할 수 있어요")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .multilineTextAlignment(.center)

                Text("추가 역 1회에서 최대 8명이 더 내릴 수 있어요.\n광고 없이 같은 운행 재시도도 가능합니다.")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.68))
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
                                Image(systemName: model.rescueOfferIsFree ? "ticket.fill" : "play.rectangle.fill")
                            }
                            Text(model.rescueOfferIsFree ? "첫 운행 무료 연장 · 다음 역 +12초" : "광고 1회 보고 다음 역 +12초")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(model.isRescueLoading)
                    .accessibilityIdentifier("acceptRescueButton")
                }

                Button("무료로 같은 운행 다시") {
                    model.restartFromRescueOffer()
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))
                .padding(.vertical, 12)
                .disabled(model.isRescueLoading)
                .accessibilityIdentifier("declineRescueButton")
            }
            .padding(28)
        }
    }
}

private struct PauseOverlay: View {
    let resume: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Color.trainNavy.opacity(0.86).ignoresSafeArea()
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
