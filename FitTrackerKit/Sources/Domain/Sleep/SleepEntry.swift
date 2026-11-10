import Foundation

/// Errors thrown when a `SleepEntry` is created with invalid input.
public enum SleepError: Error, Equatable, Sendable {
    /// The wake time was not after the bedtime.
    case wakeNotAfterBedtime
    /// The night was longer than 24 hours, which is almost certainly a wrong date.
    case longerThanADay
}

/// One night of sleep, logged by the user: when they went to bed, when they woke, and how it felt.
public struct SleepEntry: Identifiable, Hashable, Codable, Sendable {
    public static let qualityRange = 1...5

    public let id: UUID
    public let bedtime: Date
    public let wakeTime: Date
    /// 1 (terrible) to 5 (great), always within `qualityRange`.
    public let quality: Int

    /// - Throws: `SleepError` if the times don't describe a night of 24 hours or less.
    public init(id: UUID = UUID(), bedtime: Date, wakeTime: Date, quality: Int = 3) throws(SleepError) {
        guard wakeTime > bedtime else { throw .wakeNotAfterBedtime }
        guard wakeTime.timeIntervalSince(bedtime) <= 24 * 3600 else { throw .longerThanADay }
        self.id = id
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.quality = min(max(quality, Self.qualityRange.lowerBound), Self.qualityRange.upperBound)
    }

    private enum CodingKeys: String, CodingKey {
        case id, bedtime, wakeTime, quality
    }

    /// Decoding runs the same validation as creating one, so a damaged file can't produce an impossible night.
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: values.decode(UUID.self, forKey: .id),
            bedtime: values.decode(Date.self, forKey: .bedtime),
            wakeTime: values.decode(Date.self, forKey: .wakeTime),
            quality: values.decode(Int.self, forKey: .quality)
        )
    }

    public var duration: TimeInterval { wakeTime.timeIntervalSince(bedtime) }

    /// A night belongs to the day the user woke up on ("last night" is today's entry).
    public func day(in calendar: Calendar = .current) -> Day {
        Day(wakeTime, calendar: calendar)
    }
}
