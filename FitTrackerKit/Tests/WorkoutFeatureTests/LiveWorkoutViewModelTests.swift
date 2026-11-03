import Foundation
import Testing
import Domain
import TestSupport
@testable import WorkoutFeature

/// Specification for `LiveWorkoutViewModel`: recording a workout from a heart-rate source
/// and saving it. Readings come from `ScriptedHeartRateSource`, so every test is instant
/// and gives the same result each run.
@MainActor
@Suite("Live workout view model")
struct LiveWorkoutViewModelTests {

    let start = Date(timeIntervalSince1970: 1_000_000)
    let calculator: HeartRateZoneCalculator

    init() throws {
        calculator = try HeartRateZoneCalculator(maxHeartRate: 200)
    }

    /// Readings one second apart, starting one second after `start`.
    func readings(_ bpms: [Int]) throws -> [HeartRateSample] {
        try bpms.enumerated().map { index, bpm in
            try HeartRateSample(bpm: bpm, date: start.addingTimeInterval(Double(index + 1)))
        }
    }

    func makeViewModel(
        source: ScriptedHeartRateSource,
        repository: InMemoryWorkoutRepository = InMemoryWorkoutRepository()
    ) -> LiveWorkoutViewModel {
        // The clock is frozen at `start`, so dates in assertions are exact.
        LiveWorkoutViewModel(source: source, repository: repository, calculator: calculator, now: { [start] in start })
    }

    // MARK: - Recording

    @Test("Starts idle, with no reading")
    func startsIdle() {
        let viewModel = makeViewModel(source: ScriptedHeartRateSource(readings: []))

        #expect(viewModel.phase == .idle)
        #expect(viewModel.currentBPM == nil)
        #expect(viewModel.currentZone == nil)
    }

    @Test("Start begins recording from now")
    func startRecords() {
        let viewModel = makeViewModel(source: ScriptedHeartRateSource(readings: []))

        viewModel.start()

        #expect(viewModel.phase == .recording)
        #expect(viewModel.startDate == start)
    }

    @Test("Shows the latest reading and its zone while recording")
    func showsLatestReading() async throws {
        let viewModel = makeViewModel(source: ScriptedHeartRateSource(readings: try readings([120, 150, 170])))

        viewModel.start()
        await viewModel.waitUntilSourceEnds()

        #expect(viewModel.currentBPM == 170)
        #expect(viewModel.currentZone == .threshold)
        #expect(viewModel.sampleCount == 3)
        #expect(viewModel.phase == .recording)
    }

    @Test("Tapping start again while recording is ignored")
    func startTwiceIsIgnored() async throws {
        let viewModel = makeViewModel(source: ScriptedHeartRateSource(readings: try readings([120, 150, 170])))

        viewModel.start()
        viewModel.start()
        await viewModel.waitUntilSourceEnds()

        #expect(viewModel.sampleCount == 3)
    }

    // MARK: - Stopping and saving

    @Test("Stop saves the workout and shows its summary")
    func stopSaves() async throws {
        let repository = InMemoryWorkoutRepository()
        let viewModel = makeViewModel(
            source: ScriptedHeartRateSource(readings: try readings([120, 150, 170])),
            repository: repository
        )
        viewModel.start()
        await viewModel.waitUntilSourceEnds()

        await viewModel.stop()

        let saved = try #require(try await repository.workouts().first)
        #expect(saved.startDate == start)
        #expect(saved.samples.map(\.bpm) == [120, 150, 170])
        // The frozen clock says "now" is still `start`, but the workout must still contain its
        // last reading, so it ends no earlier than that reading.
        #expect(saved.endDate == start.addingTimeInterval(3))

        guard case .finished(let summary) = viewModel.phase else {
            Issue.record("Expected .finished, got \(viewModel.phase)")
            return
        }
        #expect(summary.averageBPM == 147)   // (120 + 150 + 170) / 3 = 146.67
        #expect(summary.maxBPM == 170)
    }

    @Test("If saving fails, shows an error and can retry without losing the workout")
    func saveFailureThenRetry() async throws {
        let repository = InMemoryWorkoutRepository()
        let viewModel = makeViewModel(
            source: ScriptedHeartRateSource(readings: try readings([120, 150])),
            repository: repository
        )
        viewModel.start()
        await viewModel.waitUntilSourceEnds()
        await repository.failNextCalls(with: URLError(.cannotWriteToFile))

        await viewModel.stop()
        #expect(viewModel.phase == .failed(message: LiveWorkoutViewModel.saveFailedMessage))

        await repository.failNextCalls(with: nil)
        await viewModel.retrySave()

        #expect(try await repository.workouts().first?.samples.count == 2)
        guard case .finished = viewModel.phase else {
            Issue.record("Expected .finished after retry, got \(viewModel.phase)")
            return
        }
    }

    @Test("If the monitor fails mid-workout, what was recorded is saved and the user is told")
    func signalLostSavesWorkout() async throws {
        let repository = InMemoryWorkoutRepository()
        let viewModel = makeViewModel(
            source: ScriptedHeartRateSource(readings: try readings([120, 150]), failure: URLError(.networkConnectionLost)),
            repository: repository
        )

        viewModel.start()
        await viewModel.waitUntilSourceEnds()

        #expect(try await repository.workouts().first?.samples.count == 2)
        #expect(viewModel.notice == LiveWorkoutViewModel.signalLostNotice)
        guard case .finished = viewModel.phase else {
            Issue.record("Expected .finished, got \(viewModel.phase)")
            return
        }
    }

    // MARK: - Starting over

    @Test("Reset returns to idle and clears the last workout")
    func resetClears() async throws {
        let viewModel = makeViewModel(source: ScriptedHeartRateSource(readings: try readings([120])))
        viewModel.start()
        await viewModel.waitUntilSourceEnds()
        await viewModel.stop()

        viewModel.reset()

        #expect(viewModel.phase == .idle)
        #expect(viewModel.currentBPM == nil)
        #expect(viewModel.sampleCount == 0)
        #expect(viewModel.notice == nil)
    }
}
