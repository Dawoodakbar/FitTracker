import Observation
import Domain

/// The state and actions behind the workout history screen.
///
/// The view renders `state` and calls `load()` / `delete(_:)`; it contains no logic of its own.
/// `@MainActor` because SwiftUI reads `state` on the main thread; the repository does its
/// work elsewhere and the `await`s hop back here with the results.
@MainActor
@Observable
public final class WorkoutHistoryViewModel {
    /// Every situation the screen can be in. An enum makes impossible combinations
    /// (like "loading" and "failed" at once) impossible to represent.
    public enum State: Equatable {
        case loading
        case empty
        case loaded([WorkoutHistoryRow])
        case failed(message: String)
    }

    static let loadFailedMessage = "Check your connection and try again."
    static let deleteFailedMessage = "Couldn't delete the workout. Please try again."

    public private(set) var state: State = .loading
    /// Set when a delete fails; the view shows it as an alert and clears it on dismiss.
    public var deleteError: String?

    private let repository: any WorkoutRepository
    /// The user's zones. The app updates it when settings change; it applies to the next load or reading.
    public var calculator: HeartRateZoneCalculator

    /// - Parameters:
    ///   - repository: Where workouts come from. The app passes the real one; tests a fake.
    ///   - calculator: The user's zones, used to summarize each workout.
    public init(repository: any WorkoutRepository, calculator: HeartRateZoneCalculator) {
        self.repository = repository
        self.calculator = calculator
    }

    /// Loads (or reloads) the list. Safe to call again to retry after a failure.
    public func load() async {
        do {
            let rows = try await repository.workouts().map {
                WorkoutHistoryRow(workout: $0, calculator: calculator)
            }
            state = rows.isEmpty ? .empty : .loaded(rows)
        } catch {
            // Features never show raw framework errors; they map them to a friendly message.
            state = .failed(message: Self.loadFailedMessage)
        }
    }

    /// Deletes a workout, then reloads so the list always mirrors the repository.
    /// On failure the list is left unchanged and `deleteError` is set.
    public func delete(_ id: Workout.ID) async {
        do {
            try await repository.delete(id: id)
        } catch {
            deleteError = Self.deleteFailedMessage
            return
        }
        await load()
    }
}
