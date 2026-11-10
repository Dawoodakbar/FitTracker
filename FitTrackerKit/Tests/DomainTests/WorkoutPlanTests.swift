import Foundation
import Testing
@testable import Domain

@Suite("Workout plans")
struct WorkoutPlanTests {
    let session = PlanSession(id: "a", title: "A", exercises: [
        Exercise("Squat", .reps(sets: 2, reps: 10), rest: 30, cue: ""),
        Exercise("Plank", .timed(rounds: 1, seconds: 30), cue: "")
    ])

    var plan: WorkoutPlan {
        WorkoutPlan(
            id: "p", title: "P", summary: "", kind: .strength, level: .beginner, equipment: .none,
            weeks: 2, sessions: [session, PlanSession(id: "b", title: "B", exercises: session.exercises)]
        )
    }

    // MARK: - Catalog

    @Test("Every catalog plan has sessions, and ids are unique")
    func catalogIsValid() {
        #expect(Set(PlanCatalog.all.map(\.id)).count == PlanCatalog.all.count)
        for plan in PlanCatalog.all {
            #expect(!plan.sessions.isEmpty, "\(plan.id) has no sessions")
            #expect(plan.sessions.allSatisfy { !$0.exercises.isEmpty }, "\(plan.id) has an empty session")
        }
    }

    @Test("The catalog covers every kind of activity")
    func catalogCoversKinds() {
        #expect(Set(PlanCatalog.all.map(\.kind)) == Set(ActivityKind.allCases))
    }

    @Test("Estimated minutes round up work plus rest")
    func estimatedMinutes() {
        // Squat: 2 × (10 reps × 3 s + 30 s rest) = 120 s. Plank: 30 s. Total 150 s → 3 min.
        #expect(session.estimatedMinutes == 3)
    }

    // MARK: - Progress

    @Test("Sessions rotate in order and the plan ends after weeks × sessions")
    func rotation() {
        var progress = PlanProgress()
        var seen: [String] = []
        while let next = progress.nextSession(of: plan) {
            seen.append(next.id)
            progress.record(planID: plan.id, sessionID: next.id, at: .now)
        }
        #expect(seen == ["a", "b", "a", "b"])
        #expect(progress.fraction(of: plan) == 1)
    }

    @Test("Other plans' completions don't count")
    func countsOnlyThisPlan() {
        var progress = PlanProgress()
        progress.record(planID: "other", sessionID: "a", at: .now)
        #expect(progress.completedCount(of: plan) == 0)
    }

    @Test("Completions are grouped by day")
    func completionsOnDay() {
        var progress = PlanProgress()
        progress.record(planID: "p", sessionID: "a", at: date(march3, 9))
        progress.record(planID: "p", sessionID: "b", at: date(march3.adding(days: 1, calendar: utc), 9))
        #expect(progress.completions(on: march3, calendar: utc).count == 1)
    }

    // MARK: - Player

    @Test("The player goes work, rest, work, then straight on when there's no rest")
    func playerSequence() {
        var player = SessionPlayer(session: session)
        #expect(player.phase == .work(exercise: 0, round: 1))
        player.advance()
        #expect(player.phase == .rest(seconds: 30, nextExercise: 0, nextRound: 2))
        player.advance()
        #expect(player.phase == .work(exercise: 0, round: 2))
        player.advance()
        #expect(player.phase == .rest(seconds: 30, nextExercise: 1, nextRound: 1))
        player.advance()
        #expect(player.phase == .work(exercise: 1, round: 1))
        player.advance()
        #expect(player.phase == .finished)
        #expect(player.progress == 1)
    }

    @Test("Advancing a finished player does nothing")
    func finishedIsFinal() {
        var player = SessionPlayer(session: PlanSession(id: "x", title: "", exercises: []))
        player.advance()
        #expect(player.phase == .finished)
    }
}
