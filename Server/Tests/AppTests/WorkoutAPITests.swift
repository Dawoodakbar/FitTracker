import Foundation
import Testing
import VaporTesting
import FitTrackerAPI
@testable import App

/// The behaviours that matter most: uploads are safe to repeat, bad data is refused, and
/// nobody can see or change another user's workouts.
@Suite("Workouts API")
struct WorkoutAPITests {

    @Test("Uploading the same workout twice keeps one workout, with the latest data")
    func uploadIsIdempotent() async throws {
        try await withTestApp { app in
            let tokens = try await register(app, email: "a@example.com")
            let id = UUID()
            let first = makeWorkout(id: id, bpms: [100, 110, 120])
            let second = makeWorkout(id: id, bpms: [150, 160])

            for dto in [first, second, second] {
                try await app.testing().test(.PUT, "v1/workouts/\(id)", beforeRequest: { request in
                    request.headers.bearerAuthorization = .init(token: tokens.accessToken)
                    try request.content.encode(dto)
                }, afterResponse: { response async in
                    #expect(response.status == .ok)
                })
            }

            try await app.testing().test(.GET, "v1/workouts", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: tokens.accessToken)
            }, afterResponse: { response async throws in
                let workouts = try response.content.decode([WorkoutDTO].self)
                #expect(workouts.count == 1)
                #expect(workouts.first?.samples.map(\.bpm) == [150, 160])
            })
        }
    }

    @Test("Refuses a heart rate of 0 and a mismatched id, and stores nothing")
    func rejectsBadData() async throws {
        try await withTestApp { app in
            let tokens = try await register(app, email: "a@example.com")

            let invalid = makeWorkout(bpms: [100, 0])
            try await app.testing().test(.PUT, "v1/workouts/\(invalid.id)", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: tokens.accessToken)
                try request.content.encode(invalid)
            }, afterResponse: { response async in
                #expect(response.status == .unprocessableEntity)
            })

            let valid = makeWorkout(bpms: [100])
            try await app.testing().test(.PUT, "v1/workouts/\(UUID())", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: tokens.accessToken)
                try request.content.encode(valid)
            }, afterResponse: { response async in
                #expect(response.status == .badRequest)
            })

            try await app.testing().test(.GET, "v1/workouts", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: tokens.accessToken)
            }, afterResponse: { response async throws in
                #expect(try response.content.decode([WorkoutDTO].self).isEmpty)
            })
        }
    }

    @Test("Another user can't read, overwrite or delete your workout")
    func workoutsArePrivate() async throws {
        try await withTestApp { app in
            let alice = try await register(app, email: "alice@example.com")
            let bob = try await register(app, email: "bob@example.com")
            let aliceWorkout = makeWorkout(bpms: [120, 130])

            try await app.testing().test(.PUT, "v1/workouts/\(aliceWorkout.id)", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: alice.accessToken)
                try request.content.encode(aliceWorkout)
            }, afterResponse: { response async in
                #expect(response.status == .ok)
            })

            // Bob can't see it.
            try await app.testing().test(.GET, "v1/workouts", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: bob.accessToken)
            }, afterResponse: { response async throws in
                #expect(try response.content.decode([WorkoutDTO].self).isEmpty)
            })

            // Bob can't overwrite it by reusing its id.
            try await app.testing().test(.PUT, "v1/workouts/\(aliceWorkout.id)", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: bob.accessToken)
                try request.content.encode(makeWorkout(id: aliceWorkout.id, bpms: [90]))
            }, afterResponse: { response async in
                #expect(response.status == .conflict)
            })

            // Bob's delete does nothing.
            try await app.testing().test(.DELETE, "v1/workouts/\(aliceWorkout.id)", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: bob.accessToken)
            }, afterResponse: { _ async in })

            // Alice's workout is untouched.
            try await app.testing().test(.GET, "v1/workouts", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: alice.accessToken)
            }, afterResponse: { response async throws in
                let workouts = try response.content.decode([WorkoutDTO].self)
                #expect(workouts.map(\.id) == [aliceWorkout.id])
                #expect(workouts.first?.samples.map(\.bpm) == [120, 130])
            })
        }
    }

    @Test("Requests without a valid token are refused")
    func requiresToken() async throws {
        try await withTestApp { app in
            try await app.testing().test(.GET, "v1/workouts", afterResponse: { response async in
                #expect(response.status == .unauthorized)
            })
            try await app.testing().test(.GET, "v1/workouts", beforeRequest: { request in
                request.headers.bearerAuthorization = .init(token: "not-a-real-token")
            }, afterResponse: { response async in
                #expect(response.status == .unauthorized)
            })
        }
    }
}
