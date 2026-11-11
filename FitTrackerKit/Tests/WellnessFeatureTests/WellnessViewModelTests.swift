import Foundation
import Testing
import Domain
import TestSupport
@testable import PlansFeature
@testable import SleepFeature
@testable import MedicationFeature
@testable import PrayerFeature

private struct DiskFull: Error {}

private let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// 3 March 2027, 12:00 UTC.
private let noon = Date(timeIntervalSince1970: 1_804_075_200)

@MainActor
@Suite("Wellness view models")
struct WellnessViewModelTests {

    // MARK: - Plans

    @Test("Completing a session saves it and moves to the next one")
    func planCompletion() async throws {
        let store = InMemorySnapshotStore<PlanProgress>()
        let viewModel = PlansViewModel(store: store, now: { noon })
        let plan = try #require(PlanCatalog.plan(id: "home-strength"))
        await viewModel.load()

        await viewModel.complete(plan.sessions[0], of: plan)

        #expect(viewModel.progress.nextSession(of: plan)?.id == "b")
        #expect(viewModel.activePlans.map(\.id) == ["home-strength"])
        #expect(try await store.load()?.completions.count == 1)
    }

    @Test("A failed save rolls the completion back")
    func planSaveFails() async throws {
        let store = InMemorySnapshotStore<PlanProgress>()
        await store.failNextCalls(with: DiskFull())
        let viewModel = PlansViewModel(store: store)
        let plan = try #require(PlanCatalog.all.first)

        await viewModel.complete(plan.sessions[0], of: plan)

        #expect(viewModel.progress.completions.isEmpty)
        #expect(viewModel.errorMessage == PlansViewModel.saveFailedMessage)
    }

    @Test("The kind filter narrows the library")
    func planFilter() {
        let viewModel = PlansViewModel(store: InMemorySnapshotStore())
        viewModel.kindFilter = .yoga
        #expect(!viewModel.visiblePlans.isEmpty)
        #expect(viewModel.visiblePlans.allSatisfy { $0.kind == .yoga })
    }

    // MARK: - Sleep

    @Test("Logging a night shows it as last night and against the goal")
    func sleepLog() async {
        let viewModel = SleepViewModel(store: InMemorySnapshotStore(), now: { noon }, calendar: utc)
        let times = viewModel.suggestedTimes()

        let saved = await viewModel.log(bedtime: times.bedtime, wakeTime: times.wakeTime, quality: 4)

        #expect(saved)
        #expect(viewModel.lastNight?.duration == TimeInterval(8 * 3600))
        #expect(viewModel.goalFraction == 1)
        #expect(viewModel.week.last?.hours == 8)
    }

    @Test("Impossible times aren't saved")
    func sleepInvalid() async {
        let store = InMemorySnapshotStore<SleepJournal>()
        let viewModel = SleepViewModel(store: store, now: { noon }, calendar: utc)

        let saved = await viewModel.log(bedtime: noon, wakeTime: noon.addingTimeInterval(-60), quality: 3)

        #expect(!saved)
        #expect(viewModel.errorMessage == SleepViewModel.invalidTimesMessage)
        #expect(await store.saveCount == 0)
    }

    @Test("A failed save leaves the journal unchanged")
    func sleepSaveFails() async {
        let store = InMemorySnapshotStore<SleepJournal>()
        await store.failNextCalls(with: DiskFull())
        let viewModel = SleepViewModel(store: store, now: { noon }, calendar: utc)
        let times = viewModel.suggestedTimes()

        await viewModel.log(bedtime: times.bedtime, wakeTime: times.wakeTime, quality: 3)

        #expect(viewModel.journal.entries.isEmpty)
        #expect(viewModel.errorMessage == SleepViewModel.saveFailedMessage)
    }

    // MARK: - Medication

    actor RecordingReminders: MedicationReminders {
        private(set) var synced: [[Medication]] = []
        func sync(with medications: [Medication]) { synced.append(medications) }
    }

    @Test("Saving a medication syncs reminders; marking a dose doesn't")
    func medicationReminders() async throws {
        let reminders = RecordingReminders()
        let viewModel = MedicationViewModel(store: InMemorySnapshotStore(), reminders: reminders, now: { noon }, calendar: utc)
        let med = Medication(name: "Vitamin D", times: [DoseTime(hour: 9)], startDay: viewModel.today)

        await viewModel.save(med)
        let dose = try #require(viewModel.todaysDoses.first)
        await viewModel.toggleTaken(dose)

        #expect(viewModel.todayFraction == 1)
        #expect(await reminders.synced.count == 1)
    }

    @Test("A medication needs a name and a time", arguments: [("", [DoseTime(hour: 8)]), ("Iron", [])])
    func medicationValidation(name: String, times: [DoseTime]) async {
        let viewModel = MedicationViewModel(store: InMemorySnapshotStore(), now: { noon }, calendar: utc)
        let saved = await viewModel.save(Medication(name: name, times: times, startDay: viewModel.today))
        #expect(!saved)
        #expect(viewModel.book.medications.isEmpty)
    }

    // MARK: - Prayer

    @Test("Cycling prayers updates today's fraction and the streak")
    func prayerCycle() async {
        let viewModel = PrayerViewModel(store: InMemorySnapshotStore(), now: { noon }, calendar: utc)
        for prayer in DailyPrayer.allCases { await viewModel.cycle(prayer) }
        #expect(viewModel.todayFraction == 1)
        #expect(viewModel.streak == 1)
    }

    @Test("You can't step past today")
    func prayerNoFuture() {
        let viewModel = PrayerViewModel(store: InMemorySnapshotStore(), now: { noon }, calendar: utc)
        viewModel.step(days: 1)
        #expect(viewModel.selectedDay == viewModel.today)
        viewModel.step(days: -1)
        #expect(viewModel.canGoForward)
    }
}

@MainActor
@Suite("Wellness view models: quick taps")
struct QuickTapTests {
    @Test("Taps made before earlier saves finish are all kept, in order")
    func rapidPrayerTaps() async throws {
        let store = InMemorySnapshotStore<PrayerJournal>()
        let viewModel = PrayerViewModel(store: store, now: { noon }, calendar: utc)

        // Start every tap before awaiting any of them, like fast tapping on screen.
        await withTaskGroup(of: Void.self) { group in
            for prayer in DailyPrayer.allCases {
                group.addTask { await viewModel.cycle(prayer) }
            }
        }

        #expect(viewModel.todayFraction == 1)
        #expect(try await store.load()?.count(on: viewModel.today) == 5)
    }

    @Test("A change shows immediately, before its save finishes")
    func optimistic() async {
        let viewModel = PrayerViewModel(store: InMemorySnapshotStore(), now: { noon }, calendar: utc)
        let task = Task { await viewModel.cycle(.fajr) }
        // The task hasn't run yet; once it starts, the change lands before the save's `await`.
        await Task.yield()
        #expect(viewModel.status(of: .fajr) == .onTime)
        await task.value
    }

    @Test("A failed save rolls the screen back to what's on disk")
    func rollback() async {
        let store = InMemorySnapshotStore<PrayerJournal>()
        await store.failNextCalls(with: DiskFull())
        let viewModel = PrayerViewModel(store: store, now: { noon }, calendar: utc)

        await viewModel.cycle(.fajr)

        #expect(viewModel.status(of: .fajr) == nil)
        #expect(viewModel.errorMessage == PrayerViewModel.saveFailedMessage)
    }
}
