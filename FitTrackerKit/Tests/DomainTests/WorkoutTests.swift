import Foundation
import Testing
@testable import Domain

/// Specification for `Workout`: a time window plus the heart-rate samples recorded in it.
@Suite("Workout")
struct WorkoutTests {

    let start = Date(timeIntervalSince1970: 1_000_000)

    /// A sample `seconds` after `start`.
    func sample(_ bpm: Int, at seconds: TimeInterval) throws -> HeartRateSample {
        try HeartRateSample(bpm: bpm, date: start.addingTimeInterval(seconds))
    }

    // MARK: - Creating a workout

    @Test("Stores its dates and computes duration")
    func storesDatesAndDuration() throws {
        let end = start.addingTimeInterval(30 * 60)

        let workout = try Workout(startDate: start, endDate: end, samples: [])

        #expect(workout.startDate == start)
        #expect(workout.endDate == end)
        #expect(workout.duration == .seconds(30 * 60))
    }

    @Test("A workout can be zero length")
    func allowsZeroLength() throws {
        let workout = try Workout(startDate: start, endDate: start, samples: [])

        #expect(workout.duration == .zero)
    }

    @Test("Rejects an end date before the start date")
    func rejectsEndBeforeStart() {
        #expect(throws: WorkoutError.endBeforeStart) {
            try Workout(startDate: start, endDate: start.addingTimeInterval(-1), samples: [])
        }
    }

    // MARK: - Samples

    @Test("Sorts samples chronologically")
    func sortsSamples() throws {
        let late = try sample(150, at: 120)
        let early = try sample(100, at: 0)
        let middle = try sample(120, at: 60)

        let workout = try Workout(
            startDate: start,
            endDate: start.addingTimeInterval(300),
            samples: [late, early, middle]
        )

        #expect(workout.samples == [early, middle, late])
    }

    @Test("Accepts samples exactly at the start and end", arguments: [0.0, 300.0])
    func acceptsSamplesOnBoundaries(seconds: TimeInterval) throws {
        let onBoundary = try sample(120, at: seconds)

        let workout = try Workout(
            startDate: start,
            endDate: start.addingTimeInterval(300),
            samples: [onBoundary]
        )

        #expect(workout.samples == [onBoundary])
    }

    @Test("Rejects a sample outside the workout window", arguments: [-1.0, 301.0])
    func rejectsSampleOutsideWindow(seconds: TimeInterval) throws {
        let outside = try sample(120, at: seconds)

        #expect(throws: WorkoutError.sampleOutsideWorkout(outside.id)) {
            try Workout(
                startDate: start,
                endDate: start.addingTimeInterval(300),
                samples: [outside]
            )
        }
    }
}
