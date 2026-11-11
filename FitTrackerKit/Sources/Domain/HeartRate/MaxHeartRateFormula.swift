/// A strategy for estimating someone's maximum heart rate from their age.
///
/// Conform a new type to add a formula; `HeartRateZoneCalculator` works with any of them.
public protocol MaxHeartRateFormula: Sendable {
    /// Estimated maximum heart rate in BPM for `age` in years.
    func maxHeartRate(forAge age: Int) -> Int
}

/// The classic `220 - age` formula (Fox). Simple and widely known.
public struct FoxFormula: MaxHeartRateFormula {
    public init() {}

    public func maxHeartRate(forAge age: Int) -> Int {
        220 - age
    }
}

/// The `208 - 0.7 × age` formula (Tanaka), more accurate for adults over 40.
public struct TanakaFormula: MaxHeartRateFormula {
    public init() {}

    public func maxHeartRate(forAge age: Int) -> Int {
        // Work in tenths of a beat to stay in whole numbers: 2080 - 7 × age.
        // Adding 5 before dividing by 10 rounds .5 up (190.5 -> 191) without `Double`,
        // whose binary representation of 0.7 could push exact halves the wrong way.
        (2080 - 7 * age + 5) / 10
    }
}

// MARK: - Dot syntax

// These let callers write `.fox` / `.tanaka` wherever a `MaxHeartRateFormula` is expected.
extension MaxHeartRateFormula where Self == FoxFormula {
    public static var fox: FoxFormula { FoxFormula() }
}

extension MaxHeartRateFormula where Self == TanakaFormula {
    public static var tanaka: TanakaFormula { TanakaFormula() }
}
