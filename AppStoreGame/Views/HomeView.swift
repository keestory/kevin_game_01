import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AppModel
    @State private var showsDescentShipSelection = false
    @State private var showsDescentRankings = false

    var body: some View {
        ZStack {
            homeBackdrop

            ScrollView(showsIndicators: false) {
                VStack(spacing: GameSpacing.large) {
                    header
                    hero
                    DescentModeCard(
                        bestScore: model.descentCleanBestScore,
                        assistedBestScore: model.descentAssistedBestScore,
                        selectedShip: model.selectedDescentShip,
                        showRankings: { showsDescentRankings = true }
                    ) {
                        showsDescentShipSelection = true
                    }

                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(GamePalette.borderSubtle)
                            .frame(height: 1)
                        Text("A/B BASELINE · RETURN SHOT")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(GamePalette.textMuted)
                            .fixedSize()
                        Rectangle()
                            .fill(GamePalette.borderSubtle)
                            .frame(height: 1)
                    }
                    ReturnShotPreview()
                    recordPanel
                    rulePanel

                    if model.profile.bestScore > 0 {
                        ShareLink(
                            item: "연쇄파괴: 리턴 샷 내 기록은 \(model.profile.bestScore)점 · \(model.profile.bestHeight)m!"
                        ) {
                            Label("기록 공유", systemImage: "square.and.arrow.up")
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(GamePalette.textSecondary)
                                .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("shareRecordButton")
                    }
                }
                .padding(.horizontal, GameSpacing.large)
                .padding(.top, GameSpacing.small)
                .padding(.bottom, GameSpacing.section)
            }
        }
        .sheet(isPresented: $model.showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsDescentRankings) {
            DescentRankingsSheet(
                records: model.descentCleanTop10,
                assistedBestScore: model.descentAssistedBestScore
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showsDescentShipSelection) {
            DescentShipSelectionView(
                selectedShip: model.selectedDescentShip,
                selectedBooster: model.selectedDescentBooster,
                extraLives: model.descentExtraLives,
                select: model.selectDescentShip,
                selectBooster: model.selectDescentBooster,
                close: { showsDescentShipSelection = false },
                confirm: {
                    showsDescentShipSelection = false
                    Task { @MainActor in
                        await Task.yield()
                        model.startDescent()
                    }
                }
            )
        }
    }

    private var homeBackdrop: some View {
        ZStack {
            GamePalette.canvas.ignoresSafeArea()
            GeometryReader { proxy in
                Image("RS_Playfield_Background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.58)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            LinearGradient(
                colors: [
                    GamePalette.deep.opacity(0.22),
                    GamePalette.canvas.opacity(0.72),
                    GamePalette.deep.opacity(0.98)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [GamePalette.fire.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: GameSpacing.small) {
            Label("RANKED ENDLESS // FALLING OBJECT ACTION", systemImage: "circle.hexagongrid.fill")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(GamePalette.info)

            Spacer()

            Button {
                model.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(GamePalette.surface2, in: RoundedRectangle(cornerRadius: GameRadius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: GameRadius.button)
                            .stroke(GamePalette.border)
                    )
            }
            .foregroundStyle(GamePalette.textPrimary)
            .accessibilityLabel("설정")
            .accessibilityIdentifier("settingsButton")
        }
    }

    private var hero: some View {
        VStack(spacing: GameSpacing.xSmall) {
            Text("낙하 파괴")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(GamePalette.textSecondary)

            ZStack {
                Text("DESCENT BREAKER")
                    .foregroundStyle(GamePalette.deep)
                    .offset(x: 3, y: 5)

                Text("DESCENT BREAKER")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                GamePalette.textPrimary,
                                GamePalette.textPrimary,
                                GamePalette.fireCore,
                                GamePalette.fire
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(GamePalette.fire)
                            .frame(height: 2)
                            .padding(.horizontal, 8)
                    }
            }
            .font(.system(size: 40, weight: .black, design: .rounded))
            .italic()
            .tracking(-2.4)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(maxWidth: .infinity, minHeight: 68)
            .shadow(color: GamePalette.fire.opacity(0.42), radius: 10, y: 5)
            .accessibilityLabel("DESCENT BREAKER")

            Text("위에서 내려오는 오브젝트를 부수고 드롭을 받아 공격을 강화하세요")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(GamePalette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, GameSpacing.xSmall)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("homeHero")
    }

    private var recordPanel: some View {
        VStack(spacing: GameSpacing.medium) {
            HStack(spacing: GameSpacing.small) {
                homeStat(
                    title: "BEST SCORE",
                    value: model.profile.bestScore.formatted(),
                    color: GamePalette.textPrimary
                )
                homeStat(
                    title: "BEST HEIGHT",
                    value: "\(model.profile.bestHeight)m",
                    color: GamePalette.info
                )
                homeStat(
                    title: "MAX COMBO",
                    value: "×\(model.profile.bestCombo)",
                    color: GamePalette.fireCore
                )
            }

            Button(model.profile.bestScore == 0 ? "첫 기록 시작" : "최고 기록 도전") {
                model.startGame()
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("startGameButton")
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
                .opacity(0.72)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private var rulePanel: some View {
        VStack(alignment: .leading, spacing: GameSpacing.medium) {
            HStack {
                Text("BUILD RESONANCE")
                    .font(.system(.caption, design: .rounded, weight: .black))
                    .tracking(1.2)
                    .foregroundStyle(GamePalette.textMuted)
                Spacer()
                Text("60 SEC RUN")
                    .font(.system(.caption2, design: .monospaced, weight: .black))
                    .foregroundStyle(GamePalette.warning)
            }

            rule(icon: "link", color: GamePalette.info, title: "5-LINK", body: "같은 색·무늬·마크를 잇고 6초 공명 폭주")
            rule(icon: "wand.and.stars", color: GamePalette.arcane, title: "스킬 코어", body: "직접 깨서 번개·화염·바람·관통을 LV3까지 강화")
            rule(icon: "diamond.fill", color: GamePalette.warning, title: "프리즘", body: "다중 타격 보너스와 지지 구조 붕괴를 노리기")
            rule(icon: "exclamationmark.triangle.fill", color: GamePalette.danger, title: "마이너스", body: "직접 타격은 −250, 지지점을 끊어 떨어뜨리면 +120")
        }
        .padding(GameSpacing.large)
        .background(GamePalette.surface0.opacity(0.92), in: RoundedRectangle(cornerRadius: GameRadius.panel))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.panel)
                .stroke(GamePalette.borderSubtle)
        )
    }

    private func homeStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(GamePalette.textMuted)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.64)
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(GamePalette.surface2.opacity(0.64), in: RoundedRectangle(cornerRadius: GameRadius.card))
    }

    private func rule(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(spacing: GameSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: GameRadius.badge))
                .overlay(
                    RoundedRectangle(cornerRadius: GameRadius.badge)
                        .stroke(color.opacity(0.42))
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text(body)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(GamePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct DescentShipSelectionView: View {
    let selectedShip: DescentShipKind
    let selectedBooster: DescentEndlessBoosterKind?
    let extraLives: Int
    let select: (DescentShipKind) -> Void
    let selectBooster: (DescentEndlessBoosterKind?) -> Void
    let close: () -> Void
    let confirm: () -> Void

    @State private var draftShip: DescentShipKind
    @State private var draftBooster: DescentEndlessBoosterKind?

    init(
        selectedShip: DescentShipKind,
        selectedBooster: DescentEndlessBoosterKind?,
        extraLives: Int,
        select: @escaping (DescentShipKind) -> Void,
        selectBooster: @escaping (DescentEndlessBoosterKind?) -> Void,
        close: @escaping () -> Void,
        confirm: @escaping () -> Void
    ) {
        self.selectedShip = selectedShip
        self.selectedBooster = selectedBooster
        self.extraLives = extraLives
        self.select = select
        self.selectBooster = selectBooster
        self.close = close
        self.confirm = confirm
        _draftShip = State(initialValue: selectedShip)
        _draftBooster = State(initialValue: selectedBooster)
    }

    var body: some View {
        ZStack {
            GamePalette.canvas.ignoresSafeArea()

            LinearGradient(
                colors: [
                    draftShip.accent.opacity(0.18),
                    GamePalette.canvas.opacity(0.70),
                    GamePalette.deep
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PRE-FLIGHT // LOADOUT")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .tracking(1.2)
                                .foregroundStyle(GamePalette.info)
                            Text("출격 기체 선택")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(GamePalette.textPrimary)
                        }
                        Spacer()
                        Button(action: close) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .black))
                                .frame(width: 44, height: 44)
                                .background(GamePalette.surface2, in: Circle())
                                .overlay(Circle().stroke(GamePalette.border))
                        }
                        .foregroundStyle(GamePalette.textPrimary)
                        .accessibilityLabel("기체 선택 닫기")
                        .accessibilityIdentifier("descentShipSelectionCloseButton")
                    }

                    Text("같은 속성 아이템을 사용하지만 기본 미사일의 리듬과 범위가 달라집니다")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(GamePalette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    GeometryReader { proxy in
                        HStack(spacing: 8) {
                            ForEach(DescentShipKind.allCases, id: \.self) { ship in
                                DescentShipOptionCard(
                                    ship: ship,
                                    selected: ship == draftShip
                                ) {
                                    draftShip = ship
                                    select(ship)
                                }
                                .frame(width: max(0, (proxy.size.width - 16) / 3))
                            }
                        }
                    }
                    .frame(height: 126)

                    selectedDetail

                    boosterSelection

                    Button("\(draftShip.shortName)로 출격", action: confirm)
                        .buttonStyle(PrimaryButtonStyle())
                        .frame(minHeight: 56)
                        .accessibilityHint("선택한 기체와 미사일로 낙하 파괴를 시작합니다")
                        .accessibilityIdentifier("descentShipConfirmButton")
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentShipSelection")
    }

    private var selectedDetail: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(GamePalette.surface0)
                DescentAtlasCell(
                    asset: "DB_PlayerAttacks",
                    crop: DescentArtCatalog.shipCrop(for: draftShip)
                )
                .padding(5)
            }
            .frame(width: 96, height: 82)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(draftShip.accent.opacity(0.72), lineWidth: 1.5)
            )
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(draftShip.displayName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.textPrimary)
                    Spacer()
                    Text("선택됨")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(draftShip.accent)
                }
                Text(draftShip.roleName)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(draftShip.accent)
                Text(draftShip.detailSummary)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(GamePalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 4) {
                    ForEach(Array(draftShip.statGrades.enumerated()), id: \.offset) { _, stat in
                        Text("\(stat.label) L\(stat.level)")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(stat.level == 3 ? draftShip.accent : GamePalette.textSecondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .background(GamePalette.surface0, in: Capsule())
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(draftShip.statAccessibilitySummary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 104)
        .background(GamePalette.surface1.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(draftShip.accent.opacity(0.52))
        )
    }

    private var boosterSelection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RANK CLASS")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(GamePalette.textMuted)
                    Text(draftBooster == nil ? "CLEAN 출격" : "ASSISTED 출격")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(draftBooster == nil ? GamePalette.success : GamePalette.info)
                }
                Spacer()
                Label("목숨 \(extraLives)", systemImage: "heart.fill")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(GamePalette.fireCore)
            }

            HStack(spacing: 7) {
                boosterButton(
                    title: "부스터 없음",
                    detail: "Clean 순위",
                    icon: "checkmark.shield.fill",
                    selected: draftBooster == nil,
                    color: GamePalette.success
                ) {
                    draftBooster = nil
                    selectBooster(nil)
                }
                .accessibilityIdentifier("descentBoosterCleanButton")
                boosterButton(
                    title: "전기 코어 L1",
                    detail: "Assisted",
                    icon: "bolt.fill",
                    selected: draftBooster == .startingCore(.electric),
                    color: GamePalette.electric
                ) {
                    let booster = DescentEndlessBoosterKind.startingCore(.electric)
                    draftBooster = booster
                    selectBooster(booster)
                }
                .accessibilityIdentifier("descentBoosterElectricButton")
                boosterButton(
                    title: "리액터 +1",
                    detail: "Assisted",
                    icon: "shield.lefthalf.filled",
                    selected: draftBooster == .reactorGuard,
                    color: GamePalette.info
                ) {
                    let booster = DescentEndlessBoosterKind.reactorGuard
                    draftBooster = booster
                    selectBooster(booster)
                }
                .accessibilityIdentifier("descentBoosterReactorButton")
            }

            Text("부스터·부활을 사용한 점수는 Clean Top 10에 들어가지 않습니다")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(GamePalette.textMuted)
        }
        .padding(12)
        .background(GamePalette.surface1.opacity(0.96), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(GamePalette.borderSubtle))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentBoosterSelection")
    }

    private func boosterButton(
        title: String,
        detail: String,
        icon: String,
        selected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .black))
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                Text(detail)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(selected ? color : GamePalette.textMuted)
            }
            .foregroundStyle(selected ? color : GamePalette.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 66)
            .background(color.opacity(selected ? 0.13 : 0.03), in: RoundedRectangle(cornerRadius: 11))
            .overlay(RoundedRectangle(cornerRadius: 11).stroke(selected ? color : GamePalette.borderSubtle))
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
    }
}

private struct DescentShipOptionCard: View {
    let ship: DescentShipKind
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack(alignment: .topTrailing) {
                    DescentAtlasCell(
                        asset: "DB_PlayerAttacks",
                        crop: DescentArtCatalog.shipCrop(for: ship)
                    )
                    .frame(height: 68)

                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(selected ? ship.accent : GamePalette.textMuted)
                        .background(GamePalette.deep.opacity(0.72), in: Circle())
                }

                Text(ship.shortName)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(GamePalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(ship.weaponSummary)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(selected ? ship.accent : GamePalette.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(7)
            .frame(maxWidth: .infinity, minHeight: 126)
            .background(
                selected ? ship.accent.opacity(0.12) : GamePalette.surface1,
                in: RoundedRectangle(cornerRadius: 14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? ship.accent : GamePalette.borderSubtle, lineWidth: selected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .accessibilityElement(children: .ignore)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 126, maxHeight: 126)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityLabel("\(ship.displayName), \(ship.roleName), \(ship.weaponSummary), \(ship.detailSummary), \(ship.statAccessibilitySummary)")
        .accessibilityValue(selected ? "선택됨" : "선택 안 됨")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(ship.accessibilityIdentifier)
    }
}

private struct DescentRankingsSheet: View {
    let records: [DescentCleanRankRecord]
    let assistedBestScore: Int

    var body: some View {
        ZStack {
            GamePalette.canvas.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Label("LOCAL CLEAN TOP 10", systemImage: "trophy.fill")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.warning)

                    Text("현재 기기의 검증된 Clean 기록입니다. 공개 세계 랭킹은 서버 검증 전까지 제공하지 않습니다.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(GamePalette.textSecondary)

                    if records.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "scope")
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(GamePalette.info)
                            Text("첫 Clean 기록을 만들어 보세요")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(GamePalette.textPrimary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(GamePalette.surface1, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            HStack(spacing: 10) {
                                Text("#\(index + 1)")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundStyle(index == 0 ? GamePalette.warning : GamePalette.textMuted)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.score.formatted())
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                        .foregroundStyle(GamePalette.textPrimary)
                                        .monospacedDigit()
                                    Text("LEVEL \(record.level) · MAX CHAIN \(record.maxCombo)")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(GamePalette.textSecondary)
                                }
                                Spacer()
                                Text(record.shipKind.shortName)
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(record.shipKind.accent)
                            }
                            .padding(12)
                            .background(GamePalette.surface1, in: RoundedRectangle(cornerRadius: 13))
                            .overlay(RoundedRectangle(cornerRadius: 13).stroke(GamePalette.borderSubtle))
                        }
                    }

                    HStack {
                        Text("ASSISTED PB")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(GamePalette.info)
                        Spacer()
                        Text(assistedBestScore.formatted())
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(GamePalette.textPrimary)
                            .monospacedDigit()
                    }
                    .padding(14)
                    .background(GamePalette.info.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(GamePalette.info.opacity(0.45)))
                }
                .padding(20)
            }
        }
        .accessibilityIdentifier("descentRankingsSheet")
    }
}

private struct DescentModeCard: View {
    let bestScore: Int
    let assistedBestScore: Int
    let selectedShip: DescentShipKind
    let showRankings: () -> Void
    let start: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RANKED ENDLESS")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(GamePalette.warning)
                    Text("DESCENT BREAKER")
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .italic()
                        .foregroundStyle(GamePalette.textPrimary)
                    Text("끊김 없이 내려오는 오브젝트를 파괴하고\n레벨·콤보·5속성으로 최고 기록에 도전")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(GamePalette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("CLEAN BEST")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(GamePalette.textMuted)
                    Text(bestScore.formatted())
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.fireCore)
                        .monospacedDigit()
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(GamePalette.deep.opacity(0.90))
                HStack(spacing: 7) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            DescentAtlasCell(asset: "DB_Objects", crop: DescentArtCatalog.objectCrop(for: .normal))
                            DescentAtlasCell(asset: "DB_Objects", crop: DescentArtCatalog.objectCrop(for: .armored))
                            DescentAtlasCell(asset: "DB_Objects", crop: DescentArtCatalog.objectCrop(for: .spike))
                        }
                        .frame(height: 58)
                        Image(systemName: "arrow.down")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(GamePalette.danger)
                            DescentAtlasCell(
                                asset: "DB_PlayerAttacks",
                                crop: DescentArtCatalog.shipCrop(for: selectedShip)
                            )
                            .frame(width: 54, height: 54)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 5) {
                        Text("DROP → POWER")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(GamePalette.textMuted)
                        HStack(spacing: 2) {
                            ForEach(Array(DescentSkillKind.allCases.prefix(4)), id: \.self) { kind in
                                DescentAtlasCell(asset: "DB_SkillItems", crop: DescentArtCatalog.skillCrop(for: kind))
                            }
                        }
                        .frame(height: 30)
                        HStack(spacing: 5) {
                            DescentAtlasCell(asset: "DB_SkillItems", crop: DescentArtCatalog.skillCrop(for: .explosion))
                                .frame(width: 32, height: 32)
                            Text("L0 → L3")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundStyle(GamePalette.warning)
                        }
                        Text("위험선 vs 아이템 경로")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(GamePalette.info)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(8)
            }
            .frame(height: 142)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(GamePalette.borderSubtle)
            )
            .accessibilityHidden(true)

            HStack {
                Label(selectedShip.shortName, systemImage: "airplane")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(GamePalette.info)
                Spacer()
                Text(selectedShip.weaponSummary)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(GamePalette.textMuted)
            }

            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ASSISTED PB")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(GamePalette.textMuted)
                    Text(assistedBestScore.formatted())
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.info)
                        .monospacedDigit()
                }
                Spacer()
                Button(action: showRankings) {
                    Label("LOCAL TOP 10", systemImage: "trophy.fill")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(GamePalette.warning)
                        .frame(minHeight: 44)
                }
                .accessibilityIdentifier("descentRankingsButton")
            }

            Button("기체 · 부스터 선택", action: start)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("startDescentButton")
        }
        .padding(GameSpacing.large)
        .background(GamePalette.surface1.opacity(0.97), in: RoundedRectangle(cornerRadius: GameRadius.panel))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.panel)
                .stroke(
                    LinearGradient(
                        colors: [GamePalette.fire, GamePalette.warning, GamePalette.info],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("descentModeCard")
    }
}

private struct DescentAtlasCell: View {
    let asset: String
    let crop: CGRect

    var body: some View {
        GeometryReader { proxy in
            Image(asset)
                .resizable()
                .frame(
                    width: proxy.size.width / crop.width,
                    height: proxy.size.height / crop.height
                )
                .offset(
                    x: -proxy.size.width * crop.minX / crop.width,
                    y: -proxy.size.height * crop.minY / crop.height
                )
        }
        .clipped()
    }
}

private extension DescentShipKind {
    var shortName: String {
        switch self {
        case .interceptor: "스위프트"
        case .striker: "해머"
        case .guardian: "트라이던트"
        }
    }

    var displayName: String {
        switch self {
        case .interceptor: "스위프트 S-1"
        case .striker: "해머 H-2"
        case .guardian: "트라이던트 T-3"
        }
    }

    var roleName: String {
        switch self {
        case .interceptor: "표준 정밀기"
        case .striker: "중장 파쇄기"
        case .guardian: "광역 방어기"
        }
    }

    var weaponSummary: String {
        switch self {
        case .interceptor: "고속 단발"
        case .striker: "고화력 랜스"
        case .guardian: "3레인 살보"
        }
    }

    var detailSummary: String {
        switch self {
        case .interceptor: "빠른 이동·연사가 강점입니다. 한 레인만 공격하고 순간 화력은 낮습니다."
        case .striker: "한 발 화력이 가장 강합니다. 이동이 가장 느리고 한 레인만 공격합니다."
        case .guardian: "세 레인을 동시에 막습니다. 단일 대상 DPS가 가장 낮고 원소 효과는 중앙탄만 발동합니다."
        }
    }

    var statGrades: [(label: String, level: Int)] {
        switch self {
        case .interceptor:
            [("화력", 2), ("연사", 3), ("기동", 3), ("범위", 1)]
        case .striker:
            [("화력", 3), ("연사", 2), ("기동", 1), ("범위", 1)]
        case .guardian:
            [("화력", 1), ("연사", 2), ("기동", 2), ("범위", 3)]
        }
    }

    var statAccessibilitySummary: String {
        statGrades.map { "\($0.label) 레벨 \($0.level)" }.joined(separator: ", ")
    }

    var accent: Color {
        switch self {
        case .interceptor: GamePalette.info
        case .striker: GamePalette.fireCore
        case .guardian: GamePalette.success
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .interceptor: "descentShipOptionSwift"
        case .striker: "descentShipOptionHammer"
        case .guardian: "descentShipOptionTrident"
        }
    }
}

private struct ReturnShotPreview: View {
    private struct PreviewBrick: Identifiable {
        let id: Int
        let color: Color
        let mark: String
        let pips: Int
        let item: AttackItemKind?
    }

    private var bricks: [PreviewBrick] {
        [
            PreviewBrick(id: 0, color: GamePalette.brick(.coral), mark: "●", pips: 1, item: nil),
            PreviewBrick(id: 1, color: GamePalette.fire, mark: "▲", pips: 2, item: .flame),
            PreviewBrick(id: 2, color: GamePalette.brick(.blue), mark: "★", pips: 1, item: nil),
            PreviewBrick(id: 3, color: GamePalette.arcane, mark: "◆", pips: 3, item: .pierce),
            PreviewBrick(id: 4, color: GamePalette.brick(.mint), mark: "●", pips: 1, item: .wind),
            PreviewBrick(id: 5, color: GamePalette.electric, mark: "▲", pips: 2, item: .lightning)
        ]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: GameRadius.panel)
                    .fill(GamePalette.surface0.opacity(0.96))

                VStack(spacing: GameSpacing.small) {
                    HStack {
                        Label("LIVE PLAYFIELD", systemImage: "dot.radiowaves.left.and.right")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(0.8)
                            .foregroundStyle(GamePalette.textMuted)
                        Spacer()
                    }

                    HStack(spacing: 7) {
                        ForEach(bricks) { brick in
                            previewBrick(brick)
                        }
                    }

                    HStack(spacing: 7) {
                        supportBrick
                        negativeBrick
                        supportBrick
                        negativeBrick
                    }

                    Spacer(minLength: 8)

                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 36, y: 48))
                            path.addLine(to: CGPoint(x: proxy.size.width * 0.48, y: 10))
                            path.addLine(to: CGPoint(x: proxy.size.width - 52, y: 46))
                        }
                        .stroke(GamePalette.electric.opacity(0.66), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))

                        Circle()
                            .fill(GamePalette.textPrimary)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image("RS_Ball_Chrome")
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(1.50)
                                    .blendMode(.multiply)
                                    .clipShape(Circle())
                            }
                            .overlay(Circle().stroke(GamePalette.electric, lineWidth: 2))
                            .shadow(color: GamePalette.electric.opacity(0.55), radius: 8)
                            .offset(x: 42, y: -3)
                    }
                    .frame(height: 58)

                    ZStack {
                        RoundedRectangle(cornerRadius: GameRadius.card)
                            .fill(GamePalette.surface3)
                            .frame(width: 142, height: 27)

                        HStack(spacing: 3) {
                            mechanicalEndCap

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [GamePalette.fire, GamePalette.fireCore, GamePalette.fire],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 84, height: 11)
                                .overlay(Capsule().stroke(GamePalette.textPrimary.opacity(0.72), lineWidth: 1))
                                .shadow(color: GamePalette.fire, radius: 6)

                            mechanicalEndCap
                        }
                    }
                        .overlay(
                            RoundedRectangle(cornerRadius: GameRadius.card)
                                .stroke(GamePalette.info, lineWidth: 2)
                        )
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(GamePalette.fireCore)
                                .frame(width: 44, height: 3)
                                .offset(y: 3)
                        }
                        .shadow(color: GamePalette.fire.opacity(0.34), radius: 8)
                }
                .padding(GameSpacing.large)

            }
            .overlay(
                RoundedRectangle(cornerRadius: GameRadius.panel)
                    .stroke(GamePalette.border)
            )
        }
        .frame(height: 250)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("다양한 내구도 벽돌과 네 가지 공격 코어, 공과 패들 미리보기")
    }

    private var mechanicalEndCap: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(GamePalette.deep)
            .frame(width: 19, height: 19)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(GamePalette.fire, lineWidth: 2)
            )
    }

    private func previewBrick(_ brick: PreviewBrick) -> some View {
        RoundedRectangle(cornerRadius: GameRadius.brick)
            .fill(
                LinearGradient(
                    colors: [brick.color.opacity(0.96), brick.color.opacity(0.52)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(maxWidth: .infinity, minHeight: 45)
            .overlay(
                Image("RS_Brick_Material")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.18)
                    .colorMultiply(brick.color)
                    .blendMode(.multiply)
                    .clipShape(RoundedRectangle(cornerRadius: GameRadius.brick))
            )
            .overlay(
                RoundedRectangle(cornerRadius: GameRadius.brick)
                    .stroke(brick.color.opacity(0.95), lineWidth: 1.5)
            )
            .overlay(Text(brick.mark).font(.system(size: 13, weight: .black)))
            .overlay(alignment: .bottom) {
                HStack(spacing: 2) {
                    ForEach(0..<brick.pips, id: \.self) { _ in
                        Capsule().fill(GamePalette.fireCore).frame(width: 7, height: 3)
                    }
                }
                .padding(.bottom, 4)
            }
            .overlay(alignment: .topTrailing) {
                if let item = brick.item {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(GamePalette.attackCore(item))
                        .frame(width: 17, height: 17)
                        .background(GamePalette.deep, in: RoundedRectangle(cornerRadius: 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(GamePalette.attack(item))
                        )
                        .offset(x: 3, y: -3)
                }
            }
    }

    private var supportBrick: some View {
        RoundedRectangle(cornerRadius: GameRadius.brick)
            .fill(GamePalette.surface2)
            .frame(maxWidth: .infinity, minHeight: 31)
            .overlay(Text("⌁").font(.caption.weight(.black)).foregroundStyle(GamePalette.warning))
            .overlay(RoundedRectangle(cornerRadius: GameRadius.brick).stroke(GamePalette.warning.opacity(0.72)))
    }

    private var negativeBrick: some View {
        RoundedRectangle(cornerRadius: GameRadius.brick)
            .fill(GamePalette.danger.opacity(0.18))
            .frame(maxWidth: .infinity, minHeight: 31)
            .overlay(Image(systemName: "minus").font(.caption.weight(.black)).foregroundStyle(GamePalette.danger))
            .overlay(RoundedRectangle(cornerRadius: GameRadius.brick).stroke(GamePalette.danger))
    }
}
