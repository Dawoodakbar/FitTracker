/// Stores and loads workouts, hiding *where* they live (memory, Core Data, the server).
///
/// Features depend on this protocol; the App target injects a real implementation.
/// Every implementation must follow these rules:
/// - `save` with an existing `id` replaces that workout (never a duplicate), so retries are safe.
/// - `delete` of an unknown `id` does nothing.
/// - `workouts()` returns newest first, by `startDate`.
public protocol WorkoutRepository: Sendable {
    /// Inserts `workout`, or replaces the stored workout with the same `id`.
    func save(_ workout: Workout) async throws

    /// All stored workouts, newest first.
    func workouts() async throws -> [Workout]

    /// Removes the workout with `id`, if there is one.
    func delete(id: Workout.ID) async throws
}
