import SwiftUI

/// Swift-native, presentation-only adapter for the imported Brick Breaker design kit.
/// The imported JSON/TypeScript files remain reference inputs and are not runtime resources.
enum BrickBreakerDesignAdapter {
    static let sourceName = "Brick Breaker Action Design System"
    static let sourceVersion = "1.0.0"

    enum Palette {
        static let canvas = Color(hex: 0x050A12)
        static let deep = Color(hex: 0x02060C)
        static let surface0 = Color(hex: 0x07111F)
        static let surface1 = Color(hex: 0x0B1728)
        static let surface2 = Color(hex: 0x102137)
        static let surface3 = Color(hex: 0x162B45)
        static let borderSubtle = Color(hex: 0x18314A)
        static let border = Color(hex: 0x244867)
        static let borderStrong = Color(hex: 0x3B6B8E)
        static let textPrimary = Color(hex: 0xF4F8FF)
        static let textSecondary = Color(hex: 0xA9BCD1)
        static let textMuted = Color(hex: 0x6F849B)
        static let success = Color(hex: 0x39D98A)
        static let warning = Color(hex: 0xFFC145)
        static let danger = Color(hex: 0xFF453A)
        static let info = Color(hex: 0x4DB8FF)
    }

    enum Space {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let section: CGFloat = 32
    }

    enum Radius {
        static let brick: CGFloat = 4
        static let badge: CGFloat = 6
        static let button: CGFloat = 10
        static let card: CGFloat = 12
        static let panel: CGFloat = 16
    }

    enum Motion {
        static let instant = 0.06
        static let fast = 0.10
        static let normal = 0.18
        static let slow = 0.32
    }

    struct ElementToken: Identifiable, Equatable {
        let kind: AttackItemKind
        let mainHex: UInt
        let coreHex: UInt
        let shapeName: String
        let behaviorName: String
        let isSourceExtension: Bool

        var id: AttackItemKind { kind }
        var main: Color { Color(hex: mainHex) }
        var core: Color { Color(hex: coreHex) }
    }

    /// Only the four attacks approved by Return Shot ProductSpec rev3 are exposed.
    /// Wind has no exact source-kit token, so its existing product color is an explicit extension.
    static let approvedElements: [ElementToken] = [
        ElementToken(
            kind: .lightning,
            mainHex: 0x168BFF,
            coreHex: 0xE6F7FF,
            shapeName: "분기 번개",
            behaviorName: "가까운 대상 연쇄",
            isSourceExtension: false
        ),
        ElementToken(
            kind: .flame,
            mainHex: 0xFF7A00,
            coreHex: 0xFFD166,
            shapeName: "상승 불꽃",
            behaviorName: "반경 안의 대상 타격",
            isSourceExtension: false
        ),
        ElementToken(
            kind: .wind,
            mainHex: 0x66E5E0,
            coreHex: 0xE8FCFF,
            shapeName: "세 갈래 흐름",
            behaviorName: "위쪽 구조 밀어내기",
            isSourceExtension: true
        ),
        ElementToken(
            kind: .pierce,
            mainHex: 0x7CFF2B,
            coreHex: 0xE8FFB5,
            shapeName: "직선 창끝",
            behaviorName: "다음 직접타 무반사",
            isSourceExtension: false
        )
    ]

    static func element(for kind: AttackItemKind) -> ElementToken {
        approvedElements.first(where: { $0.kind == kind }) ?? approvedElements[0]
    }
}

struct DesignSystemGalleryView: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var reduceMotionPreview = false
    @State private var photosensitivitySafe = true
    @State private var colorAssist = true
    @State private var selectedEffect: AttackItemKind = .lightning
    @State private var effectPulse = false

    private var reduceMotion: Bool { systemReduceMotion || reduceMotionPreview }

    var body: some View {
        ZStack {
            BrickBreakerDesignAdapter.Palette.canvas
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    BrickBreakerDesignAdapter.Palette.surface2.opacity(0.74),
                    BrickBreakerDesignAdapter.Palette.canvas.opacity(0.25),
                    BrickBreakerDesignAdapter.Palette.deep
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .accessibilityHidden(true)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: BrickBreakerDesignAdapter.Space.section) {
                    galleryHeader
                    accessibilityControls
                    paletteSection
                    typeSection
                    componentsSection
                    playfieldSection
                    effectSection
                    contractSection
                }
                .padding(.horizontal, BrickBreakerDesignAdapter.Space.large)
                .padding(.vertical, BrickBreakerDesignAdapter.Space.large)
            }
        }
        .foregroundStyle(BrickBreakerDesignAdapter.Palette.textPrimary)
        .accessibilityIdentifier("designSystemGallery")
        .statusBarHidden(true)
    }

    private var galleryHeader: some View {
        VStack(alignment: .leading, spacing: BrickBreakerDesignAdapter.Space.small) {
            HStack {
                Label("NATIVE ADAPTER", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.black))
                    .foregroundStyle(BrickBreakerDesignAdapter.Palette.success)
                Spacer()
                Text("DEV ONLY")
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, BrickBreakerDesignAdapter.Space.small)
                    .frame(minHeight: 24)
                    .background(BrickBreakerDesignAdapter.Palette.warning.opacity(0.14), in: Capsule())
                    .overlay(Capsule().stroke(BrickBreakerDesignAdapter.Palette.warning.opacity(0.6)))
            }

            Text("RETURN SHOT\nDESIGN SYSTEM")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .lineSpacing(-4)

            Text("기존 SwiftUI · SpriteKit 구조 위에 얹은 비권위 시각 어댑터")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var accessibilityControls: some View {
        gallerySection(title: "접근성 미리보기", subtitle: "토글은 Gallery 표현만 바꾸며 게임 규칙에는 영향을 주지 않습니다") {
            VStack(spacing: 0) {
                previewToggle(
                    "Reduce Motion",
                    icon: "figure.walk.motion",
                    value: $reduceMotionPreview,
                    identifier: "galleryReduceMotion"
                )
                Divider().overlay(BrickBreakerDesignAdapter.Palette.borderSubtle)
                previewToggle(
                    "Photosensitivity Safe",
                    icon: "sun.max.trianglebadge.exclamationmark",
                    value: $photosensitivitySafe,
                    identifier: "galleryPhotosensitivity"
                )
                Divider().overlay(BrickBreakerDesignAdapter.Palette.borderSubtle)
                previewToggle(
                    "Color Assist",
                    icon: "eye.circle.fill",
                    value: $colorAssist,
                    identifier: "galleryColorAssist"
                )
            }
            .padding(.horizontal, BrickBreakerDesignAdapter.Space.large)
            .background(BrickBreakerDesignAdapter.Palette.surface1, in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel))
            .overlay(
                RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
                    .stroke(BrickBreakerDesignAdapter.Palette.borderSubtle)
            )
        }
    }

    private var paletteSection: some View {
        gallerySection(title: "컬러 토큰", subtitle: "캔버스 → 표면 → 의미 색 순서로 위계를 고정합니다") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                swatch("Canvas", BrickBreakerDesignAdapter.Palette.canvas)
                swatch("Surface 1", BrickBreakerDesignAdapter.Palette.surface1)
                swatch("Surface 2", BrickBreakerDesignAdapter.Palette.surface2)
                swatch("Border", BrickBreakerDesignAdapter.Palette.border)
                swatch("Success", BrickBreakerDesignAdapter.Palette.success)
                swatch("Warning", BrickBreakerDesignAdapter.Palette.warning)
                swatch("Danger", BrickBreakerDesignAdapter.Palette.danger)
                swatch("Info", BrickBreakerDesignAdapter.Palette.info)
            }
        }
    }

    private var typeSection: some View {
        gallerySection(title: "타이포그래피", subtitle: "Dynamic Type과 tabular number를 유지합니다") {
            VStack(alignment: .leading, spacing: BrickBreakerDesignAdapter.Space.medium) {
                Text("IMPACT 50")
                    .font(.system(.title, design: .rounded, weight: .black))
                Text("연쇄 파괴가 이어지고 있어요")
                    .font(.headline.weight(.bold))
                Text("볼의 위치와 다음 위험이 장식보다 먼저 읽혀야 합니다.")
                    .font(.body)
                    .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
                Text("SCORE 012,840  ·  COMBO ×16")
                    .font(.system(.caption, design: .monospaced, weight: .bold))
                    .foregroundStyle(BrickBreakerDesignAdapter.Palette.textMuted)
                    .monospacedDigit()
            }
            .adapterPanel()
        }
    }

    private var componentsSection: some View {
        gallerySection(title: "UI 컴포넌트", subtitle: "44pt 이상 터치 영역과 명확한 pressed 상태") {
            VStack(spacing: BrickBreakerDesignAdapter.Space.large) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: BrickBreakerDesignAdapter.Space.small) {
                        adapterButtons
                    }
                    VStack(spacing: BrickBreakerDesignAdapter.Space.small) {
                        adapterButtons
                    }
                }

                HStack(spacing: BrickBreakerDesignAdapter.Space.small) {
                    adapterCounter("SCORE", "12,840", BrickBreakerDesignAdapter.Palette.textPrimary)
                    adapterCounter("COMBO", "×16", BrickBreakerDesignAdapter.Palette.warning)
                    adapterCounter("PB", "+320", BrickBreakerDesignAdapter.Palette.success)
                }

                HStack(spacing: BrickBreakerDesignAdapter.Space.small) {
                    adapterBadge("ACTIVE", color: BrickBreakerDesignAdapter.Palette.success, icon: "bolt.fill")
                    adapterBadge("WARNING", color: BrickBreakerDesignAdapter.Palette.warning, icon: "exclamationmark.triangle.fill")
                    adapterBadge("DANGER", color: BrickBreakerDesignAdapter.Palette.danger, icon: "minus.circle.fill")
                }
            }
        }
    }

    @ViewBuilder
    private var adapterButtons: some View {
        Button("PRIMARY") { effectPulse.toggle() }
            .buttonStyle(AdapterButtonStyle(variant: .primary))
        Button("SECONDARY") { effectPulse.toggle() }
            .buttonStyle(AdapterButtonStyle(variant: .secondary))
        Button("GHOST") { effectPulse.toggle() }
            .buttonStyle(AdapterButtonStyle(variant: .ghost))
    }

    private var playfieldSection: some View {
        gallerySection(title: "플레이 오브젝트", subtitle: "색뿐 아니라 역할·내구도·문양을 함께 보여줍니다") {
            VStack(spacing: BrickBreakerDesignAdapter.Space.large) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 98), spacing: 10)], spacing: 10) {
                    AdapterBrick(title: "NORMAL", symbol: "★ ≡", color: BrickBreakerDesignAdapter.Palette.success, pips: 1)
                    AdapterBrick(title: "SUPPORT", symbol: "⌁", color: BrickBreakerDesignAdapter.Palette.info, pips: 2)
                    AdapterBrick(title: "PRISM", symbol: "◆", color: BrickBreakerDesignAdapter.Palette.warning, pips: 3)
                    AdapterBrick(title: "NEGATIVE", symbol: "−250", color: BrickBreakerDesignAdapter.Palette.danger, pips: 0)
                }

                AdapterPlayfieldPreview(reduceMotion: reduceMotion, safeMode: photosensitivitySafe)
            }
        }
    }

    private var effectSection: some View {
        gallerySection(title: "Effect Preview", subtitle: "현행 ProductSpec이 승인한 4종만 표시합니다") {
            VStack(spacing: BrickBreakerDesignAdapter.Space.large) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                    ForEach(BrickBreakerDesignAdapter.approvedElements) { token in
                        Button {
                            selectedEffect = token.kind
                            withAnimation(reduceMotion ? nil : .easeOut(duration: BrickBreakerDesignAdapter.Motion.normal)) {
                                effectPulse.toggle()
                            }
                        } label: {
                            AdapterEffectCard(
                                token: token,
                                selected: token.kind == selectedEffect,
                                colorAssist: colorAssist
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("galleryEffect-\(token.kind.name)")
                    }
                }

                AdapterEffectStage(
                    token: BrickBreakerDesignAdapter.element(for: selectedEffect),
                    pulse: effectPulse,
                    reduceMotion: reduceMotion,
                    safeMode: photosensitivitySafe,
                    colorAssist: colorAssist
                )
            }
        }
    }

    private var contractSection: some View {
        gallerySection(title: "개발 계약", subtitle: "측정값이 아니라 이번 어댑터의 제한 범위입니다") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 142), spacing: 10)], spacing: 10) {
                contractMetric("SOURCE", BrickBreakerDesignAdapter.sourceVersion)
                contractMetric("EFFECTS", "4 APPROVED")
                contractMetric("ACTIVE BALL", "1")
                contractMetric("TARGET", "60 FPS")
            }
            .accessibilityIdentifier("galleryDeveloperContract")
        }
    }

    private func gallerySection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: BrickBreakerDesignAdapter.Space.medium) {
            VStack(alignment: .leading, spacing: BrickBreakerDesignAdapter.Space.xSmall) {
                Text(title.uppercased())
                    .font(.system(.headline, design: .rounded, weight: .black))
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func previewToggle(
        _ title: String,
        icon: String,
        value: Binding<Bool>,
        identifier: String
    ) -> some View {
        Toggle(isOn: value) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
        }
        .tint(BrickBreakerDesignAdapter.Palette.success)
        .frame(minHeight: 48)
        .accessibilityIdentifier(identifier)
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: BrickBreakerDesignAdapter.Space.small) {
            RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.button)
                .fill(color)
                .frame(height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.button)
                        .stroke(BrickBreakerDesignAdapter.Palette.borderStrong.opacity(0.7))
                )
            Text(name)
                .font(.caption.weight(.bold))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) 컬러 토큰")
    }

    private func adapterCounter(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textMuted)
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .black))
                .foregroundStyle(color)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(BrickBreakerDesignAdapter.Palette.surface1, in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.card).stroke(BrickBreakerDesignAdapter.Palette.borderSubtle))
        .accessibilityElement(children: .combine)
    }

    private func adapterBadge(_ title: String, color: Color, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(.caption2, design: .rounded, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, BrickBreakerDesignAdapter.Space.small)
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.badge))
            .overlay(RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.badge).stroke(color.opacity(0.55)))
    }

    private func contractMetric(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textMuted)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced, weight: .black))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.success)
        }
        .padding(.horizontal, BrickBreakerDesignAdapter.Space.medium)
        .frame(minHeight: 46)
        .background(BrickBreakerDesignAdapter.Palette.surface1, in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.card))
        .overlay(RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.card).stroke(BrickBreakerDesignAdapter.Palette.borderSubtle))
    }
}

private enum AdapterButtonVariant {
    case primary
    case secondary
    case ghost
}

private struct AdapterButtonStyle: ButtonStyle {
    let variant: AdapterButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .rounded, weight: .black))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(background.opacity(configuration.isPressed ? 0.70 : 1), in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.button))
            .overlay(
                RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.button)
                    .stroke(border.opacity(configuration.isPressed ? 1 : 0.65))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: BrickBreakerDesignAdapter.Motion.instant), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary: BrickBreakerDesignAdapter.Palette.deep
        case .secondary, .ghost: BrickBreakerDesignAdapter.Palette.textPrimary
        }
    }

    private var background: Color {
        switch variant {
        case .primary: BrickBreakerDesignAdapter.Palette.success
        case .secondary: BrickBreakerDesignAdapter.Palette.surface3
        case .ghost: .clear
        }
    }

    private var border: Color {
        switch variant {
        case .primary: BrickBreakerDesignAdapter.Palette.success
        case .secondary: BrickBreakerDesignAdapter.Palette.borderStrong
        case .ghost: BrickBreakerDesignAdapter.Palette.border
        }
    }
}

private struct AdapterBrick: View {
    let title: String
    let symbol: String
    let color: Color
    let pips: Int

    var body: some View {
        VStack(spacing: 7) {
            Text(symbol)
                .font(.system(.headline, design: .rounded, weight: .black))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if pips > 0 {
                HStack(spacing: 3) {
                    ForEach(0..<pips, id: \.self) { _ in
                        Capsule().fill(color).frame(width: 11, height: 4)
                    }
                }
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.brick))
        .overlay(RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.brick).stroke(color, lineWidth: 2))
        .accessibilityElement(children: .combine)
    }
}

private struct AdapterPlayfieldPreview: View {
    let reduceMotion: Bool
    let safeMode: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
                .fill(BrickBreakerDesignAdapter.Palette.surface0)

            VStack {
                HStack(spacing: 9) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.brick)
                            .fill(index == 2 ? BrickBreakerDesignAdapter.Palette.warning.opacity(0.25) : BrickBreakerDesignAdapter.Palette.info.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.brick)
                                    .stroke(index == 2 ? BrickBreakerDesignAdapter.Palette.warning : BrickBreakerDesignAdapter.Palette.info)
                            )
                            .overlay(Text(index == 2 ? "◆" : "≡").font(.caption.weight(.black)))
                            .frame(height: 36)
                    }
                }
                Spacer()
                Circle()
                    .fill(BrickBreakerDesignAdapter.Palette.textPrimary)
                    .frame(width: 24, height: 24)
                    .overlay(Circle().stroke(BrickBreakerDesignAdapter.Palette.success, lineWidth: 3))
                    .shadow(
                        color: BrickBreakerDesignAdapter.Palette.success.opacity(safeMode ? 0.24 : 0.60),
                        radius: safeMode ? 5 : 10
                    )
                    .offset(x: reduceMotion ? 0 : 34)
                Capsule()
                    .fill(BrickBreakerDesignAdapter.Palette.surface3)
                    .frame(width: 128, height: 22)
                    .overlay(Capsule().stroke(BrickBreakerDesignAdapter.Palette.success, lineWidth: 3))
            }
            .padding(18)
        }
        .frame(height: 210)
        .overlay(
            RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
                .stroke(BrickBreakerDesignAdapter.Palette.border)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("벽돌, 공, 패들의 디자인 시스템 미리보기")
    }
}

private struct AdapterEffectCard: View {
    let token: BrickBreakerDesignAdapter.ElementToken
    let selected: Bool
    let colorAssist: Bool

    var body: some View {
        HStack(spacing: BrickBreakerDesignAdapter.Space.small) {
            Image(systemName: token.kind.systemImage)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(token.core)
                .frame(width: 36, height: 36)
                .background(token.main.opacity(0.18), in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.badge))
            VStack(alignment: .leading, spacing: 2) {
                Text(token.kind.name)
                    .font(.subheadline.weight(.black))
                Text(colorAssist ? token.shapeName : token.behaviorName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, BrickBreakerDesignAdapter.Space.medium)
        .frame(minHeight: 58)
        .background(token.main.opacity(selected ? 0.18 : 0.07), in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.card)
                .stroke(selected ? token.main : BrickBreakerDesignAdapter.Palette.borderSubtle, lineWidth: selected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(token.kind.name), \(token.shapeName), \(token.behaviorName)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct AdapterEffectStage: View {
    let token: BrickBreakerDesignAdapter.ElementToken
    let pulse: Bool
    let reduceMotion: Bool
    let safeMode: Bool
    let colorAssist: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
                .fill(BrickBreakerDesignAdapter.Palette.surface0)

            Circle()
                .stroke(token.main.opacity(safeMode ? 0.18 : 0.34), lineWidth: 2)
                .frame(width: pulse ? 142 : 106, height: pulse ? 142 : 106)

            Circle()
                .fill(token.main.opacity(0.22))
                .frame(width: 92, height: 92)
                .shadow(
                    color: token.main.opacity(safeMode ? 0.18 : 0.38),
                    radius: safeMode ? 6 : 18
                )

            Image(systemName: token.kind.systemImage)
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(token.core)
                .rotationEffect(.degrees(reduceMotion ? 0 : (pulse ? 5 : -5)))

            VStack {
                HStack {
                    adapterStageLabel("IMPACT", token.kind.name.uppercased(), token.main)
                    Spacer()
                    if token.isSourceExtension {
                        adapterStageLabel("ADAPTER", "PROVISIONAL", BrickBreakerDesignAdapter.Palette.warning)
                    }
                }
                Spacer()
                HStack {
                    if colorAssist {
                        Label(token.shapeName, systemImage: token.kind.systemImage)
                    } else {
                        Text(token.behaviorName)
                    }
                    Spacer()
                    Text("L1 → L3")
                        .monospacedDigit()
                }
                .font(.caption.weight(.black))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textSecondary)
            }
            .padding(BrickBreakerDesignAdapter.Space.large)
        }
        .frame(height: 206)
        .overlay(
            RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
                .stroke(token.main.opacity(0.55))
        )
        .animation(
            reduceMotion ? nil : .easeOut(duration: BrickBreakerDesignAdapter.Motion.normal),
            value: pulse
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(token.kind.name) 효과 미리보기. \(token.shapeName). \(token.behaviorName)")
        .accessibilityIdentifier("galleryEffectStage")
    }

    private func adapterStageLabel(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2.weight(.black))
                .foregroundStyle(BrickBreakerDesignAdapter.Palette.textMuted)
            Text(value)
                .font(.caption.weight(.black))
                .foregroundStyle(color)
        }
    }
}

private extension View {
    func adapterPanel() -> some View {
        padding(BrickBreakerDesignAdapter.Space.large)
            .background(
                BrickBreakerDesignAdapter.Palette.surface1,
                in: RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BrickBreakerDesignAdapter.Radius.panel)
                    .stroke(BrickBreakerDesignAdapter.Palette.borderSubtle)
            )
    }
}
