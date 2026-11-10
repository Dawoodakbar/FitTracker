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

    public static let move = RingStyle(start: Color(red: 0.98, green: 0.07, blue: 0.31), end: Color(red: 1.0, green: 0.45, blue: 0.3))
    public static let sleep = RingStyle(start: Color(red: 0.35, green: 0.34, blue: 0.84), end: Color(red: 0.69, green: 0.32, blue: 0.87))
    public static let prayer = RingStyle(start: Color(red: 0.0, green: 0.62, blue: 0.58), end: Color(red: 0.4, green: 0.83, blue: 0.6))
    public static let medication = RingStyle(start: Color(red: 0.0, green: 0.48, blue: 1.0), end: Color(red: 0.35, green: 0.78, blue: 0.98))
    public static let plan = RingStyle(start: Color(red: 1.0, green: 0.58, blue: 0.0), end: Color(red: 1.0, green: 0.8, blue: 0.0))

    public var gradient: LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
