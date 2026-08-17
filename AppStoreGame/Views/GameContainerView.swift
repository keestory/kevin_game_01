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

            VStack(spacing: 0) {
                GameHUD(
                    snapshot: model.snapshot,
                    variant: model.visualVariant,
                    pause: model.pause
                )

                if model.showTutorial {
                    TutorialCoachmark(variant: model.visualVariant)
                        .allowsHitTesting(false)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .padding(.top, 8)
                } else {
                    GameplayFeedbackPill(
                        snapshot: model.snapshot,
                        variant: model.visualVariant
                    )
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .padding(.top, 8)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 54)

            if model.snapshot.phase == .paused {
                PauseOverlay(
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
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.showTutorial)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: model.snapshot.phase)
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
        return "점수 \(model.snapshot.score), 높이 \(model.snapshot.height)미터, 콤보 \(model.snapshot.combo), \(model.snapshot.link.leadingText), \(skills), 방어막 단계 \(model.snapshot.stageArmor)\(pierce)\(power)"
    }
}

private struct GameHUD: View {
    let snapshot: RunSnapshot
    let variant: VisualVariant
    let pause: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("SCORE")
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white.opacity(0.64))
                    Text(snapshot.score.formatted())
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                compactStat(label: "높이", value: "\(snapshot.height)m", color: .exitMint)
                compactStat(label: "콤보", value: "×\(snapshot.combo)", color: .safetyYellow)

                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 15, weight: .black))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18)))
                }
                .foregroundStyle(.white)
                .accessibilityLabel("일시정지")
                .accessibilityIdentifier("pauseButton")
            }

            HStack(spacing: 8) {
                Image(systemName: leadingIcon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(leadingColor)
                Text(snapshot.link.leadingText)
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .lineLimit(1)

                HStack(spacing: 3) {
                    ForEach(0..<5, id: \.self) { index in
                        Capsule()
                            .fill(index < min(5, snapshot.link.highestCount) ? leadingColor : Color.white.opacity(0.16))
                            .frame(width: 12, height: 6)
                    }
                }

                Spacer(minLength: 4)

                Text(recordPaceText)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(recordPaceColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if snapshot.powerSeconds > 0 {
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(LinearGradient(colors: [.safetyYellow, .alertCoral], startPoint: .leading, endPoint: .trailing))
                                .frame(width: proxy.size.width * max(0, min(1, snapshot.powerProgress)))
                        }
                }
                .frame(height: 4)
                .accessibilityLabel("공명 폭주 남은 시간 \(snapshot.powerSeconds.formatted(.number.precision(.fractionLength(1))))초")
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 10)
        .background(hudBackground, in: RoundedRectangle(cornerRadius: variant == .impactPop ? 16 : 20))
        .overlay {
            RoundedRectangle(cornerRadius: variant == .impactPop ? 16 : 20)
                .stroke(variant == .impactPop ? Color.safetyYellow.opacity(0.24) : Color.white.opacity(0.14))
        }
        .shadow(color: .black.opacity(0.34), radius: 12, y: 5)
    }

    private var hudBackground: some ShapeStyle {
        LinearGradient(
            colors: variant == .impactPop
                ? [Color(hex: 0x16243C).opacity(0.96), Color(hex: 0x291D37).opacity(0.96)]
                : [Color(hex: 0x0B172A).opacity(0.94), Color(hex: 0x12243B).opacity(0.94)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var leadingIcon: String {
        if snapshot.link.colorCount >= snapshot.link.patternCount,
           snapshot.link.colorCount >= snapshot.link.markCount { return "paintpalette.fill" }
        if snapshot.link.patternCount >= snapshot.link.markCount { return "line.3.horizontal" }
        return "star.fill"
    }

    private var leadingColor: Color {
        snapshot.powerSeconds > 0 ? .safetyYellow : .exitMint
    }

    private var recordPaceText: String {
        guard snapshot.bestScore > 0 else { return "첫 기록 중" }
        let delta = snapshot.score - snapshot.bestScore
        return delta >= 0 ? "PB +\(delta.formatted())점" : "PB까지 \((-delta).formatted())점"
    }

    private var recordPaceColor: Color {
        snapshot.bestScore > 0 && snapshot.score >= snapshot.bestScore
            ? .safetyYellow
            : .white.opacity(0.62)
    }

    private func compactStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(minWidth: 48)
    }
}

private struct GameplayFeedbackPill: View {
    let snapshot: RunSnapshot
    let variant: VisualVariant

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: snapshot.isReturnShot ? "arrow.trianglehead.2.clockwise.rotate.90" : "scope")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(snapshot.isReturnShot ? Color.safetyYellow : Color.exitMint)
            VStack(alignment: .leading, spacing: 1) {
                Text(snapshot.feedback)
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text("구조 \(snapshot.segment)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.58))

                    ForEach(AttackItemKind.allCases, id: \.self) { kind in
                        if snapshot.attackItemLevels.level(for: kind) > 0 {
                            SkillCoreChip(
                                kind: kind,
                                level: snapshot.attackItemLevels.level(for: kind),
                                charge: kind == .pierce ? snapshot.pierceCharges : 0,
                                isLatest: snapshot.lastCollectedItem == kind
                            )
                        }
                    }

                    Spacer(minLength: 2)

                    if snapshot.stageArmor > 0 {
                        Label("+\(snapshot.stageArmor)", systemImage: "shield.lefthalf.filled")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: 0xA9E7FF))
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 50)
        .background(Color(hex: variant == .impactPop ? 0x241B31 : 0x0C192C).opacity(0.93), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.14)))
        .shadow(color: .black.opacity(0.28), radius: 8, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(snapshot.feedback), 구조 \(snapshot.segment), 스킬 코어 상태")
        .accessibilityIdentifier("skillCoreHUD")
    }
}

private struct SkillCoreChip: View {
    let kind: AttackItemKind
    let level: Int
    let charge: Int
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 10, weight: .black))
            Text(charge > 0 ? "L\(level) ×\(charge)" : "L\(level)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(Color(hex: kind.tintHex))
        .padding(.horizontal, 4)
        .frame(minHeight: 20)
        .background(
            (isLatest ? Color(hex: kind.tintHex) : Color.white)
                .opacity(isLatest ? 0.16 : 0.06),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(
                    Color(hex: kind.tintHex).opacity(isLatest ? 0.72 : 0.28),
                    lineWidth: 0.8
                )
        )
        .accessibilityLabel(
            charge > 0
                ? "\(kind.name) 레벨 \(level), \(charge)회 충전"
                : "\(kind.name) 레벨 \(level)"
        )
    }
}

private struct TutorialCoachmark: View {
    let variant: VisualVariant

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.draw.fill")
                .font(.system(size: 21, weight: .black))
                .foregroundStyle(Color.safetyYellow)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("좌우로 끌어 반사각을 만드세요")
                    .font(.system(.caption, design: .rounded, weight: .black))
                Text("같은 색·무늬·마크 5연속 → 6초 폭주")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 52)
        .background(Color(hex: variant == .impactPop ? 0x2B1D36 : 0x0B192D).opacity(0.96), in: RoundedRectangle(cornerRadius: 17))
        .overlay(RoundedRectangle(cornerRadius: 17).stroke(Color.safetyYellow.opacity(0.50), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.34), radius: 10, y: 4)
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("좌우로 끌어 반사각을 만드세요. 같은 색, 무늬, 마크를 다섯 번 이으면 6초 공명 폭주가 시작됩니다")
    }
}

private struct PauseOverlay: View {
    let resume: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            Color(hex: 0x071225).opacity(0.94).ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.safetyYellow)
                Text("연쇄 일시정지")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                Text("자동으로 재개하지 않아요")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.68))
                Button("계속 파괴", action: resume)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("resumeButton")
                Button("홈으로", action: home)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("pauseHomeButton")
            }
            .padding(28)
        }
    }
}
