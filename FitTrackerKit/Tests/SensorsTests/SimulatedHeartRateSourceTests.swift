import Foundation
import Testing
import Domain
@testable import Sensors

/// Specification for `SimulatedHeartRateSource`, the stand-in for a real monitor.
@Suite("Simulated heart rate source")
struct SimulatedHeartRateSourceTests {

    let start = Date(timeIntervalSince1970: 1_000_000)

    @Test("Emits one reading per tick from its BPM pattern, stamped with the current time")
    func emitsPattern() async throws {
        // `interval: .zero` so the test doesn't wait real seconds between readings.
        let source = SimulatedHeartRateSource(interval: .zero, bpm: { 100 + $0 }, now: { [start] in start })

        var readings: [HeartRateSample] = []
        // `prefix(3)` stops iterating after three values; that cancels the source's task.
        for try await reading in source.readings().prefix(3) {
            readings.append(reading)
        }

        #expect(readings.map(\.bpm) == [100, 101, 102])
        #expect(readings.allSatisfy { $0.date == start })
    }

    @Test("Each call to readings() starts again from the first tick")
    func independentStreams() async throws {
        let source = SimulatedHeartRateSource(interval: .zero, bpm: { 100 + $0 })

        let first = try await source.readings().prefix(2).map(\.bpm).reduce(into: []) { $0.append($1) }
        let second = try await source.readings().prefix(2).map(\.bpm).reduce(into: []) { $0.append($1) }

        #expect(first == [100, 101])
        #expect(second == [100, 101])
    }

    @Test("The realistic pattern warms up, then stays in a plausible workout range for 2 hours")
    func realisticPattern() {
        let twoHours = (0..<7200).map(SimulatedHeartRateSource.realistic)

        #expect(twoHours[0] < twoHours[120], "should warm up over the first two minutes")
        #expect(twoHours.allSatisfy { (80...190).contains($0) })
    }
}
