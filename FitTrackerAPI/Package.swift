// swift-tools-version: 6.4
import PackageDescription

// The API contract: plain Codable types shared by the iOS app and the Vapor server.
// It depends on nothing (not Domain, not Vapor), so both sides can use it freely.
let package = Package(
    name: "FitTrackerAPI",
    platforms: [
        .iOS(.v27),
        .macOS(.v27)
    ],
    products: [
        .library(name: "FitTrackerAPI", targets: ["FitTrackerAPI"])
    ],
    targets: [
        .target(name: "FitTrackerAPI")
    ]
)
