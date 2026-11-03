// swift-tools-version: 6.4
import PackageDescription

// Shared compiler settings for every target, so they don't drift apart
let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ApproachableConcurrency")
]

let package = Package(
    name: "FitTrackerKit",
    platforms: [
        // Matches the app's deployment target, so SDK 27 APIs need no availability checks.
        .iOS(.v27),
        // Lets `swift test` run the pure-Swift modules on the Mac without a simulator.
        .macOS(.v27)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "HistoryFeature", targets: ["HistoryFeature"]),
        .library(name: "WorkoutFeature", targets: ["WorkoutFeature"]),
        .library(name: "Repositories", targets: ["Repositories"]),
        .library(name: "Sensors", targets: ["Sensors"])
    ],
    targets: [
        .target(name: "Domain", swiftSettings: swiftSettings),
        .target(name: "DesignSystem", swiftSettings: swiftSettings),
        // How Domain concepts look on screen (zone colours and names), shared by features.
        .target(
            name: "ZonePresentation",
            dependencies: ["Domain", "DesignSystem"],
            swiftSettings: swiftSettings
        ),
        // Features see Domain protocols and DesignSystem, never storage, sensors or networking.
        .target(
            name: "HistoryFeature",
            dependencies: ["Domain", "DesignSystem", "ZonePresentation"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "WorkoutFeature",
            dependencies: ["Domain", "DesignSystem", "ZonePresentation"],
            swiftSettings: swiftSettings
        ),
        // Infrastructure: the Core Data stack. Knows nothing about Domain.
        .target(name: "Persistence", swiftSettings: swiftSettings),
        // Implements Domain's repository protocols on top of infrastructure, mapping between them.
        .target(
            name: "Repositories",
            dependencies: ["Domain", "Persistence"],
            swiftSettings: swiftSettings
        ),
        // Implements Domain's `HeartRateSource`: simulated now, Bluetooth later.
        .target(name: "Sensors", dependencies: ["Domain"], swiftSettings: swiftSettings),
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
        ),
        .testTarget(
            name: "RepositoriesTests",
            dependencies: ["Repositories", "Domain", "TestSupport"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SensorsTests",
            dependencies: ["Sensors", "Domain"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "HistoryFeatureTests",
            dependencies: ["HistoryFeature", "Domain", "TestSupport"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WorkoutFeatureTests",
            dependencies: ["WorkoutFeature", "Domain", "TestSupport"],
            swiftSettings: swiftSettings
        )
    ]
)
