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
            .accessibilityLabel("연쇄파괴 리턴 샷")
            .accessibilityHint("좌우로 끌어 패들을 움직입니다. 모서리에 공격 문양이 있는 벽돌을 직접 깨면 그 공격이 성장하고 발동합니다")
            .accessibilityValue(gameAccessibilityValue)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .decrement:
                    scene.movePaddleForAccessibility(by: -48)
                case .increment:
                    scene.movePaddleForAccessibility(by: 48)
                @unknown default:
                    break
                }
            }
            .accessibilityAction(named: "패들을 왼쪽으로 이동") {
                scene.movePaddleForAccessibility(by: -48)
            }
            .accessibilityAction(named: "패들을 오른쪽으로 이동") {
                scene.movePaddleForAccessibility(by: 48)
            }
            .accessibilityIdentifier("returnShotGameScene")

            VStack(spacing: GameSpacing.small) {
                GameHUD(snapshot: model.snapshot, pause: model.pause)
                SkillRail(snapshot: model.snapshot)

                if model.showTutorial {
                    TutorialCoachmark()
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                } else {
                    GameplayFeedbackBar(snapshot: model.snapshot)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }

                Spacer()
            }
            .padding(.horizontal, GameSpacing.medium)
            .padding(.top, GameSpacing.xSmall)

            if model.snapshot.phase == .paused {
                PauseOverlay(
                    snapshot: model.snapshot,
                    resume: model.resume,
                    home: model.goHome
                )
                .transition(.opacity)
            }
        }
        .task { scene.setReduceMotion(reduceMotion) }
        .onChange(of: reduceMotion) { _, enabled in
            scene.setReduceMotion(enabled)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: GameMotion.normal), value: model.showTutorial)
        .animation(reduceMotion ? nil : .easeInOut(duration: GameMotion.normal), value: model.snapshot.phase)
        .statusBarHidden(true)
    }

    private var gameAccessibilityValue: String {
        let power = model.snapshot.powerSeconds > 0
            ? ", 공명 폭주 \(model.snapshot.powerSeconds.formatted(.number.precision(.fractionLength(1))))초"
            : ""
        let skills = AttackItemKind.allCases
            .map { "\($0.name) 레벨 \(model.snapshot.attackItemLevels.level(for: $0))" }
            .joined(separator: ", ")
        let pierce = model.snapshot.pierceCharges > 0
            ? ", 관통 \(model.snapshot.pierceCharges)회 충전"
            : ""
        let overdrive = model.snapshot.overdriveCount > 0
            ? ", 맥스 오버드라이브 \(model.snapshot.overdriveCount)회"
            : ""
        return "레벨 \(model.snapshot.segment), 점수 \(model.snapshot.score), 높이 \(model.snapshot.height)미터, 콤보 \(model.snapshot.combo), \(model.snapshot.link.leadingText), \(skills), 방어막 단계 \(model.snapshot.stageArmor)\(pierce)\(overdrive)\(power)"
    }
}

private struct GameHUD: View {
    let snapshot: RunSnapshot
    let pause: () -> Void

    var body: some View {
        VStack(spacing: GameSpacing.small) {
            HStack(spacing: GameSpacing.small) {
                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .black))
                        .frame(width: 44, height: 44)
                        .background(GamePalette.surface3, in: RoundedRectangle(cornerRadius: GameRadius.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: GameRadius.button)
                                .stroke(GamePalette.borderStrong)
                        )
                }
                .foregroundStyle(GamePalette.textPrimary)
                .accessibilityLabel("일시정지")
                .accessibilityIdentifier("pauseButton")

                VStack(alignment: .leading, spacing: 0) {
                    Text("HEIGHT")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(GamePalette.textMuted)
                    Text("\(snapshot.height)m")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(GamePalette.info)
                        .monospacedDigit()
                }
                .frame(minWidth: 55, alignment: .leading)

                VStack(spacing: 0) {
                    Text("SCORE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(GamePalette.textMuted)
                    Text(snapshot.score.formatted())
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(GamePalette.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .trailing, spacing: 0) {
                    Text("COMBO")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(GamePalette.textMuted)
                    Text("×\(snapshot.combo)")
                        .font(.system(size: comboFontSize, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(comboColor)
                        .monospacedDigit()
                        .rotationEffect(.degrees(snapshot.combo >= 20 ? -6 : 0))
                        .shadow(color: comboColor.opacity(snapshot.combo >= 5 ? 0.72 : 0), radius: snapshot.combo >= 20 ? 10 : 5)
                        .scaleEffect(snapshot.combo >= 50 ? 1.12 : 1)
                        .contentTransition(.numericText())
                }
                .frame(minWidth: 54, alignment: .trailing)
            }

            HStack(spacing: GameSpacing.small) {
                Image(systemName: leadingIcon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(leadingColor)
                Text(snapshot.link.leadingText)
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < min(5, snapshot.link.highestCount) ? leadingColor : GamePalette.surface3)
                            .frame(width: 13, height: 5)
                    }
                }

                Spacer(minLength: 2)

                Text(recordPaceText)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(recordPaceColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            if snapshot.powerSeconds > 0 {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(GamePalette.surface3)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [GamePalette.fireCore, GamePalette.fire, GamePalette.danger],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: proxy.size.width * max(0, min(1, snapshot.powerProgress)))
                        }
                }
                .frame(height: 5)
                .accessibilityLabel("공명 폭주 남은 시간 \(snapshot.powerSeconds.formatted(.number.precision(.fractionLength(1))))초")
            }
        }
        .padding(.horizontal, GameSpacing.medium)
        .padding(.vertical, GameSpacing.small)
        .background(GamePalette.surface1.opacity(0.96), in: RoundedRectangle(cornerRadius: GameRadius.panel))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, snapshot.powerSeconds > 0 ? GamePalette.fire : GamePalette.info, .clear],
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
                .opacity(snapshot.powerSeconds > 0 ? 0.95 : 0.72)
                .allowsHitTesting(false)
        }
        .clipped()
        .shadow(color: GamePalette.deep.opacity(0.44), radius: 10, y: 4)
    }

    private var leadingIcon: String {
        if snapshot.link.colorCount >= snapshot.link.patternCount,
           snapshot.link.colorCount >= snapshot.link.markCount { return "paintpalette.fill" }
        if snapshot.link.patternCount >= snapshot.link.markCount { return "line.3.horizontal" }
        return "star.fill"
    }

    private var leadingColor: Color {
        snapshot.powerSeconds > 0 ? GamePalette.fireCore : GamePalette.success
    }

    private var comboColor: Color {
        if snapshot.combo >= 50 { return GamePalette.arcane }
        if snapshot.combo >= 20 { return GamePalette.fire }
        if snapshot.combo >= 10 { return GamePalette.fireCore }
        return GamePalette.textPrimary
    }

    private var comboFontSize: CGFloat {
        if snapshot.combo >= 50 { return 28 }
        if snapshot.combo >= 20 { return 25 }
        if snapshot.combo >= 5 { return 23 }
        return 21
    }

    private var recordPaceText: String {
        guard snapshot.bestScore > 0 else { return "FIRST RUN" }
        let delta = snapshot.score - snapshot.bestScore
        return delta >= 0 ? "PB +\(delta.formatted())" : "PB \((-delta).formatted())"
    }

    private var recordPaceColor: Color {
        snapshot.bestScore > 0 && snapshot.score >= snapshot.bestScore
            ? GamePalette.fireCore
            : GamePalette.textMuted
    }
}

private struct SkillRail: View {
    let snapshot: RunSnapshot

    var body: some View {
        HStack(spacing: GameSpacing.xSmall) {
            ForEach(AttackItemKind.allCases, id: \.self) { kind in
                SkillCoreChip(
                    kind: kind,
                    level: snapshot.attackItemLevels.level(for: kind),
                    charge: kind == .pierce ? snapshot.pierceCharges : 0,
                    isLatest: snapshot.lastCollectedItem == kind
                )
            }
        }
        .padding(GameSpacing.xSmall)
        .background(GamePalette.surface0.opacity(0.94), in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.card)
                .stroke(GamePalette.borderSubtle)
        )
        .overlay {
            Image("RS_HUD_Frame")
                .resizable()
                .scaledToFill()
                .blendMode(.screen)
                .opacity(0.48)
                .allowsHitTesting(false)
        }
        .clipped()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("skillCoreHUD")
    }
}

private struct SkillCoreChip: View {
    let kind: AttackItemKind
    let level: Int
    let charge: Int
    let isLatest: Bool

    private var active: Bool { level > 0 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 11, weight: .black))
            VStack(alignment: .leading, spacing: 0) {
                Text(kind.name)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .lineLimit(1)
                Text(levelText)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .monospacedDigit()
            }
        }
        .foregroundStyle(active ? GamePalette.attackCore(kind) : GamePalette.textMuted)
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(
            (active ? GamePalette.attack(kind) : Color.clear)
                .opacity(isLatest ? 0.24 : (active ? 0.12 : 1)),
            in: RoundedRectangle(cornerRadius: GameRadius.badge)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.badge)
                .stroke(
                    active ? GamePalette.attack(kind).opacity(isLatest ? 1 : 0.58) : Color.clear,
                    lineWidth: isLatest ? 2 : (active ? 1 : 0)
                )
        )
        .accessibilityLabel(
            charge > 0
                ? "\(kind.name) \(rankAccessibilityText), \(charge)회 충전"
                : "\(kind.name) \(rankAccessibilityText)"
        )
    }

    private var levelText: String {
        if charge > 0 { return level >= AttackItemLevels.maximumRank ? "MAX ×\(charge)" : "L\(level) ×\(charge)" }
        return level >= AttackItemLevels.maximumRank ? "MAX" : "L\(level)"
    }

    private var rankAccessibilityText: String {
        level >= AttackItemLevels.maximumRank ? "최대 레벨 3" : "레벨 \(level)"
    }
}

private struct GameplayFeedbackBar: View {
    let snapshot: RunSnapshot

    var body: some View {
        HStack(spacing: GameSpacing.small) {
            Image(systemName: snapshot.isReturnShot ? "arrow.trianglehead.2.clockwise.rotate.90" : "scope")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(snapshot.isReturnShot ? GamePalette.fireCore : GamePalette.info)
                .frame(width: 30, height: 30)
                .background(
                    (snapshot.isReturnShot ? GamePalette.fire : GamePalette.info).opacity(0.10),
                    in: RoundedRectangle(cornerRadius: GameRadius.badge)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.feedback)
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                    .lineLimit(1)
                Text("LEVEL \(snapshot.segment)  //  ARMOR +\(snapshot.stageArmor)")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundStyle(GamePalette.textMuted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, GameSpacing.medium)
        .frame(minHeight: 44)
        .background(GamePalette.surface1.opacity(0.94), in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.card)
                .stroke(GamePalette.borderSubtle)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.feedback), 레벨 \(snapshot.segment), 방어막 단계 \(snapshot.stageArmor)")
        .accessibilityIdentifier("progressionHUD")
    }
}

private struct TutorialCoachmark: View {
    var body: some View {
        HStack(spacing: GameSpacing.medium) {
            Image(systemName: "hand.draw.fill")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(GamePalette.fireCore)
                .frame(width: 34, height: 34)
                .background(GamePalette.fire.opacity(0.12), in: RoundedRectangle(cornerRadius: GameRadius.badge))
            VStack(alignment: .leading, spacing: 2) {
                Text("좌우로 끌어 반사각을 만드세요")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text("같은 속성 5-LINK → 6초 공명 폭주")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, GameSpacing.medium)
        .frame(minHeight: 50)
        .background(GamePalette.surface1.opacity(0.96), in: RoundedRectangle(cornerRadius: GameRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.card)
                .stroke(GamePalette.fire.opacity(0.64), lineWidth: 1.5)
        )
        .shadow(color: GamePalette.deep.opacity(0.38), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("좌우로 끌어 반사각을 만드세요. 같은 색, 무늬, 마크를 다섯 번 이으면 6초 공명 폭주가 시작됩니다")
    }
}

private struct PauseOverlay: View {
    let snapshot: RunSnapshot
    let resume: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Image("RS_Playfield_Background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(GamePalette.deep.opacity(0.76).ignoresSafeArea())

            VStack(spacing: GameSpacing.large) {
                Label("RUN PAUSED", systemImage: "pause.fill")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(GamePalette.fireCore)

                Text("연쇄 일시정지")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)

                HStack(spacing: GameSpacing.small) {
                    pauseMetric("SCORE", snapshot.score.formatted(), GamePalette.textPrimary)
                    pauseMetric("HEIGHT", "\(snapshot.height)m", GamePalette.info)
                    pauseMetric("COMBO", "×\(snapshot.combo)", GamePalette.fireCore)
                }

                SkillRail(snapshot: snapshot)

                Text("자동으로 재개하지 않습니다")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)

                Button("계속 파괴", action: resume)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("resumeButton")

                Button("홈으로", action: home)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(GamePalette.textSecondary)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("pauseHomeButton")
            }
            .padding(GameSpacing.xLarge)
            .frame(maxWidth: 390)
            .background(GamePalette.surface0, in: RoundedRectangle(cornerRadius: GameRadius.panel))
            .overlay(
                RoundedRectangle(cornerRadius: GameRadius.panel)
                    .stroke(GamePalette.borderStrong)
            )
            .overlay {
                Image("RS_HUD_Frame")
                    .resizable()
                    .scaledToFill()
                    .blendMode(.screen)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            }
            .clipped()
            .padding(GameSpacing.large)
        }
    }

    private func pauseMetric(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(GamePalette.textMuted)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(GamePalette.surface2, in: RoundedRectangle(cornerRadius: GameRadius.badge))
    }
}
