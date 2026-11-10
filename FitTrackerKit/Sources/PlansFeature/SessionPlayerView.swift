import SwiftUI
import Domain
import DesignSystem

/// Plays a session full screen: one exercise at a time with a countdown for timed work and
/// rests, a breathing orb while resting, and confetti at the end.
struct SessionPlayerView: View {
    let plan: WorkoutPlan
    /// Saves the finished session. Called once, when the user taps Finish.
    let onFinish: () async -> Void

    @State private var player: SessionPlayer
    /// When the current countdown ends, or `nil` for rep-based work the user ends themselves.
    @State private var deadline: Date?
    @State private var paused = false
    /// Seconds left when the user paused.
    @State private var pausedRemaining: TimeInterval?
    @State private var confettiStart: Date?
    @Environment(\.dismiss) private var dismiss

    init(plan: WorkoutPlan, session: PlanSession, onFinish: @escaping () async -> Void) {
        self.plan = plan
        self.onFinish = onFinish
        self.player = SessionPlayer(session: session)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.l) {
                ProgressView(value: player.progress)
                    .tint(plan.kind.style.start)
                    .animation(.smooth, value: player.progress)

                Spacer(minLength: 0)
                stage
                    .id(stepID)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                Spacer(minLength: 0)
                controls
            }
            .padding(Spacing.m)
            .calmBackground(isRest ? .sleep : plan.style)
            .animation(.spring(duration: 0.5, bounce: 0.15), value: stepID)
            .overlay { if let confettiStart { ConfettiBurst(startDate: confettiStart) } }
            .navigationTitle(player.session.title)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .onAppear(perform: startStep)
        .onChange(of: stepID) { _, _ in startStep() }
        .sensoryFeedback(.impact(weight: .medium), trigger: stepID)
        .sensoryFeedback(.success, trigger: player.phase == .finished)
        // Keep the screen on, so the countdown stays visible mid-plank.
        .keepsScreenOn()
    }

    // MARK: - Stage

    @ViewBuilder
    private var stage: some View {
        switch player.phase {
        case .work(_, let round):
            if let exercise = player.currentExercise {
                VStack(spacing: Spacing.l) {
                    if plan.kind == .yoga, deadline != nil {
                        BreathingOrb(style: plan.kind.style).frame(maxWidth: 220)
                    } else {
                        Image(systemName: plan.kind.symbol)
                            .font(.system(size: 72))
                            .foregroundStyle(plan.kind.style.gradient)
                            .symbolEffect(.pulse, options: .repeating, isActive: !paused)
                    }
                    Text(exercise.name).font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text("Round \(round) of \(exercise.rounds)").font(.headline).foregroundStyle(.secondary)
                    countdownOrTarget(for: exercise)
                    Text(exercise.cue)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
        case .rest:
            VStack(spacing: Spacing.l) {
                Text("Rest").font(.largeTitle.bold())
                BreathingOrb(style: .sleep).frame(maxWidth: 220)
                countdown
                if let next = player.currentExercise {
                    Text("Next: \(next.name)").font(.headline).foregroundStyle(.secondary)
                }
            }
        case .finished:
            VStack(spacing: Spacing.l) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(plan.kind.style.gradient)
                    .symbolEffect(.bounce, value: confettiStart)
                Text("Session complete").font(.largeTitle.bold())
                Text("\(player.totalRounds) rounds · about \(player.session.estimatedMinutes) min")
                    .foregroundStyle(.secondary)
            }
            .onAppear { confettiStart = .now }
        }
    }

    @ViewBuilder
    private func countdownOrTarget(for exercise: Exercise) -> some View {
        if case .reps(_, let reps) = exercise.target {
            Text("\(reps) reps")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(plan.kind.style.gradient)
        } else {
            countdown
        }
    }

    /// The remaining seconds, redrawn on a timeline. When it reaches zero the step advances.
    private var countdown: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
            let remaining = remaining(at: timeline.date)
            Text(Duration.seconds(remaining.rounded(.up)), format: .time(pattern: .minuteSecond))
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .foregroundStyle(plan.kind.style.gradient)
                .onChange(of: remaining <= 0) { _, isDone in
                    if isDone, !paused { advance() }
                }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: Spacing.m) {
            if player.phase == .finished {
                Button("Finish", systemImage: "checkmark") {
                    Task {
                        await onFinish()
                        dismiss()
                    }
                }
                .buttonStyle(.glassProminent)
                .tint(plan.kind.style.start)
            } else {
                if deadline != nil || pausedRemaining != nil {
                    Button(paused ? "Resume" : "Pause", systemImage: paused ? "play.fill" : "pause.fill", action: togglePause)
                        .buttonStyle(.glass)
                }
                Button(isRest ? "Skip Rest" : "Done", systemImage: "forward.fill", action: advance)
                    .buttonStyle(.glassProminent)
                    .tint(plan.kind.style.end)
                    .foregroundStyle(Palette.night)
            }
        }
        .controlSize(.extraLarge)
    }

    // MARK: - Timing

    /// Changes whenever the step changes, to drive transitions and haptics.
    private var stepID: String {
        switch player.phase {
        case .work(let exercise, let round): "work-\(exercise)-\(round)"
        case .rest(_, let exercise, let round): "rest-\(exercise)-\(round)"
        case .finished: "finished"
        }
    }

    private var isRest: Bool {
        if case .rest = player.phase { true } else { false }
    }

    private func startStep() {
        paused = false
        pausedRemaining = nil
        switch player.phase {
        case .rest(let seconds, _, _):
            deadline = .now.addingTimeInterval(TimeInterval(seconds))
        case .work:
            if case .timed(_, let seconds) = player.currentExercise?.target {
                deadline = .now.addingTimeInterval(TimeInterval(seconds))
            } else {
                deadline = nil
            }
        case .finished:
            deadline = nil
        }
    }

    private func remaining(at date: Date) -> TimeInterval {
        if let pausedRemaining { return pausedRemaining }
        guard let deadline else { return 0 }
        return max(deadline.timeIntervalSince(date), 0)
    }

    private func togglePause() {
        if paused, let pausedRemaining {
            deadline = .now.addingTimeInterval(pausedRemaining)
            self.pausedRemaining = nil
        } else {
            pausedRemaining = remaining(at: .now)
            deadline = nil
        }
        paused.toggle()
    }

    private func advance() {
        player.advance()
    }
}
