import Foundation

/// The five daily prayers, in the order they occur. Raw values are stored on disk.
public enum DailyPrayer: String, CaseIterable, Codable, Identifiable, Sendable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha

    public var id: Self { self }
}

/// How a prayer was completed. An honest record is more useful than a plain checkbox.
public enum PrayerStatus: String, Codable, Sendable {
    case onTime
    /// Made up after its time.
    case late
}

/// The user's record of prayers, day by day. Kept on the device only.
public struct PrayerJournal: Codable, Equatable, Sendable {
    public private(set) var days: [Day: [DailyPrayer: PrayerStatus]]

    public init(days: [Day: [DailyPrayer: PrayerStatus]] = [:]) {
        self.days = days
    }

    public func status(of prayer: DailyPrayer, on day: Day) -> PrayerStatus? {
        days[day]?[prayer]
    }

    /// Sets or clears (`nil`) one prayer's status.
    public mutating func set(_ status: PrayerStatus?, for prayer: DailyPrayer, on day: Day) {
        days[day, default: [:]][prayer] = status
        if days[day]?.isEmpty == true { days[day] = nil }
    }

    /// One tap moves a prayer through: not prayed → on time → late → not prayed.
    public mutating func cycle(_ prayer: DailyPrayer, on day: Day) {
        let next: PrayerStatus? = switch status(of: prayer, on: day) {
        case nil: .onTime
        case .onTime: .late
        case .late: nil
        }
        set(next, for: prayer, on: day)
    }

    /// How many of the five were prayed on `day`, on time or late.
    public func count(on day: Day) -> Int {
        days[day]?.count ?? 0
    }

    public func isComplete(on day: Day) -> Bool {
        count(on: day) == DailyPrayer.allCases.count
    }

    /// Consecutive complete days up to `day`. While today is still in progress it doesn't
    /// break the streak: the count runs up to yesterday until today is complete too.
    public func streak(endingOn day: Day, calendar: Calendar = .current) -> Int {
        var cursor = isComplete(on: day) ? day : day.adding(days: -1, calendar: calendar)
        var length = 0
        while isComplete(on: cursor) {
            length += 1
            cursor = cursor.adding(days: -1, calendar: calendar)
        }
        return length
    }
}
