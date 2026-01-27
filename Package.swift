// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpacesRenamer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SpacesRenamerCore", targets: ["SpacesRenamerCore"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "SpacesRenamerApp",
            dependencies: ["SpacesRenamerCore"]),
        .target(
            name: "SpacesRenamerCore"),
        .testTarget(
            name: "SpacesRenamerCoreTests",
            dependencies: ["SpacesRenamerCore"])
    ]
)
