import Foundation
import Testing
import Domain
import TestSupport
@testable import HistoryFeature

/// Specification for `WorkoutHistoryViewModel`: loading, empty, error and delete behaviour.
///
/// `@MainActor` because the view model is main-actor isolated, like all UI state.
/// No simulator or view is involved: the view model is plain Swift fed by the in-memory fake.
@MainActor
@Suite("Workout history view model")
struct WorkoutHistoryViewModelTests {

    let start = Date(timeIntervalSince1970: 1_000_000)
    let calculator: HeartRateZoneCalculator

    init() throws {
        calculator = try HeartRateZoneCalculator(maxHeartRate: 200)
    }

    /// A 30-minute workout starting `hours` after `start`, at a steady `bpm`.
    func workout(startingAfter hours: Double, bpm: Int = 150) throws -> Workout {
        let startDate = start.addingTimeInterval(hours * 3600)
        return try Workout(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(1800),
            samples: [HeartRateSample(bpm: bpm, date: startDate)]
        )
    }

    func makeViewModel(_ repository: InMemoryWorkoutRepository) -> WorkoutHistoryViewModel {
        WorkoutHistoryViewModel(repository: repository, calculator: calculator)
    }

    // MARK: - Loading

    @Test("Starts in the loading state")
    func startsLoading() {
        let viewModel = makeViewModel(InMemoryWorkoutRepository())

        #expect(viewModel.state == .loading)
    }

    @Test("Shows saved workouts newest first, each with its summary")
    func loadsRows() async throws {
        let older = try workout(startingAfter: 0, bpm: 120)   // endurance
        let newer = try workout(startingAfter: 1, bpm: 170)   // threshold
        let viewModel = makeViewModel(InMemoryWorkoutRepository(workouts: [older, newer]))

        await viewModel.load()

        let rows = try #require(viewModel.state.rows)
        #expect(rows.map(\.id) == [newer.id, older.id])
        #expect(rows.map(\.summary.mainZone) == [.threshold, .endurance])
        #expect(rows.first?.summary.averageBPM == 170)
    }

    @Test("Shows the empty state when there are no workouts")
    func loadsEmpty() async {
        let viewModel = makeViewModel(InMemoryWorkoutRepository())

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("Shows an error when loading fails, and recovers on retry")
    func loadFailureThenRetry() async throws {
        let repository = InMemoryWorkoutRepository(workouts: [try workout(startingAfter: 0)])
        let viewModel = makeViewModel(repository)
        await repository.failNextCalls(with: URLError(.notConnectedToInternet))

        await viewModel.load()
        #expect(viewModel.state == .failed(message: WorkoutHistoryViewModel.loadFailedMessage))

        await repository.failNextCalls(with: nil)
        await viewModel.load()
        #expect(viewModel.state.rows?.count == 1)
    }

    // MARK: - Deleting

    @Test("Deleting removes the row")
    func deleteRemovesRow() async throws {
        let keep = try workout(startingAfter: 0)
        let remove = try workout(startingAfter: 1)
        let viewModel = makeViewModel(InMemoryWorkoutRepository(workouts: [keep, remove]))
        await viewModel.load()

        await viewModel.delete(remove.id)

        #expect(viewModel.state.rows?.map(\.id) == [keep.id])
    }

    @Test("Deleting the last workout shows the empty state")
    func deleteLastShowsEmpty() async throws {
        let only = try workout(startingAfter: 0)
        let viewModel = makeViewModel(InMemoryWorkoutRepository(workouts: [only]))
        await viewModel.load()

        await viewModel.delete(only.id)

        #expect(viewModel.state == .empty)
    }

    @Test("A failed delete keeps the list and reports the error")
    func deleteFailureKeepsRows() async throws {
        let saved = try workout(startingAfter: 0)
        let repository = InMemoryWorkoutRepository(workouts: [saved])
        let viewModel = makeViewModel(repository)
        await viewModel.load()
        await repository.failNextCalls(with: URLError(.timedOut))

        await viewModel.delete(saved.id)

        #expect(viewModel.state.rows?.map(\.id) == [saved.id])
        #expect(viewModel.deleteError == WorkoutHistoryViewModel.deleteFailedMessage)
    }
}

private extension WorkoutHistoryViewModel.State {
    /// The rows when loaded, otherwise `nil`. Keeps the tests free of `if case` noise.
    var rows: [WorkoutHistoryRow]? {
        if case .loaded(let rows) = self { rows } else { nil }
    }
}
