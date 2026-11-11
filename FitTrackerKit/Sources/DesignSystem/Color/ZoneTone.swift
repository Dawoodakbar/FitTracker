/// The colour for each of the five heart-rate zones, numbered 1 (easiest) to 5 (hardest).
///
/// DesignSystem doesn't depend on Domain, so tones are keyed by zone number:
/// `ZoneTone(rawValue: zone.number)`.
public enum ZoneTone: Int, CaseIterable, Sendable {
    case zone1 = 1
    case zone2
    case zone3
    case zone4
    case zone5

    /// The colour on light backgrounds. Every tone reaches 3:1 contrast against white.
    public var light: RGB {
        switch self {
        case .zone1: RGB(hex: 0x4C82E6)   // blue
        case .zone2: RGB(hex: 0x2C9A64)   // green
        case .zone3: RGB(hex: 0xA97F0A)   // amber (blueprint's #C99A12 was only 2.59:1)
        case .zone4: RGB(hex: 0xE06F22)   // orange
        case .zone5: RGB(hex: 0xCF2F3A)   // red
        }
    }

    /// The colour on dark backgrounds: lighter, so it keeps 3:1 contrast against `#1C1C1E`.
    public var dark: RGB {
        switch self {
        case .zone1: RGB(hex: 0x6E9BF0)
        case .zone2: RGB(hex: 0x3DBA7C)
        case .zone3: RGB(hex: 0xE0B43A)
        case .zone4: RGB(hex: 0xF08A45)
        case .zone5: RGB(hex: 0xF0565F)
        }
    }
}
