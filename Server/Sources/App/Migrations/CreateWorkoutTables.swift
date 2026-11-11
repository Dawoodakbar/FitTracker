import Fluent

/// A migration changes the database structure and runs once, in order. Never edit one that has
/// been applied: add a new migration instead, so every database ends up in the same shape.
struct CreateWorkout: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("workouts")
            .id()
            .field("start_date", .datetime, .required)
            .field("end_date", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("workouts").delete()
    }
}

struct CreateHeartRateSample: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("heart_rate_samples")
            .id()
            // Deleting a workout deletes its samples, like the cascade rule in the app's Core Data model.
            .field("workout_id", .uuid, .required, .references("workouts", "id", onDelete: .cascade))
            .field("bpm", .int, .required)
            .field("date", .datetime, .required)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("heart_rate_samples").delete()
    }
}
