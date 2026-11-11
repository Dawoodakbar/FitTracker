import SwiftUI

/// A shape style that draws a zone's colour, switching between its light and dark variant
/// automatically as the colour scheme changes.
///
/// ```swift
/// Circle().fill(.zone(.zone3))                 // the zone colour itself
/// Text("3").foregroundStyle(.onZone(.zone3))   // text drawn on top of a zone fill
/// ```
public struct ZoneTint: ShapeStyle {
    /// What the style is used for.
    public enum Role: Sendable {
        /// The zone colour itself, for fills, dots and accents.
        case zone
        /// Text or symbols drawn on top of a `.zone` fill.
        case onZone
    }

    /// Content colour on a light-mode zone fill. Each light tone reaches 3:1 against it.
    public static let onLight = RGB.white
    /// Content colour on a dark-mode zone fill. Each dark tone reaches 3:1 against it.
    public static let onDark = RGB(hex: 0x1C1C1E)

    public let tone: ZoneTone
    public let role: Role

    public init(_ tone: ZoneTone, role: Role = .zone) {
        self.tone = tone
        self.role = role
    }

    /// SwiftUI calls this with the view's environment each time it draws.
    public func resolve(in environment: EnvironmentValues) -> Color {
        let isDark = environment.colorScheme == .dark
        return switch role {
        case .zone: isDark ? tone.dark.color : tone.light.color
        case .onZone: isDark ? Self.onDark.color : Self.onLight.color
        }
    }

    /// Text or symbols drawn on a `.zone(tone)` fill.
    public static func onZone(_ tone: ZoneTone) -> ZoneTint {
        ZoneTint(tone, role: .onZone)
    }
}

extension ShapeStyle where Self == ZoneTint {
    /// The colour for `tone`, adapting to light and dark mode.
    public static func zone(_ tone: ZoneTone) -> ZoneTint {
        ZoneTint(tone)
    }

    /// The colour for content drawn on a `.zone(tone)` fill, adapting to light and dark mode.
    public static func onZone(_ tone: ZoneTone) -> ZoneTint {
        ZoneTint(tone, role: .onZone)
    }
}
