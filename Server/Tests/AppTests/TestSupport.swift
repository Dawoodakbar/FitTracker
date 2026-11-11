import Foundation
import Testing
import VaporTesting
import FitTrackerAPI
@testable import App

/// Runs `test` against a fresh app with an empty in-memory database.
func withTestApp(_ test: (Application) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app, inMemoryDatabase: true)
        try await test(app)
    } catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

/// Creates an account and returns its tokens.
func register(_ app: Application, email: String, password: String = "correct-horse-battery") async throws -> AuthResponse {
    var tokens: AuthResponse?
    try await app.testing().test(.POST, "v1/auth/register", beforeRequest: { request in
        try request.content.encode(Credentials(email: email, password: password))
    }, afterResponse: { response async throws in
        tokens = try response.content.decode(AuthResponse.self)
    })
    return try #require(tokens)
}

/// A workout starting at a fixed time, with one reading per entry in `bpms`.
func makeWorkout(id: UUID = UUID(), bpms: [Int]) -> WorkoutDTO {
    let start = Date(timeIntervalSince1970: 1_000_000)
    return WorkoutDTO(
        id: id,
        startDate: start,
        endDate: start.addingTimeInterval(600),
        samples: bpms.enumerated().map { index, bpm in
            HeartRateSampleDTO(id: UUID(), bpm: bpm, date: start.addingTimeInterval(Double(index * 10)))
        }
    )
}
