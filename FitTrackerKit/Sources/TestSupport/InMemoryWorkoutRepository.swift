import Domain

/// A **fake** `WorkoutRepository`: a real, working implementation that keeps workouts in memory.
///
/// Use it in tests and SwiftUI previews instead of a database. It's an `actor`, so many tasks
/// can call it at once without corrupting `storage`.
public actor InMemoryWorkoutRepository: WorkoutRepository {
    /// Keyed by id, which makes "save replaces an existing id" automatic.
    private var storage: [Workout.ID: Workout]
    /// When set, every call throws it. Lets tests check how callers handle failures.
    private var failure: (any Error)?

    public init(workouts: [Workout] = []) {
        storage = Dictionary(workouts.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
    }

    /// Makes every following call throw `error`, until called again with `nil`.
    public func failNextCalls(with error: (any Error)?) {
        failure = error
    }

    // MARK: - WorkoutRepository

    public func save(_ workout: Workout) throws {
        try throwIfFailing()
        storage[workout.id] = workout
    }

    public func workouts() throws -> [Workout] {
        try throwIfFailing()
        // Dictionaries have no order. Sort newest first, then by id so equal start dates
        // still come back in the same order every time.
        return storage.values.sorted {
            ($0.startDate, $0.id.uuidString) > ($1.startDate, $1.id.uuidString)
        }
    }

    public func delete(id: Workout.ID) throws {
        try throwIfFailing()
        storage[id] = nil
    }

    // MARK: - Private

    private func throwIfFailing() throws {
        if let failure { throw failure }
    }
}
