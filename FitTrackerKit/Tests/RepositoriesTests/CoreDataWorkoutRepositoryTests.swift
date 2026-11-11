import Foundation
import Testing
import Domain
@testable import Repositories

/// Behaviour specific to the Core Data repository, beyond the shared contract.
@Suite("Core Data workout repository")
struct CoreDataWorkoutRepositoryTests {

    @Test("Workouts saved to disk are still there when the app relaunches")
    func persistsAcrossInstances() async throws {
        // A fresh folder per test run, deleted afterwards, so runs never affect each other.
        let folder = URL.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appending(path: "Workouts.sqlite")

        let start = Date(timeIntervalSince1970: 1_000_000)
        let saved = try Workout(
            startDate: start,
            endDate: start.addingTimeInterval(1800),
            samples: [HeartRateSample(bpm: 140, date: start)]
        )

        // "First launch": save, then let the repository go away.
        do {
            let repository = try CoreDataWorkoutRepository(storeURL: storeURL)
            try await repository.save(saved)
        }

        // "Second launch": a brand-new repository reading the same file.
        let relaunched = try CoreDataWorkoutRepository(storeURL: storeURL)
        #expect(try await relaunched.workouts() == [saved])
    }
}
