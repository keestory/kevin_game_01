import SpriteKit
import UIKit

enum GameArtAsset: String, CaseIterable {
    case playfieldBackground = "RS_Playfield_Background"
    case brickMaterial = "RS_Brick_Material"
    case ballChrome = "RS_Ball_Chrome"
    case paddleArcade = "RS_Paddle_Arcade"
    case vfxLightning = "RS_VFX_Lightning"
    case vfxFlame = "RS_VFX_Flame"
    case vfxWind = "RS_VFX_Wind"
    case vfxPierce = "RS_VFX_Pierce"
    case logoWordmark = "RS_Logo_Wordmark"
    case hudFrame = "RS_HUD_Frame"

    var expectedPixelSize: CGSize {
        switch self {
        case .playfieldBackground: CGSize(width: 841, height: 1_870)
        case .brickMaterial: CGSize(width: 512, height: 227)
        case .ballChrome: CGSize(width: 256, height: 256)
        case .paddleArcade: CGSize(width: 512, height: 256)
        case .vfxLightning, .vfxFlame, .vfxWind, .vfxPierce:
            CGSize(width: 512, height: 512)
        case .logoWordmark: CGSize(width: 1_024, height: 512)
        case .hudFrame: CGSize(width: 1_024, height: 426)
        }
    }

    /// Normalized SpriteKit coordinates. The source art has an opaque matte, so
    /// gameplay silhouettes use a tight subtexture and an SKShapeNode as the clip.
    var gameplayCrop: CGRect? {
        switch self {
        case .brickMaterial:
            CGRect(x: 0.22, y: 0.06, width: 0.56, height: 0.88)
        case .ballChrome:
            CGRect(x: 0.16, y: 0.16, width: 0.68, height: 0.68)
        case .paddleArcade:
            CGRect(x: 0.08, y: 0.28, width: 0.84, height: 0.44)
        default:
            nil
        }
    }

    var usesAdditiveBlend: Bool {
        switch self {
        case .vfxLightning, .vfxFlame, .vfxWind, .vfxPierce:
            true
        default:
            false
        }
    }
}

@MainActor
final class GameArtCatalog {
    static let shared = GameArtCatalog()
    static let maximumConcurrentAttackEffects = 8

    private var sourceTextures: [GameArtAsset: SKTexture] = [:]
    private var croppedTextures: [GameArtAsset: SKTexture] = [:]

    private init() {}

    func texture(_ asset: GameArtAsset) -> SKTexture {
        if let cached = sourceTextures[asset] {
            return cached
        }

        let texture = SKTexture(imageNamed: asset.rawValue)
        texture.filteringMode = .linear
        texture.usesMipmaps = false
        sourceTextures[asset] = texture
        return texture
    }

    func gameplayTexture(_ asset: GameArtAsset) -> SKTexture {
        guard let crop = asset.gameplayCrop else {
            return texture(asset)
        }
        if let cached = croppedTextures[asset] {
            return cached
        }

        let cropped = SKTexture(rect: crop, in: texture(asset))
        cropped.filteringMode = .linear
        cropped.usesMipmaps = false
        croppedTextures[asset] = cropped
        return cropped
    }

    func attackTexture(for kind: AttackItemKind) -> SKTexture {
        texture(attackAsset(for: kind))
    }

    func attackAsset(for kind: AttackItemKind) -> GameArtAsset {
        switch kind {
        case .lightning: .vfxLightning
        case .flame: .vfxFlame
        case .wind: .vfxWind
        case .pierce: .vfxPierce
        }
    }

    func preload() {
        let originals = GameArtAsset.allCases.map(texture)
        let crops = GameArtAsset.allCases.compactMap { asset in
            asset.gameplayCrop == nil ? nil : gameplayTexture(asset)
        }
        SKTexture.preload(originals + crops) {}
    }

    func attackKind(showcaseArgument: String) -> AttackItemKind? {
        switch showcaseArgument.lowercased() {
        case "lightning": .lightning
        case "flame": .flame
        case "wind": .wind
        case "pierce": .pierce
        default: nil
        }
    }
}
