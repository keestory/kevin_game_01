// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReturnShotGameCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GameCore", targets: ["GameCore"])
    ],
    targets: [
        .target(
            name: "GameCore",
            path: "AppStoreGame/Game",
            exclude: [
                "GameScene.swift",
                "DescentGameScene.swift",
                "DescentArtCatalog.swift",
                "GameArtCatalog.swift"
            ],
            sources: [
                "GameModels.swift",
                "GameRules.swift",
                "DescentModels.swift",
                "DescentRules.swift"
            ]
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            path: "AppStoreGameTests",
            exclude: [
                "GameRulesTests 2.swift",
                "DescentResearchAnalyticsTests.swift",
                "DescentResearchReportTests.swift",
                "GameArtCatalogTests.swift"
            ],
            sources: ["GameRulesTests.swift", "DescentRulesTests.swift"]
        )
    ]
)
