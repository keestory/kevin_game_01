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
            exclude: ["GameScene.swift"],
            sources: ["GameModels.swift", "GameRules.swift"]
        ),
        .testTarget(
            name: "GameCoreTests",
            dependencies: ["GameCore"],
            path: "AppStoreGameTests",
            exclude: ["GameRulesTests 2.swift"],
            sources: ["GameRulesTests.swift"]
        )
    ]
)
