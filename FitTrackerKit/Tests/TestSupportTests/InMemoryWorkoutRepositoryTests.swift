import Foundation
import Testing
import Domain
@testable import TestSupport

/// Behaviour specific to the in-memory fake. The shared `WorkoutRepository` rules live in
/// `RepositoriesTests/WorkoutRepositoryContractTests`, which run against every implementation.
@Suite("In-memory workout repository")
struct InMemoryWorkoutRepositoryTests {

    let start = Date(timeIntervalSince1970: 1_000_000)

    func workout() throws -> Workout {
        try Workout(startDate: start, endDate: start.addingTimeInterval(1800), samples: [])
    }

    @Test("Can start with existing workouts")
    func startsWithWorkouts() async throws {
        let saved = try workout()
        let repository = InMemoryWorkoutRepository(workouts: [saved])

        #expect(try await repository.workouts() == [saved])
    }

    @Test("Throws the configured error from every operation, so callers can test error handling")
    func simulatesFailure() async throws {
        struct StorageFull: Error, Equatable {}
        let saved = try workout()
        let repository = InMemoryWorkoutRepository(workouts: [saved])

        await repository.failNextCalls(with: StorageFull())

        await #expect(throws: StorageFull.self) { try await repository.workouts() }
        await #expect(throws: StorageFull.self) { try await repository.save(saved) }
        await #expect(throws: StorageFull.self) { try await repository.delete(id: saved.id) }
    }
}
