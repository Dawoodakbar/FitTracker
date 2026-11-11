#if DEBUG
import Foundation
import Domain

/// Generates realistic-looking workouts for trying the app before Live Workout exists.
/// Debug builds only; never shipped.
enum SampleWorkout {
    /// A 20–45 minute workout ending at `endDate`, with a sample every 10 seconds that
    /// warms up, holds a random effort, then cools down.
    static func make(endingAt endDate: Date) throws -> Workout {
        let minutes = Int.random(in: 20...45)
        let startDate = endDate.addingTimeInterval(-Double(minutes * 60))
        let peakBPM = Int.random(in: 130...185)
        let sampleCount = minutes * 6   // one every 10 seconds

        let samples = try (0..<sampleCount).map { index in
            // 0 → 1 over the first fifth (warm-up), hold, 1 → 0 over the last fifth (cool-down).
            let progress = Double(index) / Double(sampleCount)
            let effort = min(1, progress * 5, (1 - progress) * 5)
            let bpm = 90 + Int(Double(peakBPM - 90) * effort) + Int.random(in: -4...4)
            return try HeartRateSample(bpm: bpm, date: startDate.addingTimeInterval(Double(index * 10)))
        }

        return try Workout(startDate: startDate, endDate: endDate, samples: samples)
    }
}
#endif
