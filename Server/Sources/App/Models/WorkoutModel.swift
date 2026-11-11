import Fluent
import Vapor
import FitTrackerAPI

/// A workout row in the `workouts` table. Its id is created by the app, which is what makes
/// uploads safe to repeat: the same workout always lands on the same row.
final class WorkoutModel: Model, @unchecked Sendable {
    static let schema = "workouts"

    @ID(key: .id) var id: UUID?
    @Field(key: "start_date") var startDate: Date
    @Field(key: "end_date") var endDate: Date
    /// The account that owns this workout. Every query filters on it.
    @OptionalField(key: "user_id") var userID: UUID?
    @Children(for: \.$workout) var samples: [HeartRateSampleModel]

    init() {}

    init(id: UUID, userID: UUID, startDate: Date, endDate: Date) {
        self.id = id
        self.userID = userID
        self.startDate = startDate
        self.endDate = endDate
    }

    convenience init(_ dto: WorkoutDTO, userID: UUID) {
        self.init(id: dto.id, userID: userID, startDate: dto.startDate, endDate: dto.endDate)
    }

    /// The wire format. `samples` must be loaded first (`.with(\.$samples)`).
    var dto: WorkoutDTO {
        WorkoutDTO(
            id: id ?? UUID(),
            startDate: startDate,
            endDate: endDate,
            samples: samples.sorted { $0.date < $1.date }.map(\.dto)
        )
    }
}

/// A reading in the `heart_rate_samples` table, owned by one workout.
final class HeartRateSampleModel: Model, @unchecked Sendable {
    static let schema = "heart_rate_samples"

    @ID(key: .id) var id: UUID?
    @Parent(key: "workout_id") var workout: WorkoutModel
    @Field(key: "bpm") var bpm: Int
    @Field(key: "date") var date: Date

    init() {}

    init(_ dto: HeartRateSampleDTO, workoutID: UUID) {
        self.id = dto.id
        self.$workout.id = workoutID
        self.bpm = dto.bpm
        self.date = dto.date
    }

    var dto: HeartRateSampleDTO {
        HeartRateSampleDTO(id: id ?? UUID(), bpm: bpm, date: date)
    }
}
