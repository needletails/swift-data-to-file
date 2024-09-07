// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-data-to-file",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftDTF",
            targets: ["SwiftDTF"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", .upToNextMajor(from: "2.65.0")),
        .package(url: "git@github.com:needle-tail/needletail-media-kit.git", .upToNextMajor(from: "1.0.6")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftDTF",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NeedletailMediaKit", package: "needletail-media-kit")
            ]
        ),
        .testTarget(
            name: "swift-dtfTests",
            dependencies: ["SwiftDTF"]),
    ]
)
