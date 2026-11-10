import SwiftUI
import Domain
import DesignSystem

/// One plan: its progress, its sessions and their exercises, and a Start button.
struct PlanDetailView: View {
    let plan: WorkoutPlan
    let viewModel: PlansViewModel
    @State private var playing: PlanSession?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                header
                ForEach(plan.sessions) { session in
                    SessionCard(session: session, isNext: session.id == next?.id) {
                        playing = session
                    }
                }
            }
            .padding(Spacing.m)
        }
        .navigationTitle(plan.title)
        .inlineNavigationTitle()
        .safeAreaInset(edge: .bottom) {
            if let next {
                Button("Start \(next.title)", systemImage: "play.fill") { playing = next }
                    .buttonStyle(.glassProminent)
                    .controlSize(.extraLarge)
                    .tint(plan.kind.style.start)
                    .padding(.bottom, Spacing.m)
            }
        }
        .fullScreenPresentation(item: $playing) { session in
            SessionPlayerView(plan: plan, session: session) {
                await viewModel.complete(session, of: plan)
            }
        }
    }

    private var next: PlanSession? { viewModel.progress.nextSession(of: plan) }

    private var header: some View {
        HStack(spacing: Spacing.l) {
            ZStack {
                ProgressRing(progress: viewModel.progress.fraction(of: plan), style: plan.kind.style, lineWidth: 14)
                VStack(spacing: 0) {
                    Text("\(viewModel.progress.completedCount(of: plan))")
                        .font(.title.bold())
                        .contentTransition(.numericText())
                    Text("of \(plan.totalSessions)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Label(plan.kind.title, systemImage: plan.kind.symbol).font(.headline)
                Text("\(plan.level.title) · \(plan.equipment.title)").foregroundStyle(.secondary)
                Text("\(plan.sessions.count) sessions a week for \(plan.weeks) weeks").font(.subheadline)
            }
        }
        .card()
    }
}

private struct SessionCard: View {
    let session: PlanSession
    let isNext: Bool
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                VStack(alignment: .leading) {
                    Text(session.title).font(.headline)
                    Text("About \(session.estimatedMinutes) min").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if isNext {
                    Text("Up next")
                        .font(.caption.bold())
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xs)
                        .background(.tint.opacity(0.15), in: .capsule)
                }
                Button("Start", systemImage: "play.fill", action: start)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
            }
            Divider()
            ForEach(session.exercises) { exercise in
                HStack {
                    Text(exercise.name)
                    Spacer()
                    Text(exercise.targetText).monospacedDigit().foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
        .card()
    }
}
