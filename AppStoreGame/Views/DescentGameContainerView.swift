import SpriteKit
import SwiftUI

struct DescentGameContainerView: View {
    @ObservedObject var scene: DescentGameScene
    let bestScore: Int
    let assistedBestScore: Int
    let extraLives: Int
    let canOfferReward: Bool
    let isRequestingReward: Bool
    let assistMessage: String?
    let requestRewardedRevive: () -> Void
    let useExtraLife: () -> Void
    let finalizeRun: () -> Void
    let retry: () -> Void
    let home: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            SpriteView(
                scene: scene,
                preferredFramesPerSecond: 60,
                options: [.ignoresSiblingOrder]
            )
            .ignoresSafeArea()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("디센트 브레이커 게임")
            .accessibilityHint("좌우로 끌어 자동 사격 레인을 바꾸고, 위험선 전에 오브젝트를 파괴하며 떨어지는 스킬 코어를 받습니다")
            .accessibilityValue(accessibilityValue)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .decrement: scene.movePlayerLane(by: -1)
                case .increment: scene.movePlayerLane(by: 1)
                @unknown default: break
                }
            }
            .accessibilityAction(named: "왼쪽 레인으로 이동") {
                scene.movePlayerLane(by: -1)
            }
            .accessibilityAction(named: "오른쪽 레인으로 이동") {
                scene.movePlayerLane(by: 1)
            }
            .accessibilityIdentifier("descentGameScene")
            .accessibilityHidden(scene.snapshot.awaitingChoice || scene.snapshot.awaitingRevive)

            VStack(spacing: 5) {
                DescentHUD(snapshot: scene.snapshot) {
                    scene.setRunPaused(true)
                }
                DescentFeedbackBar(snapshot: scene.snapshot, bestScore: bestScore)
                    .allowsHitTesting(false)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .accessibilityHidden(scene.snapshot.awaitingChoice || scene.snapshot.awaitingRevive)

            if scene.snapshot.awaitingChoice, scene.snapshot.phase == .playing {
                DescentChoiceArenaOverlay(
                    snapshot: scene.snapshot,
                    bestScore: bestScore,
                    choose: scene.resolveChoiceArena
                )
                .transition(.opacity)
            }

            if scene.snapshot.phase == .paused {
                DescentPauseOverlay(snapshot: scene.snapshot) {
                    scene.setRunPaused(false)
                }
                .transition(.opacity)
            }

            if scene.snapshot.awaitingRevive {
                DescentReviveOverlay(
                    snapshot: scene.snapshot,
                    extraLives: extraLives,
                    canOfferReward: canOfferReward,
                    isRequestingReward: isRequestingReward,
                    assistMessage: assistMessage,
                    requestRewardedRevive: requestRewardedRevive,
                    useExtraLife: useExtraLife,
                    finalizeRun: finalizeRun
                )
                .transition(.opacity)
            }

            if scene.snapshot.phase == .finished, !scene.snapshot.awaitingRevive {
                DescentResultOverlay(
                    snapshot: scene.snapshot,
                    bestScore: scene.snapshot.rankedClass == .clean
                        ? max(bestScore, scene.snapshot.fatalCheckpointScore ?? scene.snapshot.score)
                        : max(assistedBestScore, scene.snapshot.score),
                    retry: retry,
                    home: home
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if scene.researchPersistenceError != nil {
                DescentResearchPersistenceFailureOverlay(home: home)
                    .transition(.opacity)
            }
        }
        .task { scene.setReduceMotion(reduceMotion) }
        .onChange(of: reduceMotion) { _, enabled in
            scene.setReduceMotion(enabled)
        }
        .onChange(of: scene.researchPersistenceError) { _, error in
            if error != nil { scene.setRunPaused(true) }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: GameMotion.fast), value: scene.snapshot.phase)
        .statusBarHidden(true)
    }

    private var accessibilityValue: String {
        let ranks = DescentSkillKind.allCases
            .map { "\($0.koreanName) 레벨 \(scene.snapshot.skills.level(for: $0))" }
            .joined(separator: ", ")
        let progress = scene.snapshot.isRankedEndless
            ? "레벨 \(scene.snapshot.level), \(scene.snapshot.rankedClass == .clean ? "Clean" : "Assisted")"
            : "남은 시간 \(scene.snapshot.remainingSeconds)초"
        let threat = scene.snapshot.isRankedEndless
            ? ", 위협 레벨 \(scene.snapshot.threatTier), 적 공격체 \(scene.snapshot.enemyProjectileCount)"
            : ""
        return "\(shipName), \(progress)\(threat), \(choiceStatus), \(flowStatus), 현재 레인 \(scene.snapshot.lane)/5, 점수 \(scene.snapshot.score), CHAIN \(scene.snapshot.combo), 리액터 \(scene.snapshot.reactorHP), \(ranks)"
    }

    private var shipName: String {
        switch scene.snapshot.shipKind {
        case .interceptor: "스위프트, 단발 펄스"
        case .striker: "해머, 중형 랜스"
        case .guardian: "트라이던트, 3연장 살보"
        }
    }

    private var choiceStatus: String {
        if scene.snapshot.awaitingChoice { return "Choice Arena 선택 대기" }
        switch scene.snapshot.arenaChoice {
        case .steady: return "안정 비행 선택"
        case .redline: return "레드라인 선택, 보너스 \(scene.snapshot.redlineBonusScore)점"
        case nil: return "Choice Arena 전"
        }
    }

    private var flowStatus: String {
        if scene.snapshot.flowMode == .frenzy {
            let seconds = Double(scene.snapshot.frenzyRemainingTicks)
                / Double(GameRules.descentTickRate)
            return "BREAK FLOW, \(seconds.formatted(.number.precision(.fractionLength(1))))초 남음, 보너스 \(scene.snapshot.frenzyBonusScore)점"
        }
        return "BREAK FLOW 충전 \(scene.snapshot.frenzyCharge)/\(GameRules.descentFrenzyThreshold)"
    }
}

private struct DescentResearchPersistenceFailureOverlay: View {
    let home: () -> Void

    var body: some View {
        ZStack {
            GamePalette.deep.opacity(0.94).ignoresSafeArea()
            VStack(spacing: GameSpacing.large) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.system(size: 44, weight: .black))
                    .foregroundStyle(GamePalette.danger)
                Text("RESEARCH RUN INVALID")
                    .font(.system(.title3, design: .monospaced, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text("로컬 저장에 실패했습니다. 다음 참가자 런을 시작하지 말고 Research Console에서 DQ와 저장 용량을 확인하세요.")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)
                    .multilineTextAlignment(.center)
                Button("연구 중단") { home() }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("descentResearchPersistenceFailureHomeButton")
            }
            .padding(GameSpacing.xLarge)
            .glassCard()
            .padding(GameSpacing.large)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentResearchPersistenceFailure")
    }
}

private struct DescentChoiceArenaOverlay: View {
    let snapshot: DescentSceneSnapshot
    let bestScore: Int
    let choose: (DescentArenaChoice) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var controlsEnabled = false

    var body: some View {
        ZStack {
            GamePalette.deep.opacity(0.76).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    Text("CHOICE ARENA")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(GamePalette.warning)
                        .accessibilityIdentifier("descentChoiceHeading")

                    Text("남은 30초, 기록을 걸까요?")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(GamePalette.textPrimary)

                    Text(paceText)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(GamePalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("descentChoicePaceText")

                    choiceButton(
                        choice: .steady,
                        icon: "checkmark.shield.fill",
                        title: "안정 비행",
                        detail: "속도·점수 그대로\n생존을 이어갑니다",
                        color: GamePalette.info
                    )
                    .accessibilityIdentifier("descentChoiceSafeButton")

                    choiceButton(
                        choice: .redline,
                        icon: "bolt.fill",
                        title: "레드라인",
                        detail: "낙하 속도 +18%\n기본 미사일 직접 파괴 +35%",
                        color: GamePalette.fire
                    )
                    .accessibilityIdentifier("descentChoiceRedlineButton")

                    Text("원소 스킬·기체 성능·체력은 바뀌지 않습니다")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(GamePalette.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(18)
                .frame(maxWidth: 358)
                .background(GamePalette.surface0.opacity(0.98), in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [GamePalette.info, GamePalette.warning, GamePalette.fire],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentChoiceArena")
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            controlsEnabled = true
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: controlsEnabled)
    }

    private var paceText: String {
        guard bestScore > 0 else {
            return "현재 \(snapshot.score.formatted()) · 첫 기록을 완성하세요"
        }
        return "현재 \(snapshot.score.formatted()) · 전체 BEST \(bestScore.formatted())\n30초 페이스 비교는 연구 중"
    }

    private func choiceButton(
        choice: DescentArenaChoice,
        icon: String,
        title: String,
        detail: String,
        color: Color
    ) -> some View {
        Button {
            guard controlsEnabled else { return }
            controlsEnabled = false
            choose(choice)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(color)
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.textPrimary)
                    Text(detail)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(GamePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(color)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color.opacity(0.72), lineWidth: 1.4)
            )
            .contentShape(RoundedRectangle(cornerRadius: 15))
        }
        .buttonStyle(.plain)
        .disabled(!controlsEnabled)
        .accessibilityLabel(
            choice == .redline
                ? "레드라인, 낙하 속도 18퍼센트 증가, 기본 미사일 직접 파괴 점수 35퍼센트 증가, 원소 스킬은 변하지 않음"
                : "안정 비행, 속도와 점수 그대로 생존을 이어감"
        )
    }
}

private struct DescentReviveOverlay: View {
    let snapshot: DescentSceneSnapshot
    let extraLives: Int
    let canOfferReward: Bool
    let isRequestingReward: Bool
    let assistMessage: String?
    let requestRewardedRevive: () -> Void
    let useExtraLife: () -> Void
    let finalizeRun: () -> Void

    var body: some View {
        ZStack {
            GamePalette.deep.opacity(0.90).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    Label("CLEAN CHECKPOINT", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(GamePalette.success)

                    Text((snapshot.fatalCheckpointScore ?? snapshot.score).formatted())
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.textPrimary)
                        .monospacedDigit()
                        .accessibilityIdentifier("descentFatalCheckpointScore")

                    Text("LEVEL \(snapshot.level) · 이 Clean 기록은 이미 Top 10 후보로 봉인됐습니다")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(GamePalette.textSecondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 8) {
                        assistButton(
                            icon: "play.rectangle.fill",
                            title: isRequestingReward ? "보상 확인 중…" : "광고 보고 1회 부활",
                            detail: "테스트 보상 · 부활 후 Assisted 기록",
                            color: GamePalette.info,
                            enabled: canOfferReward && !isRequestingReward,
                            action: requestRewardedRevive
                        )
                        .accessibilityIdentifier("descentRewardedReviveButton")

                        assistButton(
                            icon: "heart.circle.fill",
                            title: "보유 목숨 사용",
                            detail: "남은 수량 \(extraLives) · 부활 후 Assisted 기록",
                            color: GamePalette.fireCore,
                            enabled: extraLives > 0 && !isRequestingReward,
                            action: useExtraLife
                        )
                        .accessibilityIdentifier("descentExtraLifeReviveButton")
                    }

                    if let assistMessage {
                        Text(assistMessage)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(GamePalette.warning)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("descentAssistMessage")
                    }

                    Button("Clean 기록으로 종료", action: finalizeRun)
                        .font(.system(.subheadline, design: .rounded, weight: .black))
                        .foregroundStyle(GamePalette.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(GamePalette.surface3, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(GamePalette.borderStrong))
                        .accessibilityHint("부활하지 않고 현재 Clean 기록으로 결과 화면을 엽니다")
                        .accessibilityIdentifier("descentFinalizeCleanRunButton")

                    Text("부활은 런당 한 번만 가능합니다. Assisted 점수는 Clean 순위에 들어가지 않습니다.")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(GamePalette.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: 350)
                .background(GamePalette.surface0, in: RoundedRectangle(cornerRadius: 22))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [GamePalette.success, GamePalette.info, GamePalette.fire],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentReviveOverlay")
    }

    private func assistButton(
        icon: String,
        title: String,
        detail: String,
        color: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(color)
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.textPrimary)
                    Text(detail)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(GamePalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(color.opacity(enabled ? 0.12 : 0.04), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(color.opacity(enabled ? 0.72 : 0.18)))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }
}

private struct DescentResultOverlay: View {
    let snapshot: DescentSceneSnapshot
    let bestScore: Int
    let retry: () -> Void
    let home: () -> Void

    var body: some View {
        ZStack {
            GamePalette.deep.opacity(0.86).ignoresSafeArea()
            VStack(spacing: 15) {
                Text(resultHeading)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(snapshot.isRankedEndless ? classColor : snapshot.reactorHP > 0 ? GamePalette.info : GamePalette.danger)

                Text(snapshot.score.formatted())
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [GamePalette.textPrimary, GamePalette.fireCore, GamePalette.fire],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("\(bestLabel)  \(bestScore.formatted())")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(GamePalette.warning)

                HStack(spacing: 8) {
                    DescentMetric(title: "MAX CHAIN", value: "\(snapshot.maxCombo)", color: GamePalette.warning)
                    DescentMetric(title: "DANGER SAVE", value: "\(snapshot.dangerSaves)", color: GamePalette.info)
                    DescentMetric(title: "SKILLS", value: "\(skillCount)", color: GamePalette.success)
                }

                Text(resultSummary)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(snapshot.arenaChoice == .redline ? GamePalette.fire : GamePalette.info)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .accessibilityIdentifier("descentChoiceResultSummary")

                Button("같은 패턴 다시", action: retry)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("descentRetryButton")

                Button("홈으로", action: home)
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textSecondary)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("descentHomeButton")
            }
            .padding(24)
            .frame(maxWidth: 350)
            .background(GamePalette.surface0, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [GamePalette.fire, GamePalette.borderStrong, GamePalette.info],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(20)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentResultOverlay")
    }

    private var skillCount: Int {
        DescentSkillKind.allCases.reduce(0) { result, kind in
            result + (snapshot.skills.level(for: kind) > 0 ? 1 : 0)
        }
    }

    private var resultHeading: String {
        if snapshot.isRankedEndless {
            return snapshot.rankedClass == .clean ? "CLEAN RUN SEALED" : "ASSISTED RUN COMPLETE"
        }
        return snapshot.reactorHP > 0 ? "60 SEC CLEARED" : "REACTOR OFFLINE"
    }

    private var bestLabel: String {
        snapshot.isRankedEndless
            ? (snapshot.rankedClass == .clean ? "CLEAN BEST" : "ASSISTED PB")
            : "BEST"
    }

    private var classColor: Color {
        snapshot.rankedClass == .clean ? GamePalette.success : GamePalette.info
    }

    private var resultSummary: String {
        if snapshot.isRankedEndless {
            let seconds = Int(snapshot.elapsedSeconds.rounded(.down))
            return "LEVEL \(snapshot.level) · \(seconds)초 · FLOW \(snapshot.frenzyActivationCount)회"
        }
        let choice = switch snapshot.arenaChoice {
        case .redline:
            "CHOICE: 레드라인  +\(snapshot.redlineBonusScore.formatted())"
        case .steady:
            "CHOICE: 안정 비행"
        case nil:
            "CHOICE: 미선택"
        }
        return "\(choice) · FLOW \(snapshot.frenzyActivationCount)회 +\(snapshot.frenzyBonusScore.formatted())"
    }
}

private struct DescentHUD: View {
    let snapshot: DescentSceneSnapshot
    let pause: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Button(action: pause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .black))
                        .frame(width: 44, height: 44)
                        .background(GamePalette.surface3, in: RoundedRectangle(cornerRadius: 9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(GamePalette.fire.opacity(0.78), lineWidth: 1.5)
                        )
                }
                .foregroundStyle(GamePalette.textPrimary)
                .accessibilityLabel("일시정지")
                .accessibilityIdentifier("descentPauseButton")

                DescentMetric(title: "SCORE", value: snapshot.score.formatted(), color: GamePalette.textPrimary)
                    .frame(maxWidth: .infinity)
                DescentChainMetric(snapshot: snapshot)
                    .frame(width: 70)
                DescentMetric(
                    title: snapshot.isRankedEndless ? "LEVEL" : "TIME",
                    value: snapshot.isRankedEndless
                        ? "\(snapshot.level)"
                        : String(format: "0:%02d", snapshot.remainingSeconds),
                    color: snapshot.isRankedEndless ? classColor : timeColor
                )
                    .frame(width: 54)
                    .accessibilityIdentifier(snapshot.isRankedEndless ? "descentLevelHUD" : "descentTimeHUD")

                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .black))
                    Text("\(snapshot.reactorHP)")
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .monospacedDigit()
                }
                .foregroundStyle(snapshot.reactorHP <= 1 ? GamePalette.danger : GamePalette.fireCore)
                .frame(width: 40, height: 40)
                .background(GamePalette.surface2, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("리액터 체력 \(snapshot.reactorHP)")
            }

            DescentSkillRail(snapshot: snapshot)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(GamePalette.surface0.opacity(0.95), in: RoundedRectangle(cornerRadius: 13))
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(
                    LinearGradient(
                        colors: [GamePalette.fire, GamePalette.borderStrong, GamePalette.info],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.4
                )
        )
        .shadow(color: GamePalette.deep.opacity(0.72), radius: 8, y: 3)
    }

    private var timeColor: Color {
        snapshot.remainingSeconds <= 10 ? GamePalette.danger : GamePalette.info
    }

    private var classColor: Color {
        snapshot.rankedClass == .clean ? GamePalette.success : GamePalette.info
    }
}

private struct DescentChainMetric: View {
    let snapshot: DescentSceneSnapshot
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 1) {
            Text("CHAIN")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(GamePalette.textMuted)
            Text("\(snapshot.combo)")
                .font(.system(size: chainFontSize, weight: .black, design: .rounded))
                .foregroundStyle(chainColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
            DescentFlowMeter(snapshot: snapshot)
                .frame(height: 6)
        }
        .frame(minHeight: 40)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("descentChainHUD")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: snapshot.combo)
    }

    private var chainColor: Color {
        if snapshot.combo >= 20 { return GamePalette.fire }
        if snapshot.combo >= 10 { return GamePalette.warning }
        if snapshot.combo >= 5 { return GamePalette.fireCore }
        return GamePalette.textPrimary
    }

    private var chainFontSize: CGFloat {
        if snapshot.combo >= 20 { return 20 }
        if snapshot.combo >= 10 { return 19 }
        if snapshot.combo >= 5 { return 18 }
        return 17
    }

    private var accessibilityLabel: String {
        if snapshot.flowMode == .frenzy {
            let seconds = Double(snapshot.frenzyRemainingTicks)
                / Double(GameRules.descentTickRate)
            return "CHAIN \(snapshot.combo), BREAK FLOW, \(seconds.formatted(.number.precision(.fractionLength(1))))초 남음"
        }
        return "CHAIN \(snapshot.combo), BREAK FLOW 충전 \(snapshot.frenzyCharge)/\(GameRules.descentFrenzyThreshold)"
    }
}

private struct DescentFlowMeter: View {
    let snapshot: DescentSceneSnapshot

    var body: some View {
        Group {
            if snapshot.flowMode == .frenzy {
                GeometryReader { proxy in
                    let progress = min(
                        1,
                        max(
                            0,
                            Double(snapshot.frenzyRemainingTicks)
                                / Double(GameRules.descentFrenzyDurationTicks)
                        )
                    )
                    ZStack(alignment: .leading) {
                        Capsule().fill(GamePalette.surface3)
                        Capsule()
                            .fill(GamePalette.warning)
                            .frame(width: proxy.size.width * progress)
                            .overlay {
                                DescentFlowHatch()
                                    .clipShape(Capsule())
                            }
                    }
                    .overlay(Capsule().stroke(GamePalette.textPrimary.opacity(0.48), lineWidth: 0.7))
                }
            } else {
                HStack(spacing: 2) {
                    ForEach(0..<GameRules.descentFrenzyThreshold, id: \.self) { index in
                        let active = index < snapshot.frenzyCharge
                        Capsule()
                            .fill(active ? GamePalette.fireCore : GamePalette.surface3)
                            .overlay(
                                Capsule().stroke(
                                    active ? GamePalette.textPrimary.opacity(0.52) : GamePalette.border,
                                    lineWidth: 0.6
                                )
                            )
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DescentFlowHatch: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                var x: CGFloat = -4
                while x < proxy.size.width + 4 {
                    path.move(to: CGPoint(x: x, y: proxy.size.height))
                    path.addLine(to: CGPoint(x: x + 5, y: 0))
                    x += 7
                }
            }
            .stroke(GamePalette.deep.opacity(0.64), lineWidth: 1)
        }
    }
}

private struct DescentMetric: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(GamePalette.textMuted)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.58)
        }
        .frame(minHeight: 38)
    }
}

private struct DescentSkillRail: View {
    let snapshot: DescentSceneSnapshot

    var body: some View {
        HStack(spacing: 4) {
            ForEach(DescentSkillKind.allCases, id: \.self) { kind in
                let level = snapshot.skills.level(for: kind)
                HStack(spacing: 3) {
                    Image(systemName: kind.systemImage)
                        .font(.system(size: 10, weight: .black))
                    Text(level >= DescentSkillLevels.maximumRank ? "MAX" : "L\(level)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .monospacedDigit()
                }
                .foregroundStyle(level > 0 ? kind.color : GamePalette.textMuted)
                .frame(maxWidth: .infinity, minHeight: 24)
                .background(
                    kind.color.opacity(level > 0 ? (snapshot.lastCollectedSkill == kind ? 0.24 : 0.11) : 0.025),
                    in: RoundedRectangle(cornerRadius: 7)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(kind.color.opacity(level > 0 ? 0.66 : 0.12), lineWidth: snapshot.lastCollectedSkill == kind ? 1.5 : 0.7)
                )
                .accessibilityLabel("\(kind.koreanName) 레벨 \(level)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentSkillHUD")
    }
}

private struct DescentFeedbackBar: View {
    let snapshot: DescentSceneSnapshot
    let bestScore: Int

    var body: some View {
        HStack(spacing: 7) {
            if snapshot.isRankedEndless {
                Text(snapshot.rankedClass == .clean ? "CLEAN" : "ASSISTED")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(snapshot.rankedClass == .clean ? GamePalette.success : GamePalette.info)
                    .padding(.horizontal, 5)
                    .frame(height: 16)
                    .background(
                        (snapshot.rankedClass == .clean ? GamePalette.success : GamePalette.info).opacity(0.12),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().stroke(
                            (snapshot.rankedClass == .clean ? GamePalette.success : GamePalette.info).opacity(0.62)
                        )
                    )
                    .accessibilityIdentifier("descentRankedClassBadge")
                Text("T\(snapshot.threatTier)")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundStyle(snapshot.threatTier >= 3 ? GamePalette.danger : GamePalette.warning)
                    .padding(.horizontal, 5)
                    .frame(height: 16)
                    .background(GamePalette.surface0, in: Capsule())
                    .overlay(Capsule().stroke(GamePalette.warning.opacity(0.58)))
                    .accessibilityLabel("위협 레벨 \(snapshot.threatTier)")
                    .accessibilityIdentifier("descentThreatTierBadge")
            }
            Image(systemName: feedbackIcon)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(feedbackColor)
            Text(feedbackText)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(GamePalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 2)
            Text("LANE \(snapshot.lane)/5")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(GamePalette.info)
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .frame(height: 24)
        .background(GamePalette.surface1.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(feedbackColor.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feedbackText), 현재 레인 \(snapshot.lane)/5")
    }

    private var feedbackText: String {
        if snapshot.flowMode == .frenzy {
            let seconds = Double(snapshot.frenzyRemainingTicks)
                / Double(GameRules.descentTickRate)
            return "BREAK FLOW · \(seconds.formatted(.number.precision(.fractionLength(1))))초 · +\(snapshot.frenzyBonusScore.formatted())"
        }
        if snapshot.isRankedEndless {
            let gap = max(0, bestScore - snapshot.score)
            return bestScore > 0
                ? "PB까지 \(gap.formatted())점 · LEVEL \(snapshot.level)"
                : "첫 Clean 기록 도전 · LEVEL \(snapshot.level)"
        }
        guard snapshot.arenaChoice == .redline,
              !snapshot.feedback.hasPrefix("DANGER"),
              !snapshot.feedback.contains("활성") else {
            return snapshot.feedback
        }
        let gap = max(0, bestScore - snapshot.score)
        return bestScore > 0
            ? "PB까지 \(gap.formatted())점 · REDLINE +35%"
            : "REDLINE +35% · 첫 기록 도전"
    }

    private var feedbackIcon: String {
        if snapshot.flowMode == .frenzy { return "bolt.horizontal.circle.fill" }
        return snapshot.feedback.contains("DANGER")
            ? "exclamationmark.triangle.fill"
            : "scope"
    }

    private var feedbackColor: Color {
        if snapshot.flowMode == .frenzy { return GamePalette.warning }
        return snapshot.feedback.contains("DANGER")
            ? GamePalette.danger
            : GamePalette.info
    }
}

private struct DescentPauseOverlay: View {
    let snapshot: DescentSceneSnapshot
    let resume: () -> Void

    var body: some View {
        ZStack {
            GamePalette.deep.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 14) {
                Label("RUN PAUSED", systemImage: "pause.fill")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.4)
                    .foregroundStyle(GamePalette.fireCore)
                Text("낙하 작전 정지")
                    .font(.system(.title, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                HStack(spacing: 8) {
                    DescentMetric(title: "SCORE", value: snapshot.score.formatted(), color: GamePalette.textPrimary)
                    DescentMetric(title: "MAX CHAIN", value: "\(snapshot.maxCombo)", color: GamePalette.warning)
                    DescentMetric(title: "SAVES", value: "\(snapshot.dangerSaves)", color: GamePalette.info)
                }
                Button("계속 파괴", action: resume)
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityIdentifier("descentResumeButton")
            }
            .padding(22)
            .frame(maxWidth: 350)
            .background(GamePalette.surface0, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [GamePalette.fire, GamePalette.borderStrong, GamePalette.info],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .padding(20)
        }
    }
}

private extension DescentSkillKind {
    var koreanName: String {
        switch self {
        case .fire: "화염"
        case .electric: "전기"
        case .pierce: "관통"
        case .wind: "바람"
        case .explosion: "폭발"
        }
    }

    var systemImage: String {
        switch self {
        case .fire: "flame.fill"
        case .electric: "bolt.fill"
        case .pierce: "arrow.up"
        case .wind: "wind"
        case .explosion: "burst.fill"
        }
    }

    var color: Color {
        switch self {
        case .fire: GamePalette.fire
        case .electric: GamePalette.electric
        case .pierce: GamePalette.success
        case .wind: GamePalette.info
        case .explosion: GamePalette.warning
        }
    }
}
