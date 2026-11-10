/// Walks through a session one step at a time: work, rest, work, ... finished.
///
/// A plain value with no timers, so every transition can be unit tested. The view owns the
/// clock and calls `advance()` when the user taps Done or a countdown ends.
public struct SessionPlayer: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        /// Doing round `round` (1-based) of the exercise at `exercise`.
        case work(exercise: Int, round: Int)
        /// Resting for `seconds` before the step described by `exercise` and `round`.
        case rest(seconds: Int, nextExercise: Int, nextRound: Int)
        case finished
    }

    public let session: PlanSession
    public private(set) var phase: Phase
    /// Rounds finished so far, across all exercises.
    public private(set) var completedRounds: Int

    public init(session: PlanSession) {
        self.session = session
        self.completedRounds = 0
        self.phase = session.exercises.isEmpty ? .finished : .work(exercise: 0, round: 1)
    }

    public var totalRounds: Int { session.exercises.reduce(0) { $0 + $1.rounds } }

    /// 0...1 through the session.
    public var progress: Double {
        totalRounds == 0 ? 1 : Double(completedRounds) / Double(totalRounds)
    }

    /// The exercise being done now, or the one coming up after a rest.
    public var currentExercise: Exercise? {
        switch phase {
        case .work(let index, _), .rest(_, let index, _): session.exercises[index]
        case .finished: nil
        }
    }

    /// Moves to the next step. Does nothing once finished.
    public mutating func advance() {
        switch phase {
        case .work(let index, let round):
            completedRounds += 1
            let exercise = session.exercises[index]
            let next: (exercise: Int, round: Int)? =
                round < exercise.rounds ? (index, round + 1)
                : index + 1 < session.exercises.count ? (index + 1, 1)
                : nil
            guard let next else {
                phase = .finished
                return
            }
            // No rest after the very last round, and none for exercises that flow (rest 0).
            phase = exercise.restSeconds > 0
                ? .rest(seconds: exercise.restSeconds, nextExercise: next.exercise, nextRound: next.round)
                : .work(exercise: next.exercise, round: next.round)
        case .rest(_, let nextExercise, let nextRound):
            phase = .work(exercise: nextExercise, round: nextRound)
        case .finished:
            break
        }
    }
}
