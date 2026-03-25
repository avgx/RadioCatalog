// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RadioCatalog",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library( name: "RadioCatalog", targets: ["RadioCatalog"] ),
        .executable(name: "radiocatalog-builder", targets: ["RadioCatalogBuilder"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RadioCatalog",
            dependencies: [
                "ZIPFoundation"
            ]
        ),
        .executableTarget(
            name: "RadioCatalogBuilder",
            dependencies: ["RadioCatalog"]
        ),
        .testTarget(
            name: "RadioCatalogTests",
            dependencies: ["RadioCatalog"],
            resources: [.process("Resources")] // Ensure this is present
        ),
        .testTarget(
            name: "RadioCatalogIntegrationTests",
            dependencies: ["RadioCatalog"],
        )
    ]
)
