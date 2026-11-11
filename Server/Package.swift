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
        // Fluent is Vapor's database layer; each database has its own driver.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // JSON Web Tokens for access tokens, and swift-crypto for hashing refresh tokens.
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        // SQLite runs in memory, which keeps tests fast and free of any external database.
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.6.0"),
        // The shared API contract, as a local package.
        .package(path: "../FitTrackerAPI")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "FitTrackerAPI", package: "FitTrackerAPI")
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
                .product(name: "VaporTesting", package: "vapor")
            ]
        )
    ]
)
