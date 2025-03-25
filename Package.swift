// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ReviewHelper",
    defaultLocalization: .init(rawValue: "en"),
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "ReviewHelper",
            targets: ["ReviewHelper"]),
    ],
    targets: [
        .target(
            name: "ReviewHelper",
            resources:  [.process("Resources")]
        ),

    ]
)
