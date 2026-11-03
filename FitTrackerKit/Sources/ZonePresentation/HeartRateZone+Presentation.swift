import Domain
import DesignSystem

/// How each heart-rate zone appears on screen. Shared by every feature, so the colour and
/// wording for a zone are defined once.
extension HeartRateZone {
    /// The DesignSystem colour. An exhaustive switch, so a new Domain zone won't compile
    /// until it gets a tone.
    public var tone: ZoneTone {
        switch self {
        case .recovery: .zone1
        case .endurance: .zone2
        case .aerobic: .zone3
        case .threshold: .zone4
        case .maximum: .zone5
        }
    }

    /// The name shown to users. (To be moved into a String Catalog when the app is localized.)
    public var name: String {
        switch self {
        case .recovery: "Recovery"
        case .endurance: "Endurance"
        case .aerobic: "Aerobic"
        case .threshold: "Threshold"
        case .maximum: "Maximum"
        }
    }
}
