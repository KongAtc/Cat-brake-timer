// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CatBreakTimer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "CatBreakTimerCore", targets: ["CatBreakTimerCore"]),
        .executable(name: "CatBreakTimer", targets: ["CatBreakTimer"])
    ],
    targets: [
        .target(name: "CatBreakTimerCore"),
        .executableTarget(
            name: "CatBreakTimer",
            dependencies: ["CatBreakTimerCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "CatBreakTimerCoreTests",
            dependencies: ["CatBreakTimerCore"]
        )
    ]
)
