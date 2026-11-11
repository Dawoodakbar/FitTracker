/// A training intensity zone, defined as a percentage range of the user's maximum heart rate.
///
/// Cases are declared from lowest to highest intensity, so `allCases` is already sorted.
public enum HeartRateZone: Int, CaseIterable, Comparable, Sendable {
    case recovery = 1
    case endurance
    case aerobic
    case threshold
    case maximum

    /// The zone's number as shown to users (1 = recovery ... 5 = maximum).
    public var number: Int { rawValue }

    /// The lowest percentage of max heart rate (inclusive) that belongs to this zone.
    ///
    /// Each zone ends where the next one starts, so only the lower bound is stored.
    var lowerBoundPercent: Int {
        switch self {
        case .recovery: 50
        case .endurance: 60
        case .aerobic: 70
        case .threshold: 80
        case .maximum: 90
        }
    }

    public static func < (lhs: HeartRateZone, rhs: HeartRateZone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
