import SwiftUI
import UIKit

/// Product-facing semantic bridge for the imported Brick Breaker kit.
/// SwiftUI screens consume `Color`; SpriteKit consumes the matching packed RGB value.
enum GamePalette {
    static let canvas = BrickBreakerDesignAdapter.Palette.canvas
    static let deep = BrickBreakerDesignAdapter.Palette.deep
    static let surface0 = BrickBreakerDesignAdapter.Palette.surface0
    static let surface1 = BrickBreakerDesignAdapter.Palette.surface1
    static let surface2 = BrickBreakerDesignAdapter.Palette.surface2
    static let surface3 = BrickBreakerDesignAdapter.Palette.surface3
    static let borderSubtle = BrickBreakerDesignAdapter.Palette.borderSubtle
    static let border = BrickBreakerDesignAdapter.Palette.border
    static let borderStrong = BrickBreakerDesignAdapter.Palette.borderStrong
    static let textPrimary = BrickBreakerDesignAdapter.Palette.textPrimary
    static let textSecondary = BrickBreakerDesignAdapter.Palette.textSecondary
    static let textMuted = BrickBreakerDesignAdapter.Palette.textMuted
    static let success = BrickBreakerDesignAdapter.Palette.success
    static let warning = BrickBreakerDesignAdapter.Palette.warning
    static let danger = BrickBreakerDesignAdapter.Palette.danger
    static let info = BrickBreakerDesignAdapter.Palette.info
    static let coralHex = BrickColor.coral.tintHex
    static let coral = Color(hex: coralHex)
    static let shieldBlue = info

    // Named action accents used by product art; every value still resolves to an approved element token.
    static let electric = BrickBreakerDesignAdapter.element(for: .lightning).main
    static let fire = BrickBreakerDesignAdapter.element(for: .flame).main
    static let fireCore = BrickBreakerDesignAdapter.element(for: .flame).core
    static let arcane = BrickBreakerDesignAdapter.element(for: .pierce).main

    static let canvasHex = canvas.packedRGB
    static let deepHex = deep.packedRGB
    static let surface0Hex = surface0.packedRGB
    static let surface1Hex = surface1.packedRGB
    static let surface2Hex = surface2.packedRGB
    static let surface3Hex = surface3.packedRGB
    static let borderSubtleHex = borderSubtle.packedRGB
    static let borderHex = border.packedRGB
    static let borderStrongHex = borderStrong.packedRGB
    static let textPrimaryHex = textPrimary.packedRGB
    static let textSecondaryHex = textSecondary.packedRGB
    static let textMutedHex = textMuted.packedRGB
    static let successHex = success.packedRGB
    static let warningHex = warning.packedRGB
    static let dangerHex = danger.packedRGB
    static let infoHex = info.packedRGB
    static let shieldBlueHex = infoHex
    static let electricHex = BrickBreakerDesignAdapter.element(for: .lightning).mainHex
    static let fireHex = BrickBreakerDesignAdapter.element(for: .flame).mainHex
    static let fireCoreHex = BrickBreakerDesignAdapter.element(for: .flame).coreHex
    static let arcaneHex = BrickBreakerDesignAdapter.element(for: .pierce).mainHex

    static func brick(_ color: BrickColor) -> Color {
        switch color {
        case .mint: success
        case .coral: coral
        case .blue: info
        }
    }

    static func brickHex(_ color: BrickColor) -> UInt {
        switch color {
        case .mint: successHex
        case .coral: coralHex
        case .blue: infoHex
        }
    }

    static func attack(_ kind: AttackItemKind) -> Color {
        BrickBreakerDesignAdapter.element(for: kind).main
    }

    static func attackHex(_ kind: AttackItemKind) -> UInt {
        BrickBreakerDesignAdapter.element(for: kind).mainHex
    }

    static func attackCore(_ kind: AttackItemKind) -> Color {
        BrickBreakerDesignAdapter.element(for: kind).core
    }

    static func attackCoreHex(_ kind: AttackItemKind) -> UInt {
        BrickBreakerDesignAdapter.element(for: kind).coreHex
    }
}

enum GameSpacing {
    static let xSmall = BrickBreakerDesignAdapter.Space.xSmall
    static let small = BrickBreakerDesignAdapter.Space.small
    static let medium = BrickBreakerDesignAdapter.Space.medium
    static let large = BrickBreakerDesignAdapter.Space.large
    static let xLarge = BrickBreakerDesignAdapter.Space.xLarge
    static let section = BrickBreakerDesignAdapter.Space.section
}

enum GameRadius {
    static let brick = BrickBreakerDesignAdapter.Radius.brick
    static let badge = BrickBreakerDesignAdapter.Radius.badge
    static let button = BrickBreakerDesignAdapter.Radius.button
    static let card = BrickBreakerDesignAdapter.Radius.card
    static let panel = BrickBreakerDesignAdapter.Radius.panel
}

enum GameMotion {
    static let instant = BrickBreakerDesignAdapter.Motion.instant
    static let fast = BrickBreakerDesignAdapter.Motion.fast
    static let normal = BrickBreakerDesignAdapter.Motion.normal
    static let slow = BrickBreakerDesignAdapter.Motion.slow
}

extension Color {
    // Compatibility aliases for screens that are migrating incrementally.
    static let trainNavy = GamePalette.deep
    static let trainPanel = GamePalette.surface2
    static let safetyYellow = GamePalette.warning
    static let exitMint = GamePalette.success
    static let alertCoral = GamePalette.danger
    static let warmIvory = GamePalette.textPrimary

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
            .foregroundStyle(GamePalette.deep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, GameSpacing.large)
            .background(GamePalette.warning.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: GameRadius.button, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: GameMotion.normal, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(GameSpacing.large)
            .background(GamePalette.surface1.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: GameRadius.panel, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: GameRadius.panel, style: .continuous)
                    .stroke(GamePalette.borderSubtle, lineWidth: 1)
            }
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier()) }
}

private extension Color {
    var packedRGB: UInt {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            assertionFailure("GamePalette colors must resolve to sRGB")
            return 0
        }

        let redByte = UInt((red * 255).rounded())
        let greenByte = UInt((green * 255).rounded())
        let blueByte = UInt((blue * 255).rounded())
        return (redByte << 16) | (greenByte << 8) | blueByte
    }
}
