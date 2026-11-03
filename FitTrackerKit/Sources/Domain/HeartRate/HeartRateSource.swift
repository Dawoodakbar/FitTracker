/// Something that produces heart-rate readings over time: a Bluetooth chest strap, a watch,
/// or a simulator.
///
/// Rules every implementation follows:
/// - Each call to `readings()` starts a new, independent stream.
/// - The stream finishes normally when the source stops, or throws if it fails
///   (for example, a monitor disconnecting).
/// - Cancelling the task that iterates the stream stops the source; no extra "stop" call.
public protocol HeartRateSource: Sendable {
    func readings() -> AsyncThrowingStream<HeartRateSample, any Error>
}
