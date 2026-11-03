// swift-tools-version: 6.4
import PackageDescription

// Shared compiler settings for every target, so they don't drift apart
let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ApproachableConcurrency")
]

let package = Package(
    name: "FitTrackerKit",
    platforms: [
        .iOS(.v26),
        // Lets `swift test` run the pure-Swift modules on the Mac without a simulator.
        .macOS(.v26)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(name: "Domain", swiftSettings: swiftSettings),
        .target(name: "DesignSystem", swiftSettings: swiftSettings),
        // Fakes shared by test targets. Not a product, so it never ships in the app.
        .target(name: "TestSupport", dependencies: ["Domain"], swiftSettings: swiftSettings),
        .testTarget(
            name: "DomainTests",
            dependencies: ["Domain"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TestSupportTests",
            dependencies: ["TestSupport", "Domain"],
            swiftSettings: swiftSettings
        )
    ]
)
