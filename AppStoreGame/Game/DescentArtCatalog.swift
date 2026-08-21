import SpriteKit

/// Presentation-only adapter for the owner-provided Descent Breaker sprite sheets.
/// Gameplay geometry remains authoritative in `DescentRules`.
@MainActor
enum DescentArtCatalog {
    private static let objectSheet = SKTexture(imageNamed: "DB_Objects")
    private static let skillSheet = SKTexture(imageNamed: "DB_SkillItems")
    private static let skillVFXSheet = SKTexture(imageNamed: "DB_SkillVFX")
    private static let playerAttackSheet = SKTexture(imageNamed: "DB_PlayerAttacks")
    private static let electricImpact = configuredTexture(named: "DB_VFX_ElectricImpact_R1")
    private static let windBurst = configuredTexture(named: "DB_VFX_WindBurst_R1")
    private static let playerAura = configuredTexture(named: "DB_VFX_PlayerAura_R1")
    private static let sheetPixelSize = CGSize(width: 1_448, height: 1_086)

    static func objectTexture(for kind: DescentObjectKind) -> SKTexture {
        texture(in: objectSheet, topLeftCrop: objectCrop(for: kind))
    }

    static func playerTexture(for ship: DescentShipKind) -> SKTexture {
        texture(in: playerAttackSheet, topLeftCrop: shipCrop(for: ship))
    }

    static func missileTexture(for missile: DescentMissileKind) -> SKTexture {
        texture(in: playerAttackSheet, topLeftCrop: missileCrop(for: missile))
    }

    static func skillTexture(for kind: DescentSkillKind) -> SKTexture {
        texture(in: skillSheet, topLeftCrop: skillCrop(for: kind))
    }

    static func skillVFXTexture(for kind: DescentSkillKind) -> SKTexture {
        switch kind {
        case .electric:
            electricImpact
        case .wind:
            windBurst
        default:
            texture(in: skillVFXSheet, topLeftCrop: skillVFXCrop(for: kind))
        }
    }

    static func playerAuraTexture() -> SKTexture {
        playerAura
    }

    static func makeSprite(texture: SKTexture, size: CGSize, zPosition: CGFloat) -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: texture, color: .white, size: size)
        sprite.zPosition = zPosition
        return sprite
    }

    static func makeAdditiveSprite(
        texture: SKTexture,
        size: CGSize,
        zPosition: CGFloat,
        alpha: CGFloat
    ) -> SKSpriteNode {
        let sprite = makeSprite(texture: texture, size: size, zPosition: zPosition)
        sprite.blendMode = .add
        sprite.alpha = alpha
        return sprite
    }

    /// Normalized crop rectangles use a top-left origin so SwiftUI previews and SpriteKit
    /// consume the same owner-authored atlas boundaries. The supplied sheets are not equal
    /// grids: several glows and silhouettes cross the mathematical quarter-cell lines.
    static func objectCrop(for kind: DescentObjectKind) -> CGRect {
        let pixels: CGRect = switch kind {
        case .normal: CGRect(x: 10, y: 40, width: 360, height: 445)
        case .armored: CGRect(x: 375, y: 55, width: 339, height: 430)
        case .spike: CGRect(x: 716, y: 40, width: 358, height: 460)
        case .drone: CGRect(x: 1_076, y: 100, width: 372, height: 390)
        case .core: CGRect(x: 0, y: 490, width: 385, height: 540)
        case .brute: CGRect(x: 330, y: 490, width: 470, height: 596)
        }
        return normalizedTopLeftRect(pixels)
    }

    static func shipCrop(for ship: DescentShipKind) -> CGRect {
        let pixels: CGRect = switch ship {
        case .interceptor: CGRect(x: 80, y: 60, width: 330, height: 390)
        case .striker: CGRect(x: 405, y: 30, width: 370, height: 430)
        case .guardian: CGRect(x: 785, y: 0, width: 530, height: 470)
        }
        return normalizedTopLeftRect(pixels)
    }

    static func missileCrop(for missile: DescentMissileKind) -> CGRect {
        let pixels: CGRect = switch missile {
        case .pulse: CGRect(x: 34, y: 450, width: 160, height: 310)
        case .lance: CGRect(x: 580, y: 390, width: 220, height: 340)
        // Render one rocket per authoritative lane. Cropping the complete three-rocket
        // cluster here would make the guardian's three-lane volley look like nine shots.
        case .salvo: CGRect(x: 1_270, y: 425, width: 100, height: 330)
        }
        return normalizedTopLeftRect(pixels)
    }

    static func skillCrop(for kind: DescentSkillKind) -> CGRect {
        let pixels: CGRect = switch kind {
        case .fire: CGRect(x: 0, y: 0, width: 362, height: 360)
        case .electric: CGRect(x: 362, y: 0, width: 362, height: 360)
        case .pierce: CGRect(x: 724, y: 0, width: 362, height: 360)
        case .wind: CGRect(x: 1_086, y: 0, width: 362, height: 360)
        case .explosion: CGRect(x: 0, y: 366, width: 362, height: 358)
        }
        return normalizedTopLeftRect(pixels)
    }

    private static func skillVFXCrop(for kind: DescentSkillKind) -> CGRect {
        let pixels: CGRect = switch kind {
        case .fire: CGRect(x: 0, y: 0, width: 330, height: 543)
        case .electric: CGRect(x: 330, y: 0, width: 370, height: 543)
        case .pierce: CGRect(x: 700, y: 0, width: 360, height: 543)
        case .wind: CGRect(x: 1_060, y: 0, width: 388, height: 543)
        case .explosion: CGRect(x: 0, y: 543, width: 362, height: 543)
        }
        return normalizedTopLeftRect(pixels)
    }

    private static func normalizedTopLeftRect(_ pixels: CGRect) -> CGRect {
        CGRect(
            x: pixels.minX / sheetPixelSize.width,
            y: pixels.minY / sheetPixelSize.height,
            width: pixels.width / sheetPixelSize.width,
            height: pixels.height / sheetPixelSize.height
        )
    }

    private static func texture(in sheet: SKTexture, topLeftCrop: CGRect) -> SKTexture {
        let spriteKitRect = CGRect(
            x: topLeftCrop.minX,
            y: 1 - topLeftCrop.maxY,
            width: topLeftCrop.width,
            height: topLeftCrop.height
        )
        return SKTexture(rect: spriteKitRect, in: sheet)
    }

    private static func configuredTexture(named name: String) -> SKTexture {
        let texture = SKTexture(imageNamed: name)
        texture.filteringMode = .linear
        texture.usesMipmaps = false
        return texture
    }

}
