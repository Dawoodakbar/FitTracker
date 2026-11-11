import Fluent
import FluentPostgresDriver
import FluentSQLiteDriver
import JWT
import Vapor

/// Sets up the application: listening address, database, migrations and routes.
///
/// - Parameter inMemoryDatabase: Tests pass `true` to use throwaway SQLite instead of Postgres.
func configure(_ app: Application, inMemoryDatabase: Bool = false) async throws {
    // Listen on all interfaces so the server also works inside a Docker container.
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    if inMemoryDatabase {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        // Defaults match docker-compose.yml; deployments override them with environment variables.
        app.databases.use(
            .postgres(configuration: SQLPostgresConfiguration(
                hostname: Environment.get("DATABASE_HOST") ?? "localhost",
                port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5432,
                username: Environment.get("DATABASE_USERNAME") ?? "fittracker",
                password: Environment.get("DATABASE_PASSWORD") ?? "fittracker",
                database: Environment.get("DATABASE_NAME") ?? "fittracker",
                tls: .disable
            )),
            as: .psql
        )
    }

    // Passwords: bcrypt is deliberately slow. Tests use the cheapest setting so they stay fast.
    app.passwords.use(.bcrypt(cost: app.environment == .testing ? 4 : 12))

    // Access tokens are signed with a secret that must stay private. Production refuses to start
    // without one, so a forgotten setting can't leave the server using a publicly known key.
    let secret = Environment.get("JWT_SECRET")
    if secret == nil, app.environment == .production {
        throw Abort(.internalServerError, reason: "JWT_SECRET must be set in production.")
    }
    await app.jwt.keys.add(hmac: HMACKey(from: secret ?? "development-only-secret-do-not-use"), digestAlgorithm: .sha256)

    // Order matters: each runs once, in this order.
    app.migrations.add(CreateWorkout())
    app.migrations.add(CreateHeartRateSample())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateRefreshToken())
    app.migrations.add(AddOwnerToWorkout())
    // Applies pending migrations on startup: convenient in development. A real deployment would
    // run `migrate` as a separate step instead, so a bad migration can't take the server down.
    try await app.autoMigrate()

    try routes(app)
}
