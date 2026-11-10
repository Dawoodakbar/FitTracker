import Foundation

/// A calendar day (no time, no time zone), used as the key for anything logged "per day":
/// sleep, medication doses, prayers and plan sessions.
///
/// Storing year/month/day instead of a `Date` means an entry logged on 3 March stays on
/// 3 March even if the user later travels to another time zone.
public struct Day: Hashable, Comparable, Codable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar`.
    public init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Midnight at the start of this day in `calendar`.
    public func startDate(in calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
    }

    /// The day `days` after this one (negative goes back).
    public func adding(days: Int, calendar: Calendar = .current) -> Day {
        // Noon avoids landing on the wrong day when a daylight-saving change removes midnight.
        let noon = startDate(in: calendar).addingTimeInterval(12 * 3600)
        return Day(calendar.date(byAdding: .day, value: days, to: noon) ?? noon, calendar: calendar)
    }

    /// The `count` days ending on (and including) this one, oldest first.
    public func lastDays(_ count: Int, calendar: Calendar = .current) -> [Day] {
        (0..<max(count, 0)).reversed().map { adding(days: -$0, calendar: calendar) }
    }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
