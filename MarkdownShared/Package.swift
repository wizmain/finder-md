// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MarkdownShared",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "MarkdownShared",
            targets: ["MarkdownShared"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "MarkdownShared",
            dependencies: [
                .product(name: "Markdown", package: "swift-markdown")
            ],
            resources: [
                .copy("Resources/template.html"),
                .copy("Resources/themes"),
                .copy("Resources/js"),
                .copy("Resources/css"),
                .copy("Resources/fonts")
            ]
        ),
        .testTarget(
            name: "MarkdownSharedTests",
            dependencies: ["MarkdownShared"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
