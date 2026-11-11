import Foundation

/// A workout as it travels between the app and the server (JSON, version 1 of the API).
///
/// "DTO" means data transfer object: a type whose only job is describing the wire format.
/// The app maps it to and from its Domain `Workout`; the server maps it to its database model.
/// The client creates `id`, and the server uses it to ignore repeated uploads of the same workout.
public struct WorkoutDTO: Codable, Equatable, Sendable {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date
    public var samples: [HeartRateSampleDTO]

    public init(id: UUID, startDate: Date, endDate: Date, samples: [HeartRateSampleDTO]) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.samples = samples
    }
}

/// One heart-rate reading inside a `WorkoutDTO`.
public struct HeartRateSampleDTO: Codable, Equatable, Sendable {
    public var id: UUID
    public var bpm: Int
    public var date: Date

    public init(id: UUID, bpm: Int, date: Date) {
        self.id = id
        self.bpm = bpm
        self.date = date
    }
}

/// The reply to `GET /health`.
public struct HealthDTO: Codable, Equatable, Sendable {
    public var status: String

    public init(status: String) {
        self.status = status
    }
}
