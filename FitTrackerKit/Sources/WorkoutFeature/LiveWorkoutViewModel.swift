import Foundation
import Observation
import Domain

/// Records a workout live: listens to a `HeartRateSource`, shows the current reading and
/// zone, and saves the finished workout through a `WorkoutRepository`.
@MainActor
@Observable
public final class LiveWorkoutViewModel {
    /// Where the screen is in the record → save flow.
    public enum Phase: Equatable {
        case idle
        case recording
        case saving
        case finished(WorkoutSummary)
        case failed(message: String)
    }

    static let saveFailedMessage = "Your workout couldn't be saved. Try again."
    static let noSignalMessage = "No heart-rate signal. Check that Bluetooth is on and your monitor is on and nearby."
    static let signalLostNotice = "The heart-rate signal was lost, so the workout was saved early."

    public private(set) var phase: Phase = .idle
    public private(set) var startDate: Date?
    public private(set) var currentBPM: Int?
    public private(set) var currentZone: HeartRateZone?
    /// A one-off message shown with the result, e.g. why recording stopped early.
    public private(set) var notice: String?

    /// How many readings have been recorded so far.
    public var sampleCount: Int { samples.count }

    private var samples: [HeartRateSample] = []
    /// The workout waiting to be saved again after a failed save.
    private var unsavedWorkout: Workout?
    private var recordingTask: Task<Void, Never>?

    private let source: any HeartRateSource
    private let repository: any WorkoutRepository
    private let calculator: HeartRateZoneCalculator
    private let now: @Sendable () -> Date

    public init(
        source: any HeartRateSource,
        repository: any WorkoutRepository,
        calculator: HeartRateZoneCalculator,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.source = source
        self.repository = repository
        self.calculator = calculator
        self.now = now
    }

    // MARK: - Actions

    /// Starts recording. Does nothing if a workout is already being recorded or saved.
    public func start() {
        guard phase == .idle else { return }
        samples = []
        notice = nil
        startDate = now()
        phase = .recording

        // This task runs on the main actor (it inherits it), so `record` can update state
        // directly. Each `await` on the stream suspends without blocking the UI.
        recordingTask = Task { [source] in
            do {
                for try await reading in source.readings() {
                    record(reading)
                }
            } catch {
                // A cancelled task ends the loop normally; any thrown error means the source failed.
                guard phase == .recording else { return }
                // Nothing was recorded (Bluetooth off, no monitor found): don't save an empty workout.
                guard !samples.isEmpty else {
                    phase = .failed(message: Self.noSignalMessage)
                    return
                }
                notice = Self.signalLostNotice
                await finishAndSave()
            }
        }
    }

    /// Stops recording and saves the workout.
    public func stop() async {
        guard phase == .recording else { return }
        recordingTask?.cancel()
        recordingTask = nil
        await finishAndSave()
    }

    /// Tries the last failed save again.
    public func retrySave() async {
        guard case .failed = phase else { return }
        guard let unsavedWorkout else {
            // The failure was "no heart-rate signal", so there's nothing to save: start over.
            reset()
            start()
            return
        }
        await save(unsavedWorkout)
    }

    /// Clears the finished workout so a new one can start.
    public func reset() {
        recordingTask?.cancel()
        recordingTask = nil
        phase = .idle
        startDate = nil
        currentBPM = nil
        currentZone = nil
        notice = nil
        samples = []
        unsavedWorkout = nil
    }

    // MARK: - Testing

    /// Waits until the current recording task ends (the source finished or failed).
    func waitUntilSourceEnds() async {
        await recordingTask?.value
    }

    // MARK: - Private

    private func record(_ reading: HeartRateSample) {
        // A reading stamped before the workout began (a sensor's clock can lag) would make
        // the workout invalid, so it's ignored.
        guard let startDate, reading.date >= startDate else { return }
        samples.append(reading)
        currentBPM = reading.bpm
        currentZone = calculator.zone(for: reading.bpm)
    }

    private func finishAndSave() async {
        guard let startDate else { return }
        // A sensor's clock can run slightly ahead of the phone's, so the workout ends no
        // earlier than its last reading; otherwise `Workout` would reject that reading.
        let endDate = max(now(), samples.last?.date ?? startDate)
        do {
            let workout = try Workout(startDate: startDate, endDate: endDate, samples: samples)
            await save(workout)
        } catch {
            phase = .failed(message: Self.saveFailedMessage)
        }
    }

    private func save(_ workout: Workout) async {
        phase = .saving
        do {
            try await repository.save(workout)
            unsavedWorkout = nil
            phase = .finished(WorkoutSummary(workout: workout, calculator: calculator))
        } catch {
            unsavedWorkout = workout
            phase = .failed(message: Self.saveFailedMessage)
        }
    }
}
