import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.haptics") private var haptics = true
    @AppStorage("settings.sound") private var sound = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Image("RS_Playfield_Background")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .overlay(GamePalette.canvas.opacity(0.72).ignoresSafeArea())

                ScrollView(showsIndicators: false) {
                    VStack(spacing: GameSpacing.large) {
                        settingsPanel(title: "PLAY FEEDBACK", icon: "waveform.path") {
                            settingToggle("사운드", subtitle: "속성별 타격과 콤보 리듬", icon: "speaker.wave.2.fill", value: $sound)
                            Divider().overlay(GamePalette.borderSubtle)
                            settingToggle("햅틱", subtitle: "리턴·공명·큰 파괴 피드백", icon: "hand.tap.fill", value: $haptics)
                        }

                        settingsPanel(title: "ACCESSIBILITY", icon: "accessibility") {
                            statusRow(
                                title: "동작 줄이기",
                                value: reduceMotion ? "시스템에서 켜짐" : "시스템 설정 따름",
                                icon: "figure.walk.motion",
                                color: reduceMotion ? GamePalette.success : GamePalette.info
                            )
                            Divider().overlay(GamePalette.borderSubtle)
                            statusRow(
                                title: "색상 외 신호",
                                value: "문양·아이콘 항상 표시",
                                icon: "circle.hexagongrid.fill",
                                color: GamePalette.arcane
                            )
                        }

                        settingsPanel(title: "BUILD", icon: "hammer.fill") {
                            infoRow("버전", value: "0.4 Action Design")
                            Divider().overlay(GamePalette.borderSubtle)
                            infoRow("오늘의 시드", value: String(DailySeed.current()))
                            Divider().overlay(GamePalette.borderSubtle)
                            infoRow("렌더", value: "SwiftUI + SpriteKit")
                        }
                    }
                    .padding(GameSpacing.large)
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(GamePalette.surface0, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                        .font(.headline.weight(.black))
                        .foregroundStyle(GamePalette.fireCore)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func settingsPanel<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: GameSpacing.medium) {
            Label(title, systemImage: icon)
                .font(.system(.caption, design: .rounded, weight: .black))
                .tracking(1.0)
                .foregroundStyle(GamePalette.textMuted)
            content()
        }
        .padding(GameSpacing.large)
        .background(GamePalette.surface1, in: RoundedRectangle(cornerRadius: GameRadius.panel))
        .overlay(
            RoundedRectangle(cornerRadius: GameRadius.panel)
                .stroke(GamePalette.borderSubtle)
        )
        .overlay {
            Image("RS_HUD_Frame")
                .resizable()
                .scaledToFill()
                .blendMode(.screen)
                .opacity(0.56)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private func settingToggle(
        _ title: String,
        subtitle: String,
        icon: String,
        value: Binding<Bool>
    ) -> some View {
        Toggle(isOn: value) {
            HStack(spacing: GameSpacing.medium) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(GamePalette.fireCore)
                    .frame(width: 34, height: 34)
                    .background(GamePalette.fire.opacity(0.10), in: RoundedRectangle(cornerRadius: GameRadius.badge))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(GamePalette.textPrimary)
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GamePalette.textSecondary)
                }
            }
        }
        .tint(GamePalette.fire)
        .frame(minHeight: 52)
    }

    private func statusRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: GameSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: GameRadius.badge))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(GamePalette.textPrimary)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(GamePalette.textSecondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(color)
        }
        .frame(minHeight: 48)
    }

    private func infoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(GamePalette.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced, weight: .black))
                .foregroundStyle(GamePalette.textPrimary)
        }
        .frame(minHeight: 36)
    }
}
