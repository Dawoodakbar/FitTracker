import Foundation
import Observation
import Domain

/// The state behind the plan library and session player: which plans exist, which the
/// user is following, and how far they've got.
@MainActor
@Observable
public final class PlansViewModel {
    static let loadFailedMessage = "Your plan progress couldn't be loaded."
    static let saveFailedMessage = "That session couldn't be saved. Please try again."

    public let plans: [WorkoutPlan]
    public private(set) var progress = PlanProgress()
    /// What is on disk, to roll back to if a save fails.
    private var savedProgress = PlanProgress()
    /// `nil` shows every kind.
    public var kindFilter: ActivityKind?
    /// Set when loading or saving fails; the view shows it as an alert and clears it on dismiss.
    public var errorMessage: String?

    private let store: any SnapshotStore<PlanProgress>
    private let now: @Sendable () -> Date

    public init(
        store: any SnapshotStore<PlanProgress>,
        plans: [WorkoutPlan] = PlanCatalog.all,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.store = store
        self.plans = plans
        self.now = now
    }

    public var visiblePlans: [WorkoutPlan] {
        guard let kindFilter else { return plans }
        return plans.filter { $0.kind == kindFilter }
    }

    /// Plans with at least one session done that aren't finished yet, for "Continue" cards.
    public var activePlans: [WorkoutPlan] {
        plans.filter { progress.completedCount(of: $0) > 0 && progress.nextSession(of: $0) != nil }
    }

    /// Sessions finished today, across all plans.
    public var sessionsToday: Int {
        progress.completions(on: Day(now())).count
    }

    public func load() async {
        do {
            progress = try await store.load() ?? PlanProgress()
            savedProgress = progress
        } catch {
            errorMessage = Self.loadFailedMessage
        }
    }

    /// Records a finished session and saves. On failure the completion is rolled back,
    /// so the screen never keeps progress that isn't on disk.
    public func complete(_ session: PlanSession, of plan: WorkoutPlan) async {
        progress.record(planID: plan.id, sessionID: session.id, at: now())
        let snapshot = progress
        do {
            try await store.save(snapshot)
            savedProgress = snapshot
        } catch {
            progress = savedProgress
            errorMessage = Self.saveFailedMessage
        }
    }
}
