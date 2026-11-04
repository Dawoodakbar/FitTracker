import Vapor

/// Sets up the application: listening address and routes. Databases and auth are added here later.
func configure(_ app: Application) async throws {
    // Listen on all interfaces so the server also works inside a Docker container.
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = Environment.get("PORT").flatMap(Int.init) ?? 8080

    try routes(app)
}
