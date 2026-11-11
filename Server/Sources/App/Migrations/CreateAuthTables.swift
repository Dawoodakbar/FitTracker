import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            // The database itself refuses duplicate emails, even if two sign-ups race.
            .unique(on: "email")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}

struct CreateRefreshToken: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field("user_id", .uuid, .required)
            .field("token_hash", .string, .required)
            .field("expires_at", .datetime, .required)
            .unique(on: "token_hash")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}

/// Gives every workout an owner. The column is nullable because the table may already hold
/// rows from before accounts existed. Those have no owner, so no one can see them.
struct AddOwnerToWorkout: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("workouts")
            .field("user_id", .uuid)
            .update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("workouts")
            .deleteField("user_id")
            .update()
    }
}
