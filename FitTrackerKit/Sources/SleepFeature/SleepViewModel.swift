import Foundation
import Observation
import Domain

/// The state behind the Sleep screen: the journal, last night, and the weekly trend.
@MainActor
@Observable
public final class SleepViewModel {
    /// The commonly recommended minimum for adults, used as the goal line.
    public static let goalHours = 8.0
    static let loadFailedMessage = "Your sleep journal couldn't be loaded."
    static let saveFailedMessage = "That night couldn't be saved. Please try again."
    static let invalidTimesMessage = "Wake-up time must be after bedtime, and the night under 24 hours."

    public private(set) var journal = SleepJournal()
    /// What is on disk, to roll back to if a save fails.
    private var savedJournal = SleepJournal()
    public var errorMessage: String?

    private let store: any SnapshotStore<SleepJournal>
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        store: any SnapshotStore<SleepJournal>,
        now: @escaping @Sendable () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.store = store
        self.now = now
        self.calendar = calendar
    }

    public var today: Day { Day(now(), calendar: calendar) }

    /// The night that ended today, if logged.
    public var lastNight: SleepEntry? { journal.entry(on: today, calendar: calendar) }

    public var weekStats: SleepStats? { journal.stats(endingOn: today, days: 7, calendar: calendar) }

    /// The last 7 days, oldest first, with hours slept (0 for days with nothing logged).
    public var week: [(day: Day, hours: Double)] {
        journal.nights(endingOn: today, days: 7, calendar: calendar).map {
            ($0.day, ($0.entry?.duration ?? 0) / 3600)
        }
    }

    /// Last night as a fraction of the goal, for the Today ring.
    public var goalFraction: Double {
        min((lastNight?.duration ?? 0) / 3600 / Self.goalHours, 1)
    }

    /// A clock time as minutes after midnight, for the sleep dial.
    public func minutesAfterMidnight(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// Suggested times for a new entry: last night 23:00 to this morning 07:00.
    public func suggestedTimes() -> (bedtime: Date, wakeTime: Date) {
        let midnight = today.startDate(in: calendar)
        return (midnight.addingTimeInterval(-3600), midnight.addingTimeInterval(7 * 3600))
    }

    public func load() async {
        do {
            journal = try await store.load() ?? SleepJournal()
            savedJournal = journal
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    /// Logs a night. Returns `false` (and sets `errorMessage`) if it wasn't saved.
    @discardableResult
    public func log(bedtime: Date, wakeTime: Date, quality: Int) async -> Bool {
        let entry: SleepEntry
        do {
            entry = try SleepEntry(bedtime: bedtime, wakeTime: wakeTime, quality: quality)
        } catch {
            errorMessage = Self.invalidTimesMessage
            return false
        }
        journal.log(entry, calendar: calendar)
        return await persist()
    }

    public func delete(_ id: SleepEntry.ID) async {
        journal.remove(id: id)
        await persist()
    }

    /// Saves the change already shown. Changes are applied before the first `await`, so
    /// quick edits are saved in order; if a save fails the screen rolls back to the disk.
    @discardableResult
    private func persist() async -> Bool {
        let snapshot = journal
        do {
            try await store.save(snapshot)
            savedJournal = snapshot
            return true
        } catch {
            journal = savedJournal
            errorMessage = Self.saveFailedMessage
            return false
        }
    }
}
