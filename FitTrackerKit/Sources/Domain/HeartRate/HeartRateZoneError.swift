/// Errors thrown when a `HeartRateZoneCalculator` is created with invalid input.
public enum HeartRateZoneError: Error, Equatable, Sendable {
    /// The max heart rate was zero or negative.
    case invalidMaxHeartRate
    /// The age was outside `1...120`.
    case invalidAge
}
