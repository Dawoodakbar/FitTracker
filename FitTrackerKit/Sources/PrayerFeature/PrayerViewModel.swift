import Foundation
import Observation
import Domain

/// The state behind the Prayer screen: today's five prayers, the week, and the streak.
@MainActor
@Observable
public final class PrayerViewModel {
    static let loadFailedMessage = "Your prayer log couldn't be loaded."
    static let saveFailedMessage = "That change couldn't be saved. Please try again."

    public private(set) var journal = PrayerJournal()
    /// What is on disk, to roll back to if a save fails.
    private var savedJournal = PrayerJournal()
    /// The day being viewed. Defaults to today; the user can step back to fill in earlier days.
    public var selectedDay: Day
    public var errorMessage: String?

    private let store: any SnapshotStore<PrayerJournal>
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        store: any SnapshotStore<PrayerJournal>,
        now: @escaping @Sendable () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.store = store
        self.now = now
        self.calendar = calendar
        self.selectedDay = Day(now(), calendar: calendar)
    }

    public var today: Day { Day(now(), calendar: calendar) }
    public var streak: Int { journal.streak(endingOn: today, calendar: calendar) }

    /// Today's prayers as a fraction of five, for the Today ring.
    public var todayFraction: Double {
        Double(journal.count(on: today)) / Double(DailyPrayer.allCases.count)
    }

    /// The last 7 days ending today, oldest first, each with its fraction complete.
    public var week: [(day: Day, fraction: Double)] {
        today.lastDays(7, calendar: calendar).map {
            ($0, Double(journal.count(on: $0)) / Double(DailyPrayer.allCases.count))
        }
    }

    public var canGoForward: Bool { selectedDay < today }

    public func step(days: Int) {
        let target = selectedDay.adding(days: days, calendar: calendar)
        selectedDay = min(target, today)
    }

    public func status(of prayer: DailyPrayer) -> PrayerStatus? {
        journal.status(of: prayer, on: selectedDay)
    }

    public func load() async {
        do {
            journal = try await store.load() ?? PrayerJournal()
            savedJournal = journal
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    /// Not prayed → on time → late → not prayed, on the selected day.
    ///
    /// The screen updates at once and the save follows. Each change is applied before the
    /// first `await`, so quick taps queue up in order instead of overwriting each other.
    public func cycle(_ prayer: DailyPrayer) async {
        journal.cycle(prayer, on: selectedDay)
        let snapshot = journal
        do {
            try await store.save(snapshot)
            savedJournal = snapshot
        } catch {
            journal = savedJournal
            errorMessage = Self.saveFailedMessage
        }
    }
}
