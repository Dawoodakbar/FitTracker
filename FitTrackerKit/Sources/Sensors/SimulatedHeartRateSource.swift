import Foundation
import Domain

/// A pretend heart-rate monitor: one reading every `interval`, following a BPM pattern.
///
/// Used by the app until a Bluetooth monitor is connected, and in previews. Swapping it for the
/// real monitor later changes only the composition root; features see a `HeartRateSource`.
public struct SimulatedHeartRateSource: HeartRateSource {
    let interval: Duration
    let bpm: @Sendable (_ tick: Int) -> Int
    let now: @Sendable () -> Date

    /// - Parameters:
    ///   - interval: Time between readings. Tests pass `.zero` to run instantly.
    ///   - bpm: The reading for each tick (0, 1, 2, …). Defaults to `realistic`.
    ///   - now: The timestamp for each reading. Injectable so tests get exact dates.
    public init(
        interval: Duration = .seconds(1),
        bpm: @escaping @Sendable (_ tick: Int) -> Int = SimulatedHeartRateSource.realistic,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.interval = interval
        self.bpm = bpm
        self.now = now
    }

    public func readings() -> AsyncThrowingStream<HeartRateSample, any Error> {
        // `makeStream` returns the stream for the consumer and the continuation for the producer.
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: HeartRateSample.self)

        let producer = Task { [interval, bpm, now] in
            var tick = 0
            do {
                while true {
                    continuation.yield(try HeartRateSample(bpm: bpm(tick), date: now()))
                    tick += 1
                    // Throws `CancellationError` as soon as the consumer stops listening.
                    try await Task.sleep(for: interval)
                }
            } catch is CancellationError {
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        // When the consumer stops iterating (break, prefix, or its task is cancelled),
        // stop producing. Without this the producer task would run forever.
        continuation.onTermination = { _ in producer.cancel() }
        return stream
    }

    /// A believable session: warms up from about 95 to 150 BPM over two minutes, then drifts
    /// in slow waves of ±15 BPM, with a little beat-to-beat noise. Deterministic, so the same
    /// tick always gives the same value.
    @Sendable public static func realistic(tick: Int) -> Int {
        let t = Double(tick)
        let warmUp = min(1, t / 120)
        let base = 95 + 55 * warmUp
        let waves = 15 * sin(t / 45) * warmUp
        let noise = 3 * sin(t * 1.7)
        return Int((base + waves + noise).rounded())
    }
}
