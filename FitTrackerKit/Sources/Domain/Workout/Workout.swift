import Foundation

/// A recorded training session: a time window and the heart-rate samples taken during it.
public struct Workout: Identifiable, Hashable, Sendable {
    /// Stable identity, also used as the idempotency key when the workout syncs.
    public let id: UUID
    public let startDate: Date
    public let endDate: Date
    /// Samples in chronological order, all within `startDate...endDate`.
    public let samples: [HeartRateSample]

    /// Creates a validated workout. Samples may be passed in any order; they are stored sorted.
    /// - Throws: `WorkoutError.endBeforeStart` if `endDate < startDate`, or
    ///   `WorkoutError.sampleOutsideWorkout` for the first sample outside the window.
    public init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        samples: [HeartRateSample]
    ) throws(WorkoutError) {
        // Must be checked first: building `startDate...endDate` with end < start would crash.
        guard startDate <= endDate else { throw .endBeforeStart }

        let window = startDate...endDate
        if let outside = samples.first(where: { !window.contains($0.date) }) {
            throw .sampleOutsideWorkout(outside.id)
        }

        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.samples = samples.sorted { $0.date < $1.date }
    }

    /// How long the workout lasted.
    public var duration: Duration {
        .seconds(endDate.timeIntervalSince(startDate))
    }
}
