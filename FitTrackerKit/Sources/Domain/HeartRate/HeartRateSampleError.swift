/// Errors thrown when a `HeartRateSample` is created with invalid input.
public enum HeartRateSampleError: Error, Equatable, Sendable {
    /// The BPM was outside `HeartRateSample.validBPM`. Carries the rejected value for logging.
    case invalidBPM(Int)
}
