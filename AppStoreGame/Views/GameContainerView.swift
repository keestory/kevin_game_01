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
            .accessibilityLabel("지옥철 목표 인원 문닫기 게임")
            .accessibilityHint("현재 탑승 인원이 목표와 같을 때 하단 문 닫기 레버를 누르세요")
            .accessibilityValue(gameAccessibilityValue)
            .accessibilityIdentifier("trainGameScene")

            VStack(spacing: 0) {
                GameHUD(snapshot: model.snapshot) {
                    model.pause()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Spacer()

                CloseDoorLever(
                    snapshot: model.snapshot,
                    close: { scene.closeDoors(observedRevision: model.snapshot.countRevision) }
                )
                .padding(.horizontal, 14)
                .padding(.bottom, 7)
            }

            if model.showTutorial {
                VStack {
                    Spacer()
                    TutorialCoachmark()
                        .padding(.bottom, 142)
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
            return "승하차 중, 현재 \(model.snapshot.onboardCount)명, 목표 \(model.snapshot.targetOnboardCount)명"
        }
        if let delta = model.snapshot.lastCloseDelta {
            if delta == 0 { return "목표 인원 정확히 맞음" }
            return delta > 0 ? "\(delta)명 초과" : "\(-delta)명 부족"
        }
        return "현재 \(model.snapshot.onboardCount)명, 목표 \(model.snapshot.targetOnboardCount)명, \(model.snapshot.timeText)초 남음"
    }
}

private struct GameHUD: View {
    let snapshot: RunSnapshot
    let pause: () -> Void

    var body: some View {
        VStack(spacing: 7) {
            HStack(spacing: 8) {
                Text("\(snapshot.stopIndex)/5역")
                    .font(.system(size: 20, weight: .black, design: .rounded))

                Text("정확 \(snapshot.currentChain)/3")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.exitMint)

                Spacer()

                Text(snapshot.clockStarted ? snapshot.timeText : "60")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .padding(.horizontal, 11)
                    .frame(height: 34)
                    .background(Color.safetyYellow.opacity(0.95), in: Capsule())
                    .foregroundStyle(Color.trainNavy)

                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 13, weight: .black))
                        .frame(width: 42, height: 38)
                        .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                }
                .foregroundStyle(.white)
                .accessibilityLabel("일시정지")
                .accessibilityIdentifier("pauseButton")
            }

            HStack(spacing: 9) {
                Image(systemName: "tram.fill")
                    .foregroundStyle(Color.exitMint)

                GeometryReader { proxy in
                    let progress = snapshot.flowProgress
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.11))
                        Capsule()
                            .fill(Color.exitMint)
                            .frame(width: max(8, proxy.size.width * progress))
                        HStack {
                            ForEach(0..<5, id: \.self) { station in
                                Circle()
                                    .fill(station < snapshot.stopIndex ? Color.exitMint : Color.white.opacity(0.66))
                                    .frame(width: station + 1 == snapshot.stopIndex ? 10 : 7)
                                if station < 4 { Spacer() }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .frame(height: 12)

                Text(snapshot.canCloseDoors ? "탑승 중" : "하차 중")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(snapshot.canCloseDoors ? Color.exitMint : .white.opacity(0.62))

            }
        }
        .padding(9)
        .background(Color.trainNavy.opacity(0.88), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.12)))
    }
}

private struct CloseDoorLever: View {
    let snapshot: RunSnapshot
    let close: () -> Void

    var body: some View {
        Button(action: close) {
            HStack(spacing: 17) {
                ZStack {
                    Circle()
                        .fill(snapshot.onboardCount == snapshot.targetOnboardCount ? Color.exitMint : Color.safetyYellow)
                        .frame(width: 74, height: 74)
                        .overlay(Circle().stroke(Color.white.opacity(0.84), lineWidth: 4))
                        .shadow(
                            color: (snapshot.onboardCount == snapshot.targetOnboardCount ? Color.exitMint : Color.safetyYellow).opacity(0.48),
                            radius: 13
                        )
                    Image(systemName: "door.left.hand.closed")
                        .font(.system(size: 31, weight: .black))
                        .foregroundStyle(Color.trainNavy)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(snapshot.canCloseDoors ? (snapshot.onboardCount == snapshot.targetOnboardCount ? "지금! 문 닫기" : "문 닫기") : "하차 중")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                    Text(snapshot.canCloseDoors ? "현재 \(snapshot.onboardCount) · 목표 \(snapshot.targetOnboardCount)" : "승객이 모두 내리면 활성화돼요")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                }
                Spacer()
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(snapshot.onboardCount == snapshot.targetOnboardCount ? Color.exitMint : Color.white.opacity(0.44))
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 96)
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .disabled(!snapshot.canCloseDoors)
        .background(Color.trainNavy.opacity(0.94), in: RoundedRectangle(cornerRadius: 34))
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(snapshot.onboardCount == snapshot.targetOnboardCount ? Color.exitMint : Color.safetyYellow.opacity(0.70), lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.42), radius: 18, y: 8)
        .accessibilityLabel(snapshot.canCloseDoors ? "문 닫기, 현재 \(snapshot.onboardCount)명, 목표 \(snapshot.targetOnboardCount)명" : "하차 중")
        .accessibilityIdentifier("closeDoorButton")
    }
}

private struct TutorialCoachmark: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "equal.circle.fill")
                .font(.title3.weight(.black))
                .foregroundStyle(Color.safetyYellow)
            Text("현재 인원과 목표가 같을 때 문을 닫으세요")
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
