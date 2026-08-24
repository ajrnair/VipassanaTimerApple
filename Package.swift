// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VipassanaTimerApple",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "VipassanaCore", targets: ["VipassanaCore"])
    ],
    targets: [
        .target(
            name: "VipassanaCore",
            path: "VipassanaTimer",
            exclude: ["App", "Resources", "Services", "Views"],
            sources: ["Core"]
        ),
        .testTarget(
            name: "VipassanaCoreTests",
            dependencies: ["VipassanaCore"],
            path: "VipassanaTimerTests"
        )
    ]
)
