// swift-tools-version: 6.4
import PackageDescription

// The FitTracker backend. Run it from this folder with `swift run`, or open the folder in Xcode.
let package = Package(
    name: "Server",
    platforms: [
        .macOS(.v27)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.100.0"),
        // The shared API contract, as a local package.
        .package(path: "../FitTrackerAPI")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "FitTrackerAPI", package: "FitTrackerAPI")
            ]
        )
    ]
)
