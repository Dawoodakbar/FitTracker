import Foundation
import Testing
import Domain
import TestSupport
@testable import Repositories

/// Every `WorkoutRepository` implementation, so each rule below runs against all of them.
/// Add a case here when a new implementation (e.g. a network repository) arrives.
enum RepositoryKind: CaseIterable, Sendable, CustomTestStringConvertible {
    case inMemory
    case coreData

    func make() throws -> any WorkoutRepository {
        switch self {
        case .inMemory: InMemoryWorkoutRepository()
        case .coreData: try CoreDataWorkoutRepository.inMemory()
        }
    }

    /// The name shown for each test case in the Test navigator.
    var testDescription: String {
        switch self {
        case .inMemory: "in-memory fake"
        case .coreData: "Core Data"
        }
    }
}

/// The `WorkoutRepository` contract. The protocol's doc comment states the rules; these
/// tests enforce them for every implementation.
@Suite("WorkoutRepository contract")
struct WorkoutRepositoryContractTests {

    let start = Date(timeIntervalSince1970: 1_000_000)

    /// A 30-minute workout starting `hours` after `start`, with two samples.
    func workout(startingAfter hours: Double, id: UUID = UUID()) throws -> Workout {
        let startDate = start.addingTimeInterval(hours * 3600)
        return try Workout(
            id: id,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(1800),
            samples: [
                HeartRateSample(bpm: 120, date: startDate),
                HeartRateSample(bpm: 160, date: startDate.addingTimeInterval(600))
            ]
        )
    }

    // MARK: - Saving and listing

    @Test("A new repository is empty", arguments: RepositoryKind.allCases)
    func startsEmpty(kind: RepositoryKind) async throws {
        let repository = try kind.make()

        #expect(try await repository.workouts().isEmpty)
    }

    @Test("Round-trips every field, including samples", arguments: RepositoryKind.allCases)
    func roundTrips(kind: RepositoryKind) async throws {
        let repository = try kind.make()
        let saved = try workout(startingAfter: 0)

        try await repository.save(saved)

        #expect(try await repository.workouts() == [saved])
    }

    @Test("Lists saved workouts newest first", arguments: RepositoryKind.allCases)
    func listsNewestFirst(kind: RepositoryKind) async throws {
        let repository = try kind.make()
        let oldest = try workout(startingAfter: 0)
        let newest = try workout(startingAfter: 2)
        let middle = try workout(startingAfter: 1)

        try await repository.save(oldest)
        try await repository.save(newest)
        try await repository.save(middle)

        #expect(try await repository.workouts() == [newest, middle, oldest])
    }

    @Test("Saving the same id again replaces the workout", arguments: RepositoryKind.allCases)
    func saveIsIdempotent(kind: RepositoryKind) async throws {
        let repository = try kind.make()
        let id = UUID()
        let original = try workout(startingAfter: 0, id: id)
        let edited = try workout(startingAfter: 1, id: id)

        try await repository.save(original)
        try await repository.save(edited)

        #expect(try await repository.workouts() == [edited])
    }

    // MARK: - Deleting

    @Test("Deletes a workout by id", arguments: RepositoryKind.allCases)
    func deletes(kind: RepositoryKind) async throws {
        let repository = try kind.make()
        let keep = try workout(startingAfter: 0)
        let remove = try workout(startingAfter: 1)
        try await repository.save(keep)
        try await repository.save(remove)

        try await repository.delete(id: remove.id)

        #expect(try await repository.workouts() == [keep])
    }

    @Test("Deleting an unknown id does nothing", arguments: RepositoryKind.allCases)
    func deleteUnknownIsNoOp(kind: RepositoryKind) async throws {
        let repository = try kind.make()
        let keep = try workout(startingAfter: 0)
        try await repository.save(keep)

        try await repository.delete(id: UUID())

        #expect(try await repository.workouts() == [keep])
    }

    // MARK: - Concurrency

    @Test("Many saves at the same time are all kept", arguments: RepositoryKind.allCases)
    func concurrentSaves(kind: RepositoryKind) async throws {
        let repository = try kind.make()
        let workouts = try (0..<50).map { try workout(startingAfter: Double($0)) }

        try await withThrowingTaskGroup { group in
            for workout in workouts {
                group.addTask { try await repository.save(workout) }
            }
            try await group.waitForAll()
        }

        #expect(try await repository.workouts().count == 50)
    }
}
