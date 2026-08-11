// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "TempoApple",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "TempoCore", targets: ["TempoCore"]),
    ],
    targets: [
        .target(name: "TempoCore", path: "Sources/TempoCore"),
        .testTarget(
            name: "TempoCoreTests",
            dependencies: ["TempoCore"],
            path: "Tests/TempoCoreTests"
        ),
    ]
)
