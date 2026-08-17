import SwiftUI

struct ResultView: View {
    @ObservedObject var model: AppModel
    let result: RunResult

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Image("ReturnShotBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(model.visualVariant == .impactPop ? 0.78 : 0.62)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            LinearGradient(
                colors: [Color(hex: 0x071225).opacity(0.50), Color(hex: 0x0E2238).opacity(0.76), Color(hex: 0x28182E).opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("같은 구조 · 더 좋은 각도 · 더 높은 기록")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.exitMint)
                        .padding(.top, 22)

                    VStack(spacing: 5) {
                        Text(result.headline)
                            .font(.system(size: 33, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                        Text("점수 · 높이 · LINK · 스킬 빌드")
                            .foregroundStyle(.white.opacity(0.48))
                    }

                    Text(recordDeltaText)
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(result.isNewBest ? Color.safetyYellow : Color.white.opacity(0.72))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 38)
                        .background(
                            (result.isNewBest ? Color.alertCoral : Color.white).opacity(0.12),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke((result.isNewBest ? Color.safetyYellow : Color.white).opacity(0.24)))
                        .accessibilityIdentifier("recordDeltaLabel")

                    ZStack {
                        Circle()
                            .fill(Color.safetyYellow.opacity(0.12))
                            .frame(width: 110, height: 110)
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [Color.exitMint, Color.safetyYellow, Color.alertCoral, Color.exitMint],
                                    center: .center
                                ),
                                lineWidth: 6
                            )
                            .frame(width: 96, height: 96)
                        Text(result.grade)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundStyle(Color.safetyYellow)
                    }

                    VStack(spacing: 7) {
                        Text(result.score.formatted())
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("이전 PB  \(result.previousBestScore.formatted())")
                            .font(.system(.caption, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    Button("같은 구조 다시") {
                        model.startGame()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("retryButton")

                    HStack(spacing: 9) {
                        resultStat(icon: "arrow.up.to.line", title: "최고 높이", value: "\(result.height)m")
                        resultStat(icon: "burst.fill", title: "최대 콤보", value: "×\(result.maxCombo)")
                        resultStat(icon: "link", title: "최대 LINK", value: "\(result.maxLink)/5")
                    }

                    HStack(spacing: 9) {
                        resultStat(icon: "bolt.fill", title: "공명 폭주", value: "\(result.powerActivations)회")
                        resultStat(icon: "square.3.layers.3d", title: "파괴·낙하", value: "\(result.destroyedBrickCount)개")
                        resultStat(icon: "wand.and.stars", title: "스킬 코어", value: "\(result.totalItemsCollected)개")
                    }

                    if result.totalItemsCollected > 0 {
                        HStack(spacing: 7) {
                            ForEach(AttackItemKind.allCases, id: \.self) { kind in
                                if result.attackItemLevels.level(for: kind) > 0 {
                                    Label(
                                        "\(kind.name) L\(result.attackItemLevels.level(for: kind))",
                                        systemImage: kind.systemImage
                                    )
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(Color(hex: kind.tintHex))
                                    .padding(.horizontal, 7)
                                    .frame(minHeight: 28)
                                    .background(Color.white.opacity(0.07), in: Capsule())
                                }
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(
                            AttackItemKind.allCases
                                .filter { result.attackItemLevels.level(for: $0) > 0 }
                                .map { "\($0.name) 레벨 \(result.attackItemLevels.level(for: $0))" }
                                .joined(separator: ", ")
                        )
                    }

                    VStack(spacing: 12) {
                        ShareLink(item: result.shareText) {
                            Label("기록 공유하기", systemImage: "square.and.arrow.up.fill")
                                .font(.headline.weight(.heavy))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
                        }
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("shareResultButton")

                        Button("홈으로") { model.goHome() }
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.78))
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("resultHomeButton")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private var recordDeltaText: String {
        if result.isNewBest {
            return "NEW BEST  +\(result.scoreDeltaFromPreviousBest.formatted())"
        }
        if result.scoreDeltaFromPreviousBest < 0 {
            return "PB까지 \((-result.scoreDeltaFromPreviousBest).formatted())점"
        }
        return "PB와 같은 기록"
    }

    private func resultStat(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(Color.exitMint)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}
