// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HWPXShared",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "HWPXShared", targets: ["HWPXShared"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.19"),
        .package(path: "../MarkdownShared")
    ],
    targets: [
        .target(
            name: "HWPXShared",
            dependencies: [
                "ZIPFoundation",
                "MarkdownShared"
            ]
        ),
        .testTarget(
            name: "HWPXSharedTests",
            dependencies: ["HWPXShared"],
            resources: [
                .copy("Fixtures")
            ]
        )
    ]
)
