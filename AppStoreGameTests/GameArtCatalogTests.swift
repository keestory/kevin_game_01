import SpriteKit
import UIKit
import XCTest

@testable import AppStoreGame

@MainActor
final class GameArtCatalogTests: XCTestCase {
    func testProductionCatalogContainsExactlyTenExpectedAssets() {
        XCTAssertEqual(GameArtAsset.allCases.count, 10)
        XCTAssertEqual(Set(GameArtAsset.allCases.map(\.rawValue)).count, 10)
        XCTAssertEqual(
            Set(GameArtAsset.allCases.map(\.rawValue)),
            [
                "RS_Playfield_Background",
                "RS_Brick_Material",
                "RS_Ball_Chrome",
                "RS_Paddle_Arcade",
                "RS_VFX_Lightning",
                "RS_VFX_Flame",
                "RS_VFX_Wind",
                "RS_VFX_Pierce",
                "RS_Logo_Wordmark",
                "RS_HUD_Frame"
            ]
        )
    }

    func testEveryCatalogImageLoadsAtExpectedPixelSize() throws {
        for asset in GameArtAsset.allCases {
            let image = try XCTUnwrap(
                UIImage(named: asset.rawValue),
                "Missing asset catalog image: \(asset.rawValue)"
            )
            let cgImage = try XCTUnwrap(image.cgImage)
            XCTAssertEqual(CGFloat(cgImage.width), asset.expectedPixelSize.width, asset.rawValue)
            XCTAssertEqual(CGFloat(cgImage.height), asset.expectedPixelSize.height, asset.rawValue)
        }
    }

    func testGameplayCropsStayNormalizedAndResolveToTextures() {
        let catalog = GameArtCatalog.shared
        let clippedAssets: [GameArtAsset] = [.brickMaterial, .ballChrome, .paddleArcade]

        for asset in clippedAssets {
            let crop = asset.gameplayCrop
            XCTAssertNotNil(crop)
            XCTAssertGreaterThanOrEqual(crop?.minX ?? -1, 0)
            XCTAssertGreaterThanOrEqual(crop?.minY ?? -1, 0)
            XCTAssertLessThanOrEqual(crop?.maxX ?? 2, 1)
            XCTAssertLessThanOrEqual(crop?.maxY ?? 2, 1)

            let texture = catalog.gameplayTexture(asset)
            XCTAssertGreaterThan(texture.size().width, 0)
            XCTAssertGreaterThan(texture.size().height, 0)
        }
    }

    func testEveryAttackKindHasDistinctAdditiveArtAndShowcaseArgument() {
        let catalog = GameArtCatalog.shared
        let arguments = ["lightning", "flame", "wind", "pierce"]
        let assets = AttackItemKind.allCases.map { catalog.attackAsset(for: $0) }

        XCTAssertEqual(Set(assets.map(\.rawValue)).count, AttackItemKind.allCases.count)
        XCTAssertTrue(assets.allSatisfy(\.usesAdditiveBlend))
        XCTAssertEqual(
            arguments.compactMap { catalog.attackKind(showcaseArgument: $0) },
            AttackItemKind.allCases
        )
        XCTAssertEqual(GameArtCatalog.maximumConcurrentAttackEffects, 8)
    }

    func testDescentOwnerSheetsKeepRealAlphaAndOnlyDocumentedGlowCropsOverlap() throws {
        let sheetNames = [
            "DB_Objects",
            "DB_BreakStates",
            "DB_SkillItems",
            "DB_SkillVFX",
            "DB_PlayerAttacks",
            "DB_HUD"
        ]
        for name in sheetNames {
            let image = try XCTUnwrap(UIImage(named: name), "Missing transparent owner sheet: \(name)")
            let cgImage = try XCTUnwrap(image.cgImage)
            switch cgImage.alphaInfo {
            case .none, .noneSkipFirst, .noneSkipLast:
                XCTFail("Owner sheet lost alpha channel: \(name)")
            default:
                break
            }
        }

        let objectCrops = DescentObjectKind.allCases.map { DescentArtCatalog.objectCrop(for: $0) }
        for crop in objectCrops {
            XCTAssertGreaterThanOrEqual(crop.minX, 0)
            XCTAssertGreaterThanOrEqual(crop.minY, 0)
            XCTAssertLessThanOrEqual(crop.maxX, 1)
            XCTAssertLessThanOrEqual(crop.maxY, 1)
        }
        let kinds = DescentObjectKind.allCases
        let documentedGlowOverlapPairs: Set<Set<DescentObjectKind>> = [
            [.spike, .brute],
            [.core, .brute]
        ]
        var actualOverlapPairs = Set<Set<DescentObjectKind>>()
        for leftIndex in objectCrops.indices {
            for rightIndex in objectCrops.indices where rightIndex > leftIndex {
                let left = objectCrops[leftIndex]
                let right = objectCrops[rightIndex]
                guard left.intersects(right) else { continue }
                let pair: Set<DescentObjectKind> = [kinds[leftIndex], kinds[rightIndex]]
                actualOverlapPairs.insert(pair)
                let intersection = left.intersection(right)
                let smallerArea = min(left.width * left.height, right.width * right.height)
                let overlapRatio = intersection.width * intersection.height / smallerArea
                XCTAssertLessThanOrEqual(
                    overlapRatio,
                    0.16,
                    "Documented glow overlap expanded into a neighboring sprite: \(pair)"
                )
            }
        }
        XCTAssertEqual(actualOverlapPairs, documentedGlowOverlapPairs)

        for kind in DescentSkillKind.allCases {
            let crop = DescentArtCatalog.skillCrop(for: kind)
            XCTAssertGreaterThanOrEqual(crop.minX, 0)
            XCTAssertGreaterThanOrEqual(crop.minY, 0)
            XCTAssertLessThanOrEqual(crop.maxX, 1)
            XCTAssertLessThanOrEqual(crop.maxY, 1)
            XCTAssertGreaterThan(DescentArtCatalog.skillTexture(for: kind).size().width, 0)
        }

        let shipCrops = DescentShipKind.allCases.map { DescentArtCatalog.shipCrop(for: $0) }
        let missileCrops = DescentMissileKind.allCases.map { DescentArtCatalog.missileCrop(for: $0) }
        for crop in shipCrops + missileCrops {
            XCTAssertGreaterThanOrEqual(crop.minX, 0)
            XCTAssertGreaterThanOrEqual(crop.minY, 0)
            XCTAssertLessThanOrEqual(crop.maxX, 1)
            XCTAssertLessThanOrEqual(crop.maxY, 1)
        }
        for ship in DescentShipKind.allCases {
            XCTAssertGreaterThan(DescentArtCatalog.playerTexture(for: ship).size().width, 0)
        }
        for missile in DescentMissileKind.allCases {
            XCTAssertGreaterThan(DescentArtCatalog.missileTexture(for: missile).size().height, 0)
        }
    }

    func testDescentGPTCombatSignatureAssetsLoadWithinAdditiveBudget() throws {
        let expectedSizes: [String: CGSize] = [
            "DB_VFX_ElectricImpact_R1": CGSize(width: 512, height: 512),
            "DB_VFX_WindBurst_R1": CGSize(width: 409, height: 512),
            "DB_VFX_PlayerAura_R1": CGSize(width: 512, height: 432)
        ]

        for (name, expectedSize) in expectedSizes {
            let image = try XCTUnwrap(UIImage(named: name), "Missing GPT combat signature asset: \(name)")
            let cgImage = try XCTUnwrap(image.cgImage)
            XCTAssertEqual(CGSize(width: cgImage.width, height: cgImage.height), expectedSize, name)
            XCTAssertLessThanOrEqual(cgImage.width, 512, name)
            XCTAssertLessThanOrEqual(cgImage.height, 512, name)
            switch cgImage.alphaInfo {
            case .none, .noneSkipFirst, .noneSkipLast:
                break
            default:
                XCTFail("Additive-ready asset unexpectedly changed alpha contract: \(name)")
            }
        }

        let aura = DescentArtCatalog.makeAdditiveSprite(
            texture: DescentArtCatalog.playerAuraTexture(),
            size: CGSize(width: 118, height: 72),
            zPosition: -2,
            alpha: 0.34
        )
        XCTAssertEqual(aura.blendMode, .add)
        XCTAssertEqual(aura.alpha, 0.34, accuracy: 0.001)
        XCTAssertGreaterThan(aura.texture?.size().width ?? 0, 0)
    }
}
