import Testing
@testable import Domain

/// Specification for `HeartRateZoneCalculator`.
///
/// Zones are percentages of the user's maximum heart rate:
/// | Zone        | Range of max HR |
/// | ----------- | --------------- |
/// | recovery    | 50% ..< 60%     |
/// | endurance   | 60% ..< 70%     |
/// | aerobic     | 70% ..< 80%     |
/// | threshold   | 80% ..< 90%     |
/// | maximum     | 90% and above   |
/// Below 50% the user is resting, so there is no zone (`nil`).
@Suite("Heart rate zone calculator")
struct HeartRateZoneTests {

    // MARK: - Creating a calculator

    @Test("Stores the max heart rate it was given")
    func storesMaxHeartRate() throws {
        let calculator = try HeartRateZoneCalculator(maxHeartRate: 200)

        #expect(calculator.maxHeartRate == 200)
    }

    @Test("Estimates max heart rate from age using 220 - age")
    func estimatesMaxHeartRateFromAge() throws {
        let calculator = try HeartRateZoneCalculator(age: 30)

        #expect(calculator.maxHeartRate == 190)
    }

    @Test("Rejects a max heart rate that is zero or negative", arguments: [0, -1, -180])
    func rejectsInvalidMaxHeartRate(maxHeartRate: Int) {
        #expect(throws: HeartRateZoneError.invalidMaxHeartRate) {
            try HeartRateZoneCalculator(maxHeartRate: maxHeartRate)
        }
    }

    @Test("Rejects an age outside 1...120", arguments: [0, -5, 121, 300])
    func rejectsInvalidAge(age: Int) {
        #expect(throws: HeartRateZoneError.invalidAge) {
            try HeartRateZoneCalculator(age: age)
        }
    }

    // MARK: - Calculating zones (max heart rate = 200)

    @Test("Maps BPM to the correct zone, including exact boundaries", arguments: [
        (100, HeartRateZone.recovery),   // exactly 50%  -> first zone starts
        (119, HeartRateZone.recovery),   // just below 60%
        (120, HeartRateZone.endurance),  // exactly 60%
        (139, HeartRateZone.endurance),
        (140, HeartRateZone.aerobic),    // exactly 70%
        (159, HeartRateZone.aerobic),
        (160, HeartRateZone.threshold),  // exactly 80%
        (179, HeartRateZone.threshold),
        (180, HeartRateZone.maximum),    // exactly 90%
        (200, HeartRateZone.maximum),    // 100%
        (215, HeartRateZone.maximum)     // above max still counts as maximum
    ])
    func mapsBPMToZone(bpm: Int, expected: HeartRateZone) throws {
        let calculator = try HeartRateZoneCalculator(maxHeartRate: 200)

        #expect(calculator.zone(for: bpm) == expected)
    }

    @Test("Returns nil when the heart rate is below 50% (resting)", arguments: [99, 60, 0, -10])
    func returnsNilBelowFirstZone(bpm: Int) throws {
        let calculator = try HeartRateZoneCalculator(maxHeartRate: 200)

        #expect(calculator.zone(for: bpm) == nil)
    }

    // MARK: - Lowest BPM in a zone

    @Test("Lowest BPM in each zone for max 200", arguments: [
        (HeartRateZone.recovery, 100),
        (HeartRateZone.endurance, 120),
        (HeartRateZone.aerobic, 140),
        (HeartRateZone.threshold, 160),
        (HeartRateZone.maximum, 180)
    ])
    func lowestBPMForMax200(zone: HeartRateZone, expected: Int) throws {
        let calculator = try HeartRateZoneCalculator(maxHeartRate: 200)

        #expect(calculator.lowestBPM(in: zone) == expected)
    }

    @Test("Rounds up when the boundary is not a whole BPM")
    func lowestBPMRoundsUp() throws {
        // 50% of 195 = 97.5. 97 BPM is still resting, so the zone really starts at 98.
        let calculator = try HeartRateZoneCalculator(maxHeartRate: 195)

        #expect(calculator.lowestBPM(in: .recovery) == 98)
    }

    @Test(
        "Lowest BPM is in the zone and one below is not",
        arguments: [150, 190, 195, 199],
        HeartRateZone.allCases
    )
    func lowestBPMMatchesZoneForBPM(maxHeartRate: Int, zone: HeartRateZone) throws {
        // Ties `lowestBPM(in:)` to `zone(for:)`, so the two can never disagree.
        let calculator = try HeartRateZoneCalculator(maxHeartRate: maxHeartRate)
        let lowest = calculator.lowestBPM(in: zone)

        #expect(calculator.zone(for: lowest) == zone)
        #expect(calculator.zone(for: lowest - 1) != zone)
    }

    // MARK: - Zone metadata

    @Test("Zones are numbered 1 to 5 in order")
    func zonesAreNumberedInOrder() {
        #expect(HeartRateZone.allCases.map(\.number) == [1, 2, 3, 4, 5])
    }
}
