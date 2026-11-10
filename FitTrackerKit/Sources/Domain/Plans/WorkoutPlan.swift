/// The kinds of training the app offers plans for. Raw values are stored on disk.
public enum ActivityKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case strength
    case yoga
    case hiit
    case running
    case mobility

    public var id: Self { self }
}

public enum PlanLevel: String, CaseIterable, Codable, Sendable {
    case beginner
    case intermediate
    case advanced
}

/// What the user needs to follow a plan. Lets people filter to what they have at home.
public enum Equipment: String, CaseIterable, Codable, Sendable {
    case none
    case dumbbells
    case gym
}

/// One movement inside a session, with how much of it to do.
public struct Exercise: Identifiable, Hashable, Sendable {
    /// How the work is measured.
    public enum Target: Hashable, Sendable {
        /// `sets` sets of `reps` repetitions, e.g. 3 × 10.
        case reps(sets: Int, reps: Int)
        /// `rounds` rounds held or performed for `seconds` each, e.g. a 30-second plank.
        case timed(rounds: Int, seconds: Int)
    }

    public let id: String
    public let name: String
    public let target: Target
    /// Rest after each round, in seconds. Zero for flowing sequences like yoga.
    public let restSeconds: Int
    /// One short form tip shown while the exercise is active.
    public let cue: String

    public init(_ name: String, _ target: Target, rest restSeconds: Int = 0, cue: String) {
        self.id = name.lowercased().replacing(" ", with: "-")
        self.name = name
        self.target = target
        self.restSeconds = max(restSeconds, 0)
        self.cue = cue
    }

    /// How many times the user performs this exercise (sets or rounds). Always at least 1.
    public var rounds: Int {
        switch target {
        case .reps(let sets, _): max(sets, 1)
        case .timed(let rounds, _): max(rounds, 1)
        }
    }

    /// A rough length for one round, used for the session's estimated time.
    var secondsPerRound: Int {
        switch target {
        case .reps(_, let reps): reps * 3
        case .timed(_, let seconds): seconds
        }
    }
}

/// One workout of a plan: an ordered list of exercises.
public struct PlanSession: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let exercises: [Exercise]

    public init(id: String, title: String, exercises: [Exercise]) {
        self.id = id
        self.title = title
        self.exercises = exercises
    }

    /// Work plus rest, rounded up to whole minutes.
    public var estimatedMinutes: Int {
        let seconds = exercises.reduce(0) { $0 + $1.rounds * ($1.secondsPerRound + $1.restSeconds) }
        return max(1, (seconds + 59) / 60)
    }
}

/// A training plan: a few sessions the user repeats each week.
public struct WorkoutPlan: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let kind: ActivityKind
    public let level: PlanLevel
    public let equipment: Equipment
    public let weeks: Int
    public let sessions: [PlanSession]

    public init(
        id: String,
        title: String,
        summary: String,
        kind: ActivityKind,
        level: PlanLevel,
        equipment: Equipment,
        weeks: Int,
        sessions: [PlanSession]
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.kind = kind
        self.level = level
        self.equipment = equipment
        self.weeks = weeks
        self.sessions = sessions
    }

    /// Completing every session once per week for the whole plan.
    public var totalSessions: Int { sessions.count * weeks }
}
