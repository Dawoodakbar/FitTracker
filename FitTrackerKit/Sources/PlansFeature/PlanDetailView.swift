import SwiftUI
import Domain
import DesignSystem

/// One plan: a large artwork header, progress, each session's exercises, and a Start button.
public struct PlanDetailView: View {
    let plan: WorkoutPlan
    let viewModel: PlansViewModel
    @State private var playing: PlanSession?

    public init(plan: WorkoutPlan, viewModel: PlansViewModel) {
        self.plan = plan
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                hero
                progressCard
                SectionHeader("Sessions", subtitle: "\(plan.sessions.count) a week for \(plan.weeks) weeks")
                ForEach(plan.sessions) { session in
                    SessionCard(session: session, style: plan.style, isNext: session.id == next?.id) {
                        playing = session
                    }
                }
            }
            .padding(Spacing.m)
            .padding(.bottom, 80)
        }
        .calmBackground(plan.style)
        .inlineNavigationTitle()
        .safeAreaInset(edge: .bottom) {
            if let next {
                Button {
                    playing = next
                } label: {
                    Label("Start \(next.title)", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(Palette.night)
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, Spacing.m)
                        .background(plan.style.gradient, in: .capsule)
                        .shadow(color: plan.style.end.opacity(0.5), radius: 16, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.bottom, Spacing.s)
            }
        }
        .fullScreenPresentation(item: $playing) { session in
            SessionPlayerView(plan: plan, session: session) {
                await viewModel.complete(session, of: plan)
            }
        }
    }

    private var next: PlanSession? { viewModel.progress.nextSession(of: plan) }

    private var hero: some View {
        SceneArt(style: plan.style, kind: plan.sceneKind, seed: plan.artSeed)
            .frame(height: 230)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label(plan.kind.title.uppercased(), systemImage: plan.kind.symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(plan.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text(plan.summary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                }
                .padding(Spacing.m)
                .shadow(color: .black.opacity(0.35), radius: 8)
            }
            .clipShape(.rect(cornerRadius: 30, style: .continuous))
    }

    private var progressCard: some View {
        HStack(spacing: Spacing.l) {
            ZStack {
                ProgressRing(progress: viewModel.progress.fraction(of: plan), style: plan.style, lineWidth: 10)
                VStack(spacing: 0) {
                    Text("\(viewModel.progress.completedCount(of: plan))")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .contentTransition(.numericText())
                    Text("of \(plan.totalSessions)").font(.caption2).foregroundStyle(Palette.textSecondary)
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: Spacing.s) {
                InfoPill(text: plan.level.title, symbol: "chart.bar.fill")
                InfoPill(text: plan.equipment.title, symbol: "dumbbell")
                InfoPill(text: "About \(plan.sessions.first?.estimatedMinutes ?? 0) min", symbol: "clock")
            }
        }
        .card()
    }
}

private struct InfoPill: View {
    let text: String
    let symbol: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.subheadline)
            .foregroundStyle(Palette.textSecondary)
    }
}

private struct SessionCard: View {
    let session: PlanSession
    let style: RingStyle
    let isNext: Bool
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.s) {
                        Text(session.title).font(.system(.headline, design: .rounded))
                        if isNext {
                            Text("UP NEXT")
                                .font(.caption2.weight(.heavy))
                                .foregroundStyle(Palette.night)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(style.gradient, in: .capsule)
                        }
                    }
                    Text("About \(session.estimatedMinutes) min · \(session.exercises.count) exercises")
                        .font(.caption).foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                Button(action: start) {
                    Image(systemName: "play.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.night)
                        .frame(width: 40, height: 40)
                        .background(style.gradient, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start \(session.title)")
            }
            ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: Spacing.m) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(style.end)
                        .frame(width: 24, height: 24)
                        .background(style.end.opacity(0.15), in: .circle)
                    Text(exercise.name).font(.subheadline)
                    Spacer()
                    Text(exercise.targetText).font(.subheadline).monospacedDigit().foregroundStyle(Palette.textSecondary)
                }
            }
        }
        .card()
    }
}
