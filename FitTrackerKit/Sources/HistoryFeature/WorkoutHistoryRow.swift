import Foundation
import Domain

/// One row in the history list: a workout's identity and its precomputed summary.
///
/// Summaries are computed once when loading, not in the view's `body`, which can run many
/// times per second while scrolling.
public struct WorkoutHistoryRow: Identifiable, Equatable, Sendable {
    public let id: Workout.ID
    public let startDate: Date
    public let summary: WorkoutSummary

    init(workout: Workout, calculator: HeartRateZoneCalculator) {
        id = workout.id
        startDate = workout.startDate
        summary = WorkoutSummary(workout: workout, calculator: calculator)
    }
}
