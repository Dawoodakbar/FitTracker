import CoreData
import Domain
import Persistence

/// A `WorkoutRepository` that stores workouts in Core Data (SQLite on disk).
///
/// Every operation gets its own background context and does all Core Data work inside
/// `perform`, so the caller's thread is never blocked and managed objects never escape.
/// Only Domain values (`Workout`) cross the `await`.
public final class CoreDataWorkoutRepository: WorkoutRepository {
    private let store: WorkoutStore

    /// Opens (or creates) the store at `storeURL`.
    public init(storeURL: URL) throws {
        store = try WorkoutStore(storeURL: storeURL)
    }

    private init(store: WorkoutStore) {
        self.store = store
    }

    /// A repository backed by a throwaway store, for tests and previews.
    public static func inMemory() throws -> CoreDataWorkoutRepository {
        CoreDataWorkoutRepository(store: try WorkoutStore(storeURL: nil))
    }

    /// The default on-disk location: the app's Application Support folder.
    public static func defaultStoreURL() -> URL {
        URL.applicationSupportDirectory.appending(path: "Workouts.sqlite")
    }

    // MARK: - WorkoutRepository

    public func save(_ workout: Workout) async throws {
        let context = store.newBackgroundContext()
        try await context.perform {
            // Upsert: update the existing row for this id, or insert a new one.
            let entity = try context.fetch(WorkoutEntity.fetchRequest(id: workout.id)).first
                ?? WorkoutEntity(context: context)
            entity.update(from: workout, in: context)
            try context.save()
        }
    }

    public func workouts() async throws -> [Workout] {
        let context = store.newBackgroundContext()
        let workouts = try await context.perform {
            try context.fetch(WorkoutEntity.fetchRequest()).map { try $0.toDomain() }
        }
        // Same order as every other implementation: newest first, ties broken by id.
        return workouts.sorted {
            ($0.startDate, $0.id.uuidString) > ($1.startDate, $1.id.uuidString)
        }
    }

    public func delete(id: Workout.ID) async throws {
        let context = store.newBackgroundContext()
        try await context.perform {
            guard let entity = try context.fetch(WorkoutEntity.fetchRequest(id: id)).first else {
                return   // unknown id: nothing to do
            }
            context.delete(entity)   // cascade deletes its samples
            try context.save()
        }
    }
}
