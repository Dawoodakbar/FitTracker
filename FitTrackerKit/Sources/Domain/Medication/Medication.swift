import Foundation

/// A time of day a dose is due, e.g. 08:00. Always a real clock time.
public struct DoseTime: Hashable, Comparable, Codable, Sendable {
    public let hour: Int
    public let minute: Int

    /// Out-of-range values are clamped to the nearest valid time.
    public init(hour: Int, minute: Int = 0) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public static func < (lhs: DoseTime, rhs: DoseTime) -> Bool {
        (lhs.hour, lhs.minute) < (rhs.hour, rhs.minute)
    }
}

/// Something the user takes on a daily schedule. The app tracks it; it never gives dosing advice.
public struct Medication: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    /// Free text exactly as the user typed it, e.g. "500 mg" or "2 puffs".
    public var dose: String
    /// When doses are due each day, earliest first, without duplicates.
    public var times: [DoseTime]
    /// Doses left in the pack, if the user wants refill warnings.
    public var remaining: Int?
    /// The first day doses count towards adherence.
    public let startDay: Day

    public init(
        id: UUID = UUID(),
        name: String,
        dose: String = "",
        times: [DoseTime],
        remaining: Int? = nil,
        startDay: Day
    ) {
        self.id = id
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.dose = dose.trimmingCharacters(in: .whitespacesAndNewlines)
        self.times = Array(Set(times)).sorted()
        self.remaining = remaining.map { max($0, 0) }
        self.startDay = startDay
    }
}

/// Identifies one scheduled dose: this medication, on this day, at this time.
public struct DoseKey: Hashable, Codable, Sendable {
    public let medicationID: Medication.ID
    public let day: Day
    public let time: DoseTime

    public init(medicationID: Medication.ID, day: Day, time: DoseTime) {
        self.medicationID = medicationID
        self.day = day
        self.time = time
    }
}

public enum DoseStatus: String, Codable, Sendable {
    case taken
    case skipped
}

/// One row of a day's checklist.
public struct ScheduledDose: Identifiable, Hashable, Sendable {
    public let medication: Medication
    public let key: DoseKey
    /// `nil` until the user marks it.
    public let status: DoseStatus?

    public var id: DoseKey { key }
}
