import Foundation
import Testing
import Domain
@testable import TestSupport

/// Specification for the `WorkoutRepository` contract, checked against the in-memory fake.
///
/// When the Core Data repository arrives, it must pass these same rules.
@Suite("In-memory workout repository")
struct InMemoryWorkoutRepositoryTests {

    let start = Date(timeIntervalSince1970: 1_000_000)

    /// A 30-minute workout starting `hours` after `start`.
    func workout(startingAfter hours: Double, id: UUID = UUID()) throws -> Workout {
        let startDate = start.addingTimeInterval(hours * 3600)
        return try Workout(id: id, startDate: startDate, endDate: startDate.addingTimeInterval(1800), samples: [])
    }

    // MARK: - Saving and listing

    @Test("A new repository is empty")
    func startsEmpty() async throws {
        let repository = InMemoryWorkoutRepository()

        #expect(try await repository.workouts().isEmpty)
    }

    @Test("Can start with existing workouts")
    func startsWithWorkouts() async throws {
        let saved = try workout(startingAfter: 0)
        let repository = InMemoryWorkoutRepository(workouts: [saved])

        #expect(try await repository.workouts() == [saved])
    }

    @Test("Lists saved workouts newest first")
    func listsNewestFirst() async throws {
        let repository = InMemoryWorkoutRepository()
        let oldest = try workout(startingAfter: 0)
        let newest = try workout(startingAfter: 2)
        let middle = try workout(startingAfter: 1)

        try await repository.save(oldest)
        try await repository.save(newest)
        try await repository.save(middle)

        #expect(try await repository.workouts() == [newest, middle, oldest])
    }

    @Test("Saving the same id again replaces the workout instead of duplicating it")
    func saveIsIdempotent() async throws {
        let repository = InMemoryWorkoutRepository()
        let id = UUID()
        let original = try workout(startingAfter: 0, id: id)
        let edited = try workout(startingAfter: 1, id: id)

        try await repository.save(original)
        try await repository.save(edited)

        #expect(try await repository.workouts() == [edited])
    }

    // MARK: - Deleting

    @Test("Deletes a workout by id")
    func deletes() async throws {
        let keep = try workout(startingAfter: 0)
        let remove = try workout(startingAfter: 1)
        let repository = InMemoryWorkoutRepository(workouts: [keep, remove])

        try await repository.delete(id: remove.id)

        #expect(try await repository.workouts() == [keep])
    }

    @Test("Deleting an unknown id does nothing")
    func deleteUnknownIsNoOp() async throws {
        let keep = try workout(startingAfter: 0)
        let repository = InMemoryWorkoutRepository(workouts: [keep])

        try await repository.delete(id: UUID())

        #expect(try await repository.workouts() == [keep])
    }

    // MARK: - Concurrency

    @Test("Many saves at the same time are all kept")
    func concurrentSaves() async throws {
        let repository = InMemoryWorkoutRepository()
        let workouts = try (0..<100).map { try workout(startingAfter: Double($0)) }

        // 100 child tasks call `save` at once. The actor runs them one at a time, so
        // none overwrite each other's changes.
        try await withThrowingTaskGroup { group in
            for workout in workouts {
                group.addTask { try await repository.save(workout) }
            }
            try await group.waitForAll()
        }

        #expect(try await repository.workouts().count == 100)
    }

    // MARK: - Simulating failures

    @Test("Throws the configured error from every operation, so callers can test error handling")
    func simulatesFailure() async throws {
        struct StorageFull: Error, Equatable {}
        let saved = try workout(startingAfter: 0)
        let repository = InMemoryWorkoutRepository(workouts: [saved])

        await repository.failNextCalls(with: StorageFull())

        await #expect(throws: StorageFull.self) { try await repository.workouts() }
        await #expect(throws: StorageFull.self) { try await repository.save(saved) }
        await #expect(throws: StorageFull.self) { try await repository.delete(id: saved.id) }
    }
}
