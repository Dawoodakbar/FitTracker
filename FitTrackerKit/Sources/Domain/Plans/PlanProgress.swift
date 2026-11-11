import Foundation

/// Which plan sessions the user has finished, and when.
public struct PlanProgress: Codable, Equatable, Sendable {
    public struct Completion: Codable, Hashable, Sendable {
        public let planID: String
        public let sessionID: String
        public let date: Date
    }

    public private(set) var completions: [Completion]

    public init(completions: [Completion] = []) {
        self.completions = completions
    }

    public mutating func record(planID: String, sessionID: String, at date: Date) {
        completions.append(Completion(planID: planID, sessionID: sessionID, date: date))
    }

    /// How many sessions of `plan` have been finished, capped at the plan's total.
    public func completedCount(of plan: WorkoutPlan) -> Int {
        min(completions.count { $0.planID == plan.id }, plan.totalSessions)
    }

    /// 0...1, for progress rings and bars.
    public func fraction(of plan: WorkoutPlan) -> Double {
        plan.totalSessions == 0 ? 0 : Double(completedCount(of: plan)) / Double(plan.totalSessions)
    }

    /// The session to do next: sessions rotate in order (A, B, C, A, ...). `nil` once the plan is done.
    public func nextSession(of plan: WorkoutPlan) -> PlanSession? {
        let done = completedCount(of: plan)
        guard !plan.sessions.isEmpty, done < plan.totalSessions else { return nil }
        return plan.sessions[done % plan.sessions.count]
    }

    /// Sessions finished on `day`, across all plans.
    public func completions(on day: Day, calendar: Calendar = .current) -> [Completion] {
        completions.filter { Day($0.date, calendar: calendar) == day }
    }
}
