import Foundation
import Observation
import Domain

/// The state behind the Medication screen: today's checklist, adherence, and refill warnings.
@MainActor
@Observable
public final class MedicationViewModel {
    static let loadFailedMessage = "Your medications couldn't be loaded."
    static let saveFailedMessage = "That change couldn't be saved. Please try again."
    static let emptyNameMessage = "Enter a name for the medication."
    static let noTimesMessage = "Add at least one time of day."

    public private(set) var book = MedicationBook()
    /// What is on disk, to roll back to if a save fails.
    private var savedBook = MedicationBook()
    public var errorMessage: String?

    private let store: any SnapshotStore<MedicationBook>
    private let reminders: any MedicationReminders
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        store: any SnapshotStore<MedicationBook>,
        reminders: any MedicationReminders = NoMedicationReminders(),
        now: @escaping @Sendable () -> Date = { .now },
        calendar: Calendar = .current
    ) {
        self.store = store
        self.reminders = reminders
        self.now = now
        self.calendar = calendar
    }

    public var today: Day { Day(now(), calendar: calendar) }
    public var todaysDoses: [ScheduledDose] { book.doses(on: today) }

    /// Taken doses as a fraction of today's, for the Today ring. 0 when nothing is scheduled.
    public var todayFraction: Double {
        let doses = todaysDoses
        guard !doses.isEmpty else { return 0 }
        return Double(doses.count { $0.status == .taken }) / Double(doses.count)
    }

    public var weekAdherence: Double? { book.adherence(endingOn: today, days: 7, calendar: calendar) }

    public func load() async {
        do {
            book = try await store.load() ?? MedicationBook()
            savedBook = book
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    /// Adds or updates a medication. Returns `false` (and sets `errorMessage`) if it wasn't saved.
    @discardableResult
    public func save(_ medication: Medication) async -> Bool {
        guard !medication.name.isEmpty else {
            errorMessage = Self.emptyNameMessage
            return false
        }
        guard !medication.times.isEmpty else {
            errorMessage = Self.noTimesMessage
            return false
        }
        book.save(medication)
        return await persist(resyncReminders: true)
    }

    public func remove(_ id: Medication.ID) async {
        book.remove(id: id)
        await persist(resyncReminders: true)
    }

    /// One tap marks a dose taken; tapping again clears it.
    public func toggleTaken(_ dose: ScheduledDose) async {
        book.mark(dose.key, as: book.records[dose.key] == .taken ? nil : .taken)
        await persist(resyncReminders: false)
    }

    public func skip(_ dose: ScheduledDose) async {
        book.mark(dose.key, as: .skipped)
        await persist(resyncReminders: false)
    }

    /// Saves the change already shown. Changes are applied before the first `await`, so
    /// quick taps are saved in order; if a save fails the screen rolls back to the disk.
    @discardableResult
    private func persist(resyncReminders: Bool) async -> Bool {
        let snapshot = book
        do {
            try await store.save(snapshot)
            savedBook = snapshot
        } catch {
            book = savedBook
            errorMessage = Self.saveFailedMessage
            return false
        }
        if resyncReminders {
            await reminders.sync(with: snapshot.medications)
        }
        return true
    }
}
