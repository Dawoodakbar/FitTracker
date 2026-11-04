import Vapor
import FitTrackerAPI

/// All HTTP routes. The API is versioned under `/v1`, so a future breaking change can ship
/// as `/v2` while old app versions keep working.
func routes(_ app: Application) throws {
    // Used by load balancers and Docker to check that the server is alive.
    app.get("health") { _ in
        HealthDTO(status: "ok")
    }
}

// Lets a `HealthDTO` be returned directly from a route handler: Vapor encodes it as JSON.
extension HealthDTO: Content {}
