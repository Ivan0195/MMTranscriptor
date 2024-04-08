// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MMTranscriptor",
    platforms: [
           .macOS(.v10_13), .iOS(.v16),
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MMTranscriptor",
            targets: ["MMTranscriptor"]),
    ],
    dependencies: [
            .package(url: "https://github.com/exPHAT/SwiftWhisper.git", revision: "deb1cb6a27256c7b01f5d3d2e7dc1dcc330b5d01"),
            .package(url: "https://github.com/AudioKit/AudioKit.git", branch: "main"),
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MMTranscriptor",
            dependencies: [.byName(name: "SwiftWhisper"), .byName(name: "AudioKit")]
            ),
    ]
)
