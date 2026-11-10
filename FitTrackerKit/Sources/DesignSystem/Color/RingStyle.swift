import SwiftUI

/// The two-colour gradient for one area of the app (training, sleep, ...).
///
/// Each area keeps the same colours on every screen, so a glance at a ring or bar tells
/// the user which part of their day it shows.
public struct RingStyle: Equatable, Sendable {
    public let start: Color
    public let end: Color

    public init(start: Color, end: Color) {
        self.start = start
        self.end = end
    }

    /// Training: warm peach into rose.
    public static let move = RingStyle(start: Palette.rose, end: Palette.peach)
    /// Sleep: lavender into periwinkle.
    public static let sleep = RingStyle(start: Palette.periwinkle, end: Palette.lavender)
    /// Prayer: aqua into sage.
    public static let prayer = RingStyle(start: Palette.aqua, end: Palette.sage)
    /// Medication: sky into ice.
    public static let medication = RingStyle(start: Palette.sky, end: Palette.ice)
    /// Plans and streaks: apricot into honey.
    public static let plan = RingStyle(start: Palette.apricot, end: Palette.honey)

    public var gradient: LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
