import SwiftUI

/// A shape style that draws a zone's colour, switching between its light and dark variant
/// automatically as the colour scheme changes.
///
/// ```swift
/// Circle().fill(.zone(.zone3))
/// Text("3").foregroundStyle(.zone(.zone3))
/// ```
public struct ZoneTint: ShapeStyle {
    public let tone: ZoneTone

    public init(_ tone: ZoneTone) {
        self.tone = tone
    }

    /// SwiftUI calls this with the view's environment each time it draws.
    public func resolve(in environment: EnvironmentValues) -> Color {
        switch environment.colorScheme {
        case .dark: tone.dark.color
        default: tone.light.color
        }
    }
}

extension ShapeStyle where Self == ZoneTint {
    /// The colour for `tone`, adapting to light and dark mode.
    public static func zone(_ tone: ZoneTone) -> ZoneTint {
        ZoneTint(tone)
    }
}
