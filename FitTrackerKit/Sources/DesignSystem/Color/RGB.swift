import SwiftUI

/// An sRGB colour stored as 8-bit components.
///
/// Design tokens are defined as `RGB` (not `Color`) because plain numbers can be compared,
/// hashed and checked for accessibility in unit tests. Convert with `color` to draw.
public struct RGB: Hashable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    /// Creates a colour from a `0xRRGGBB` value, the same format as CSS `#RRGGBB`.
    public init(hex: UInt32) {
        red = UInt8((hex >> 16) & 0xFF)
        green = UInt8((hex >> 8) & 0xFF)
        blue = UInt8(hex & 0xFF)
    }

    public static let white = RGB(hex: 0xFFFFFF)
    public static let black = RGB(hex: 0x000000)

    /// The SwiftUI colour for drawing.
    public var color: Color {
        Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    // MARK: - Accessibility

    /// The WCAG 2.x contrast ratio between two colours, from `1` (none) to `21` (black/white).
    public func contrastRatio(with other: RGB) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// How bright the colour looks to the human eye, from `0` (black) to `1` (white).
    ///
    /// Each channel is converted from gamma-encoded sRGB to linear light first; the weights
    /// reflect that eyes are most sensitive to green and least to blue.
    var relativeLuminance: Double {
        func linear(_ channel: UInt8) -> Double {
            let value = Double(channel) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}
