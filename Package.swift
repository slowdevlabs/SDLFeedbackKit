// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SDLFeedbackKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SDLFeedbackKit",
            targets: ["SDLFeedbackKit"]
        )
    ],
    targets: [
        .target(
            name: "SDLFeedbackKit",
            resources: [
                .process("Localization/Resources")
            ]
        ),
        .testTarget(
            name: "SDLFeedbackKitTests",
            dependencies: ["SDLFeedbackKit"]
        )
    ]
)
