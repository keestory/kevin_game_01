import SwiftUI

extension Color {
    static let trainNavy = Color(hex: 0x10182C)
    static let trainPanel = Color(hex: 0x182541)
    static let safetyYellow = Color(hex: 0xFFD84D)
    static let exitMint = Color(hex: 0x36D6A0)
    static let alertCoral = Color(hex: 0xFF665F)
    static let warmIvory = Color(hex: 0xF7F3E8)

    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .heavy))
            .foregroundStyle(Color.trainNavy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color.safetyYellow.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier()) }
}
