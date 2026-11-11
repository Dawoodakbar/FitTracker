import Fluent
import Vapor
import FitTrackerAPI

/// `/v1/workouts`: upload, list and delete workouts.
struct WorkoutController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        // Every workout route requires a signed-in user.
        let workouts = routes.grouped("v1", "workouts").grouped(AccessTokenMiddleware())
        workouts.get(use: list)
        workouts.group(":id") { workout in
            workout.put(use: upsert)
            workout.delete(use: remove)
        }
    }

    /// `GET /v1/workouts?limit=50`: newest first. (Cursor paging comes with sync.)
    func list(req: Request) async throws -> [WorkoutDTO] {
        let userID = try req.auth.require(AuthenticatedUser.self).id
        let limit = min(max(req.query[Int.self, at: "limit"] ?? 50, 1), 200)
        let workouts = try await WorkoutModel.query(on: req.db)
            .filter(\.$userID == userID)
            .with(\.$samples)
            .sort(\.$startDate, .descending)
            .limit(limit)
            .all()
        return workouts.map(\.dto)
    }

    /// `PUT /v1/workouts/:id`: creates the workout, or replaces it if the id already exists.
    /// Sending the same request twice leaves the same result, so the app can retry safely.
    func upsert(req: Request) async throws -> WorkoutDTO {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "The workout id in the URL isn't a valid UUID.")
        }
        let userID = try req.auth.require(AuthenticatedUser.self).id
        let dto = try req.content.decode(WorkoutDTO.self)
        guard dto.id == id else {
            throw Abort(.badRequest, reason: "The workout id in the URL and in the body must match.")
        }
        if let problem = dto.validationProblem {
            throw Abort(.unprocessableEntity, reason: problem)
        }

        // One transaction: either the whole workout is replaced or nothing changes.
        try await req.db.transaction { database in
            if let existing = try await WorkoutModel.find(id, on: database) {
                // The id is taken by someone else's workout: never overwrite another user's data.
                guard existing.userID == userID else {
                    throw Abort(.conflict, reason: "This workout id is already in use.")
                }
                try await HeartRateSampleModel.query(on: database).filter(\.$workout.$id == id).delete()
                existing.startDate = dto.startDate
                existing.endDate = dto.endDate
                try await existing.update(on: database)
            } else {
                try await WorkoutModel(dto, userID: userID).create(on: database)
            }
            try await dto.samples.map { HeartRateSampleModel($0, workoutID: id) }.create(on: database)
        }
        return dto
    }

    /// `DELETE /v1/workouts/:id`: removes the workout. Deleting one that's already gone also succeeds.
    func remove(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "The workout id in the URL isn't a valid UUID.")
        }
        let userID = try req.auth.require(AuthenticatedUser.self).id
        // Filtering on the owner means deleting someone else's workout quietly does nothing.
        try await WorkoutModel.query(on: req.db).filter(\.$id == id).filter(\.$userID == userID).delete()
        return .noContent
    }
}

extension WorkoutDTO: Content {}

extension WorkoutDTO {
    /// The same rules as the app's Domain, enforced again here because a server can't trust its clients.
    var validationProblem: String? {
        guard startDate <= endDate else { return "The workout can't end before it starts." }
        for sample in samples {
            guard (1...300).contains(sample.bpm) else {
                return "Heart rate must be between 1 and 300 BPM."
            }
            guard (startDate...endDate).contains(sample.date) else {
                return "Every sample must fall inside the workout's start and end time."
            }
        }
        return nil
    }
}
