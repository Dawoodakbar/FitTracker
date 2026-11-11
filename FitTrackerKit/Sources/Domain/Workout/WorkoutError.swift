/// Errors thrown when a `Workout` is created with invalid input.
public enum WorkoutError: Error, Equatable, Sendable {
    /// `endDate` was earlier than `startDate`.
    case endBeforeStart
    /// A sample was recorded outside `startDate...endDate`. Carries the sample's id.
    case sampleOutsideWorkout(HeartRateSample.ID)
}
