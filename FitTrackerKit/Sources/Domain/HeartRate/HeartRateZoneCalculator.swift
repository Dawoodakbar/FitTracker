/// Maps a heart rate in beats per minute to a `HeartRateZone`.
///
/// ```swift
/// let calculator = try HeartRateZoneCalculator(age: 30)   // max HR = 190
/// calculator.zone(for: 150)                                // .aerobic
/// ```
public struct HeartRateZoneCalculator: Equatable, Sendable {
    /// Valid ages for estimating max heart rate.
    static let validAges = 1...120

    /// The user's maximum heart rate in BPM. Always greater than zero.
    public let maxHeartRate: Int

    /// Creates a calculator from a known (e.g. measured) maximum heart rate.
    /// - Throws: `HeartRateZoneError.invalidMaxHeartRate` if `maxHeartRate <= 0`.
    public init(maxHeartRate: Int) throws(HeartRateZoneError) {
        guard maxHeartRate > 0 else { throw .invalidMaxHeartRate }
        self.maxHeartRate = maxHeartRate
    }

    /// Creates a calculator by estimating max heart rate from `age` with `formula`.
    /// - Parameter formula: The estimation strategy. Defaults to `.fox` (`220 - age`).
    /// - Throws: `HeartRateZoneError.invalidAge` if `age` is outside `1...120`, or
    ///   `HeartRateZoneError.invalidMaxHeartRate` if the formula returns a value `<= 0`.
    public init(
        age: Int,
        formula: some MaxHeartRateFormula = .fox
    ) throws(HeartRateZoneError) {
        guard Self.validAges.contains(age) else { throw .invalidAge }
        try self.init(maxHeartRate: formula.maxHeartRate(forAge: age))
    }

    /// The lowest whole BPM that `zone(for:)` places in `zone`.
    ///
    /// Use this to show zone ranges, so the UI never re-implements the boundary math.
    public func lowestBPM(in zone: HeartRateZone) -> Int {
        // Ceiling division: the boundary `percent × max / 100` is often fractional (97.5),
        // and the first BPM that satisfies `bpm * 100 >= percent * max` is the next whole one.
        (zone.lowerBoundPercent * maxHeartRate + 99) / 100
    }

    /// Returns the zone for `bpm`, or `nil` if it is below 50% of max (resting).
    public func zone(for bpm: Int) -> HeartRateZone? {
        // Compare `bpm * 100 >= percent * max` instead of dividing, so the math stays in
        // whole numbers and boundaries like exactly 60% can't hit floating-point rounding errors.
        HeartRateZone.allCases.last { zone in
            bpm * 100 >= zone.lowerBoundPercent * maxHeartRate
        }
    }
}
