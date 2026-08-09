import SwiftUI

struct ResultView: View {
    @ObservedObject var model: AppModel
    let result: RunResult

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.trainNavy, Color(hex: 0x1B2C4C)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text(result.completed ? "다음 역이 열렸어요" : "새 운행은 목숨 없이 바로 시작할 수 있어요")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.exitMint)
                        .padding(.top, 20)

                    VStack(spacing: 4) {
                        Text(result.headline)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                        Text("오늘의 운행 등급")
                            .foregroundStyle(.white.opacity(0.50))
                    }

                    ZStack {
                        Circle()
                            .fill(Color.safetyYellow.opacity(0.15))
                            .frame(width: 156, height: 156)
                        Circle()
                            .stroke(Color.safetyYellow, lineWidth: 5)
                            .frame(width: 132, height: 132)
                        Text(result.grade)
                            .font(.system(size: 82, weight: .black, design: .rounded))
                            .foregroundStyle(Color.safetyYellow)
                    }

                    VStack(spacing: 8) {
                        Text(result.score.formatted())
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("BEST  \(model.profile.bestScore.formatted())")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white.opacity(0.42))
                    }

                    if result.rescueUsed || result.assisted {
                        HStack(spacing: 7) {
                            Image(systemName: "lifepreserver.fill")
                            Text(result.rescueUsed ? "구조 운행 기록" : "혼잡 완화 운행 기록")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.exitMint)
                    }

                    HStack(spacing: 10) {
                        resultStat(icon: "person.2.fill", title: "하차", value: "\(result.exited)명")
                        resultStat(icon: "arrow.triangle.branch", title: "최고 환승", value: "×\(max(1, result.bestChain))")
                        resultStat(icon: "person.badge.plus", title: "탑승", value: "\(result.boarded)명")
                    }

                    VStack(spacing: 12) {
                        Button(result.completed ? "다음 역 바로 출발" : "같은 역 다시 도전") {
                            model.startGame()
                        }
                            .buttonStyle(PrimaryButtonStyle())
                            .accessibilityIdentifier("retryButton")

                        ShareLink(item: result.shareText + " 몇 점까지 갈 수 있을까?") {
                            Label("친구에게 기록 공유하기", systemImage: "person.2.wave.2.fill")
                                .font(.headline.weight(.heavy))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                        }
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("shareResultButton")

                        Button("홈으로") { model.goHome() }
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.58))
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private func resultStat(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(Color.exitMint)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}
