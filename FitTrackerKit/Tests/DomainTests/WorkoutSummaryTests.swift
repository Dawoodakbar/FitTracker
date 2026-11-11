import Foundation
import Testing
@testable import Domain

/// Specification for `WorkoutSummary`: the stats shown after a workout.
///
/// Time in zone: each sample's zone lasts until the next sample; the last sample lasts until
/// the workout ends. Time before the first sample and time below zone 1 are not counted.
/// All examples use a max heart rate of 200 (aerobic = 140..<160, threshold = 160..<180).
@Suite("Workout summary")
struct WorkoutSummaryTests {

    let start = Date(timeIntervalSince1970: 1_000_000)
    let calculator: HeartRateZoneCalculator

    init() throws {
        calculator = try HeartRateZoneCalculator(maxHeartRate: 200)
    }

    /// Builds a workout lasting `seconds`, with `(bpm, secondsAfterStart)` samples.
    func workout(lasting seconds: TimeInterval, samples: [(Int, TimeInterval)]) throws -> Workout {
        try Workout(
            startDate: start,
            endDate: start.addingTimeInterval(seconds),
            samples: samples.map { bpm, offset in
                try HeartRateSample(bpm: bpm, date: start.addingTimeInterval(offset))
            }
        )
    }

    // MARK: - Empty workout

    @Test("A workout with no samples has a duration but no heart-rate stats")
    func emptyWorkout() throws {
        let summary = WorkoutSummary(workout: try workout(lasting: 600, samples: []), calculator: calculator)

        #expect(summary.duration == .seconds(600))
        #expect(summary.averageBPM == nil)
        #expect(summary.maxBPM == nil)
        #expect(summary.timeInZone.isEmpty)
    }

    // MARK: - BPM stats

    @Test("Computes average (rounded) and max BPM")
    func averageAndMax() throws {
        // (100 + 150 + 151) / 3 = 133.67 -> 134
        let summary = WorkoutSummary(
            workout: try workout(lasting: 300, samples: [(100, 0), (150, 60), (151, 120)]),
            calculator: calculator
        )

        #expect(summary.averageBPM == 134)
        #expect(summary.maxBPM == 151)
    }

    @Test("Average rounds .5 up")
    func averageRoundsHalfUp() throws {
        // (100 + 101) / 2 = 100.5 -> 101
        let summary = WorkoutSummary(
            workout: try workout(lasting: 300, samples: [(100, 0), (101, 60)]),
            calculator: calculator
        )

        #expect(summary.averageBPM == 101)
    }

    // MARK: - Time in zone

    @Test("Each sample's zone lasts until the next sample; resting time is not counted")
    func timeInZone() throws {
        let summary = WorkoutSummary(
            workout: try workout(lasting: 300, samples: [
                (150, 0),     // aerobic   0 ..< 60    = 60s
                (170, 60),    // threshold 60 ..< 180  = 120s
                (90, 180)     // resting   180 ..< 300 -> not counted
            ]),
            calculator: calculator
        )

        #expect(summary.timeInZone == [.aerobic: .seconds(60), .threshold: .seconds(120)])
    }

    @Test("Time in the same zone adds up across separate stretches")
    func timeInZoneAccumulates() throws {
        let summary = WorkoutSummary(
            workout: try workout(lasting: 200, samples: [
                (150, 0),     // aerobic   0 ..< 60    = 60s
                (120, 60),    // endurance 60 ..< 120  = 60s
                (155, 120)    // aerobic   120 ..< 200 = 80s (last sample runs to the end)
            ]),
            calculator: calculator
        )

        #expect(summary.timeInZone == [.aerobic: .seconds(140), .endurance: .seconds(60)])
    }

    // MARK: - Main zone

    @Test("Main zone is nil when no time was spent in any zone")
    func mainZoneNilWhenNoZoneTime() throws {
        let summary = WorkoutSummary(
            workout: try workout(lasting: 300, samples: [(90, 0)]),   // resting the whole time
            calculator: calculator
        )

        #expect(summary.mainZone == nil)
    }

    @Test("Main zone is the zone with the most time")
    func mainZoneIsMostTime() throws {
        let summary = WorkoutSummary(
            workout: try workout(lasting: 300, samples: [(150, 0), (170, 60), (90, 180)]),
            calculator: calculator
        )

        // aerobic 60s, threshold 120s
        #expect(summary.mainZone == .threshold)
    }

    @Test("On a tie, the harder zone wins")
    func mainZoneTieGoesToHarderZone() throws {
        let summary = WorkoutSummary(
            workout: try workout(lasting: 120, samples: [(150, 0), (170, 60)]),
            calculator: calculator
        )

        // aerobic 60s, threshold 60s
        #expect(summary.mainZone == .threshold)
    }

    @Test("Time before the first sample is not counted")
    func ignoresTimeBeforeFirstSample() throws {
        let summary = WorkoutSummary(
            workout: try workout(lasting: 200, samples: [(150, 100)]),
            calculator: calculator
        )

        #expect(summary.timeInZone == [.aerobic: .seconds(100)])
    }
}
