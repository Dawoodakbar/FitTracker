import Domain

/// A `HeartRateSource` that plays back fixed readings immediately, then finishes, or throws
/// `failure` to simulate a monitor disconnecting.
public struct ScriptedHeartRateSource: HeartRateSource {
    // Not named `readings`: a property can't share its name with the `readings()` method.
    let script: [HeartRateSample]
    let failure: (any Error)?

    public init(readings: [HeartRateSample], failure: (any Error)? = nil) {
        self.script = readings
        self.failure = failure
    }

    public func readings() -> AsyncThrowingStream<HeartRateSample, any Error> {
        AsyncThrowingStream { continuation in
            for reading in script {
                continuation.yield(reading)
            }
            continuation.finish(throwing: failure)
        }
    }
}
