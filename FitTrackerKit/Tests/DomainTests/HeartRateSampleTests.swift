import Foundation
import Testing
@testable import Domain

/// Specification for `HeartRateSample`: one heart-rate reading at a point in time.
///
/// Valid BPM is `1...300`. Sensors report `0` when they lose skin contact, so `0` is rejected.
@Suite("Heart rate sample")
struct HeartRateSampleTests {

    /// A fixed date, so tests never depend on the clock.
    let date = Date(timeIntervalSince1970: 1_000_000)

    // MARK: - Creating a sample

    @Test("Stores the id, BPM and date it was given")
    func storesValues() throws {
        let id = try #require(UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"))

        let sample = try HeartRateSample(id: id, bpm: 72, date: date)

        #expect(sample.id == id)
        #expect(sample.bpm == 72)
        #expect(sample.date == date)
    }

    @Test("Generates a unique id when none is given")
    func generatesUniqueIDs() throws {
        let first = try HeartRateSample(bpm: 72, date: date)
        let second = try HeartRateSample(bpm: 72, date: date)

        #expect(first.id != second.id)
    }

    @Test("Accepts BPM at the edges of the valid range", arguments: [1, 300])
    func acceptsBoundaryBPM(bpm: Int) throws {
        let sample = try HeartRateSample(bpm: bpm, date: date)

        #expect(sample.bpm == bpm)
    }

    @Test("Rejects BPM outside 1...300", arguments: [0, -1, 301, 1_000])
    func rejectsInvalidBPM(bpm: Int) {
        #expect(throws: HeartRateSampleError.invalidBPM(bpm)) {
            try HeartRateSample(bpm: bpm, date: date)
        }
    }

    // MARK: - Identity

    @Test("Samples with the same id, BPM and date are equal and hash the same")
    func equalityAndHashing() throws {
        let id = UUID()
        let a = try HeartRateSample(id: id, bpm: 80, date: date)
        let b = try HeartRateSample(id: id, bpm: 80, date: date)

        #expect(a == b)
        #expect(Set([a, b]).count == 1)
    }

    // MARK: - Zone

    @Test("Asks the calculator for its zone", arguments: [
        (90, nil),                          // below 50% of 200 -> resting
        (150, HeartRateZone.aerobic),       // 75%
        (190, HeartRateZone.maximum)        // 95%
    ])
    func zoneUsingCalculator(bpm: Int, expected: HeartRateZone?) throws {
        let calculator = try HeartRateZoneCalculator(maxHeartRate: 200)
        let sample = try HeartRateSample(bpm: bpm, date: date)

        #expect(sample.zone(using: calculator) == expected)
    }
}
