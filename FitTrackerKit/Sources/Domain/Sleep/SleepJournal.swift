import Foundation

/// A summary of several nights.
public struct SleepStats: Equatable, Sendable {
    public let nights: Int
    public let averageDuration: TimeInterval
    /// 0...100: how regular bed and wake times are. `nil` with fewer than 3 nights.
    public let consistency: Int?
}

/// Every night the user has logged, at most one per day.
public struct SleepJournal: Codable, Equatable, Sendable {
    /// Nights needed before a consistency score means anything.
    public static let minimumNightsForConsistency = 3
    /// Bed and wake times that vary by this many minutes on average score 0.
    static let worstSpreadMinutes = 120.0

    public private(set) var entries: [SleepEntry]

    public init(entries: [SleepEntry] = []) {
        self.entries = entries.sorted { $0.wakeTime > $1.wakeTime }
    }

    /// Adds `entry`, replacing any night already logged for the same day. Newest first.
    public mutating func log(_ entry: SleepEntry, calendar: Calendar = .current) {
        let day = entry.day(in: calendar)
        entries.removeAll { $0.day(in: calendar) == day }
        entries.append(entry)
        entries.sort { $0.wakeTime > $1.wakeTime }
    }

    public mutating func remove(id: SleepEntry.ID) {
        entries.removeAll { $0.id == id }
    }

    public func entry(on day: Day, calendar: Calendar = .current) -> SleepEntry? {
        entries.first { $0.day(in: calendar) == day }
    }

    /// The last `days` days ending on `day`, oldest first, each with its night if one was logged.
    public func nights(endingOn day: Day, days: Int, calendar: Calendar = .current) -> [(day: Day, entry: SleepEntry?)] {
        day.lastDays(days, calendar: calendar).map { ($0, entry(on: $0, calendar: calendar)) }
    }

    /// Averages over the logged nights in the last `days` days. `nil` if there are none.
    public func stats(endingOn day: Day, days: Int = 7, calendar: Calendar = .current) -> SleepStats? {
        let logged = nights(endingOn: day, days: days, calendar: calendar).compactMap(\.entry)
        guard !logged.isEmpty else { return nil }
        let average = logged.reduce(0) { $0 + $1.duration } / Double(logged.count)
        return SleepStats(
            nights: logged.count,
            averageDuration: average,
            consistency: Self.consistency(of: logged, calendar: calendar)
        )
    }

    /// Regular sleep timing matters at least as much as duration, so it gets its own score:
    /// 100 when every night starts and ends at the same clock time, falling to 0 as the
    /// typical variation reaches two hours.
    static func consistency(of nights: [SleepEntry], calendar: Calendar) -> Int? {
        guard nights.count >= minimumNightsForConsistency else { return nil }
        let bedSpread = spread(nights.map { minutesFromNoon($0.bedtime, calendar: calendar) })
        let wakeSpread = spread(nights.map { minutesFromNoon($0.wakeTime, calendar: calendar) })
        let score = 100 * (1 - ((bedSpread + wakeSpread) / 2) / worstSpreadMinutes)
        return Int(min(max(score, 0), 100).rounded())
    }

    /// Clock time as minutes after noon, so 23:30 and 00:30 are 60 minutes apart, not 23 hours.
    static func minutesFromNoon(_ date: Date, calendar: Calendar) -> Double {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        return Double((minutes - 720 + 1440) % 1440)
    }

    /// Standard deviation.
    private static func spread(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        return variance.squareRoot()
    }
}
