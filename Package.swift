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
        .library(name: "RadioCatalog", targets: ["RadioCatalog"]),
        .library(name: "TopRadioCatalog", targets: ["TopRadioCatalog"]),
        .executable(name: "radiocatalog-builder", targets: ["RadioCatalogBuilder"]),
        .executable(name: "topradiocatalog-builder", targets: ["TopRadioCatalogBuilder"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "RadioCatalog",
            dependencies: [
                "ZIPFoundation"
            ]
        ),
        .target(
            name: "TopRadioCatalog",
            dependencies: [
                "ZIPFoundation"
            ]
        ),
        .executableTarget(
            name: "RadioCatalogBuilder",
            dependencies: ["RadioCatalog"]
        ),
        .executableTarget(
            name: "TopRadioCatalogBuilder",
            dependencies: [
                "TopRadioCatalog",
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ]
        ),
        .testTarget(
            name: "RadioCatalogTests",
            dependencies: ["RadioCatalog"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "RadioCatalogIntegrationTests",
            dependencies: ["RadioCatalog"]
        ),
        .testTarget(
            name: "TopRadioCatalogTests",
            dependencies: [
                "TopRadioCatalog",
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            exclude: [
                "cities.json",
                "cityStations.json",
                "countries.json",
                "cstations.json",
                "genres.json",
                "links.json",
                "rating.json",
                "stations.json",
                "streams.json",
                "tr-stations.json",
                "webStations.json",
                "tr-stations.json"
            ]
        )
    ]
)
