import SwiftUI

struct ResultView: View {
    @ObservedObject var model: AppModel
    let result: RunResult

    var body: some View {
        ZStack {
            resultBackdrop

            ScrollView(showsIndicators: false) {
                VStack(spacing: GameSpacing.medium) {
                    resultHeader
                    scorePanel

                    Button("같은 구조 다시") {
                        model.startGame()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("retryButton")

                    statGrid
                    skillBuild
                    actions
                }
                .padding(.horizontal, GameSpacing.large)
                .padding(.top, GameSpacing.large)
                .padding(.bottom, GameSpacing.section)
            }
        }
    }

    private var resultBackdrop: some View {
        ZStack {
            GamePalette.canvas.ignoresSafeArea()
            GeometryReader { proxy in
                Image("RS_Playfield_Background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.50)
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    GamePalette.deep.opacity(0.44),
                    GamePalette.canvas.opacity(0.78),
                    GamePalette.deep.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    (result.isNewBest ? GamePalette.fire : GamePalette.info).opacity(0.14),
                    .clear
                ],
                center: .top,
                startRadius: 10,
                endRadius: 280
            )
            .ignoresSafeArea()
        }
    }

    private var resultHeader: some View {
        VStack(spacing: GameSpacing.small) {
            HStack {
                Label("RUN COMPLETE", systemImage: "flag.checkered")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.3)
                    .foregroundStyle(GamePalette.info)
                Spacer()
                Text("구조 코드 \(DailySeed.current())")
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundStyle(GamePalette.textMuted)
            }

            Text(result.headline)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(GamePalette.textPrimary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.74)

            Text(recordDeltaText)
                .font(.system(.subheadline, design: .rounded, weight: .black))
                .tracking(0.5)
                .foregroundStyle(result.isNewBest ? GamePalette.fireCore : GamePalette.textSecondary)
                .padding(.horizontal, GameSpacing.medium)
                .frame(minHeight: 34)
                .background(
                    (result.isNewBest ? GamePalette.fire : GamePalette.surface2).opacity(0.16),
                    in: RoundedRectangle(cornerRadius: GameRadius.badge)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GameRadius.badge)
                        .stroke((result.isNewBest ? GamePalette.fire : GamePalette.border).opacity(0.72))
                )
                .accessibilityIdentifier("recordDeltaLabel")
        }
    }

    private var scorePanel: some View {
        HStack(spacing: GameSpacing.large) {
            ZStack {
                Circle()
                    .fill(GamePalette.surface2)
                    .frame(width: 86, height: 86)
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [GamePalette.fire, GamePalette.fireCore, GamePalette.danger, GamePalette.fire],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 78, height: 78)
                Text(result.grade)
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(GamePalette.fireCore)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("최종 점수")
                    .font(.system(.caption2, design: .rounded, weight: .black))
                    .tracking(1.1)
                    .foregroundStyle(GamePalette.textMuted)
                Text(result.score.formatted())
                    .font(.system(size: 47, weight: .black, design: .rounded))
                    .foregroundStyle(GamePalette.textPrimary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text("이전 최고  \(result.previousBestScore.formatted())")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(GameSpacing.large)
        .background(GamePalette.surface1.opacity(0.96), in: RoundedRectangle(cornerRadius: GameRadius.panel))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, GamePalette.fire, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, GameSpacing.medium)
        }
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.panel)
                .stroke(GamePalette.borderSubtle)
        )
        .overlay {
            Image("RS_HUD_Frame")
                .resizable()
                .scaledToFill()
                .blendMode(.screen)
                .opacity(0.78)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: GameSpacing.small) {
            resultStat(icon: "arrow.up.to.line", title: "높이", value: "\(result.height)m", color: GamePalette.info)
            resultStat(icon: "burst.fill", title: "콤보", value: "×\(result.maxCombo)", color: GamePalette.fireCore)
            resultStat(icon: "link", title: "링크", value: "\(result.maxLink)/5", color: GamePalette.success)
            resultStat(icon: "bolt.fill", title: "공명", value: "\(result.powerActivations)", color: GamePalette.electric)
            resultStat(icon: "square.3.layers.3d", title: "파괴", value: "\(result.destroyedBrickCount)", color: GamePalette.danger)
            resultStat(icon: "wand.and.stars", title: "코어", value: "\(result.totalItemsCollected)", color: GamePalette.arcane)
        }
    }

    @ViewBuilder
    private var skillBuild: some View {
        if result.totalItemsCollected > 0 {
            VStack(alignment: .leading, spacing: GameSpacing.small) {
                Text("FINAL BUILD")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.1)
                    .foregroundStyle(GamePalette.textMuted)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: GameSpacing.small)], spacing: GameSpacing.small) {
                    ForEach(AttackItemKind.allCases, id: \.self) { kind in
                        if result.attackItemLevels.level(for: kind) > 0 {
                            Label(
                                "\(kind.name)  LV.\(result.attackItemLevels.level(for: kind))",
                                systemImage: kind.systemImage
                            )
                            .font(.system(.caption, design: .rounded, weight: .black))
                            .foregroundStyle(GamePalette.attackCore(kind))
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(
                                GamePalette.attack(kind).opacity(0.12),
                                in: RoundedRectangle(cornerRadius: GameRadius.badge)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: GameRadius.badge)
                                    .stroke(GamePalette.attack(kind).opacity(0.72))
                            )
                        }
                    }
                }
            }
            .padding(GameSpacing.medium)
            .background(GamePalette.surface0.opacity(0.92), in: RoundedRectangle(cornerRadius: GameRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: GameRadius.card)
                    .stroke(GamePalette.borderSubtle)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                AttackItemKind.allCases
                    .filter { result.attackItemLevels.level(for: $0) > 0 }
                    .map { "\($0.name) 레벨 \(result.attackItemLevels.level(for: $0))" }
                    .joined(separator: ", ")
            )
        }
    }

    private var actions: some View {
        VStack(spacing: GameSpacing.small) {
            ShareLink(item: result.shareText) {
                Label("기록 공유", systemImage: "square.and.arrow.up.fill")
                    .font(.headline.weight(.heavy))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(GamePalette.surface2, in: RoundedRectangle(cornerRadius: GameRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: GameRadius.button)
                            .stroke(GamePalette.borderStrong)
                    )
            }
            .foregroundStyle(GamePalette.textPrimary)
            .accessibilityIdentifier("shareResultButton")

            Button("홈으로") { model.goHome() }
                .font(.headline.weight(.bold))
                .foregroundStyle(GamePalette.textSecondary)
                .frame(minHeight: 44)
                .accessibilityIdentifier("resultHomeButton")
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

    private func resultStat(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(GamePalette.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(GamePalette.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(GamePalette.surface1.opacity(0.92), in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.card)
                .stroke(GamePalette.borderSubtle)
        )
    }
}
