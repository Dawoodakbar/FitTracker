import SwiftUI

/// The app's calm night palette: deep indigo backgrounds lit by soft, glowing pastels.
///
/// The idea is "light on darkness": surfaces stay dark and quiet, and colour is used sparingly
/// for the things that matter (progress, the next step, a finished day).
public enum Palette {
    // MARK: Night (backgrounds)

    /// The deepest background, behind everything.
    public static let night = Color(hex: 0x0C0A1D)
    /// A slightly lifted indigo for the top of background gradients.
    public static let dusk = Color(hex: 0x1C1842)
    /// Card fill, drawn over the background with a hairline border.
    public static let surface = Color.white.opacity(0.06)
    public static let surfaceBorder = Color.white.opacity(0.09)

    // MARK: Glow (accents)

    public static let lavender = Color(hex: 0xB8A6FF)
    public static let periwinkle = Color(hex: 0x7F8CFF)
    public static let peach = Color(hex: 0xFFB199)
    public static let rose = Color(hex: 0xFF8FB8)
    public static let sage = Color(hex: 0xA8E6CF)
    public static let aqua = Color(hex: 0x6FD3D9)
    public static let sky = Color(hex: 0x8EC5FF)
    public static let ice = Color(hex: 0xC4E6FF)
    public static let honey = Color(hex: 0xFFE29A)
    public static let apricot = Color(hex: 0xFFC08C)

    // MARK: Text

    public static let textPrimary = Color.white.opacity(0.96)
    public static let textSecondary = Color.white.opacity(0.62)
    public static let textTertiary = Color.white.opacity(0.4)
}

extension Color {
    /// A colour from a 0xRRGGBB value.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
