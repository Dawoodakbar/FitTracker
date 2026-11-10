import SwiftUI
import Domain
import DesignSystem

/// Every plan, filterable by type, with the plans in progress at the top.
/// Embed it in a `NavigationStack`; it sets its own title.
public struct PlanLibraryView<Extra: View>: View {
    @State private var viewModel: PlansViewModel
    /// Extra rows the app adds at the top (live heart-rate workout, history).
    private let extra: Extra

    public init(viewModel: PlansViewModel, @ViewBuilder extra: () -> Extra = { EmptyView() }) {
        self.viewModel = viewModel
        self.extra = extra()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                extra

                if !viewModel.activePlans.isEmpty {
                    Text("Continue").font(.title2.bold())
                    ForEach(viewModel.activePlans) { plan in
                        NavigationLink(value: plan) { ContinueCard(plan: plan, progress: viewModel.progress) }
                            .buttonStyle(.plain)
                    }
                }

                Text("Plans").font(.title2.bold())
                filterBar
                LazyVStack(spacing: Spacing.m) {
                    ForEach(viewModel.visiblePlans) { plan in
                        NavigationLink(value: plan) {
                            PlanCard(plan: plan, fraction: viewModel.progress.fraction(of: plan))
                        }
                        .buttonStyle(.plain)
                        .transition(.asymmetric(insertion: .scale(scale: 0.92).combined(with: .opacity), removal: .opacity))
                    }
                }
                .animation(.spring(duration: 0.45, bounce: 0.2), value: viewModel.kindFilter)
            }
            .padding(Spacing.m)
        }
        .navigationTitle("Train")
        .navigationDestination(for: WorkoutPlan.self) { plan in
            PlanDetailView(plan: plan, viewModel: viewModel)
        }
        .task { await viewModel.load() }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                FilterChip(title: "All", symbol: "square.grid.2x2", isOn: viewModel.kindFilter == nil) {
                    viewModel.kindFilter = nil
                }
                ForEach(ActivityKind.allCases) { kind in
                    FilterChip(title: kind.title, symbol: kind.symbol, isOn: viewModel.kindFilter == kind) {
                        viewModel.kindFilter = kind
                    }
                }
            }
        }
        .scrollClipDisabled()
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

private struct FilterChip: View {
    let title: String
    let symbol: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.s)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isOn ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        .background {
            Capsule().fill(isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.fill.tertiary))
        }
        .animation(.snappy, value: isOn)
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// A plan in the library: coloured header with its symbol, details, and a thin progress bar.
struct PlanCard: View {
    let plan: WorkoutPlan
    let fraction: Double

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: plan.kind.symbol)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(plan.kind.style.gradient, in: .rect(cornerRadius: 18))
                .symbolEffect(.bounce, value: fraction)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(plan.title).font(.headline)
                Text("\(plan.level.title) · \(plan.weeks) weeks · \(plan.equipment.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(plan.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                if fraction > 0 {
                    ProgressView(value: fraction).tint(plan.kind.style.start)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

/// A plan the user is part-way through, with its ring and the next session.
struct ContinueCard: View {
    let plan: WorkoutPlan
    let progress: PlanProgress

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZStack {
                ProgressRing(progress: progress.fraction(of: plan), style: plan.kind.style, lineWidth: 8)
                Image(systemName: plan.kind.symbol).foregroundStyle(plan.kind.style.start)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(plan.title).font(.headline)
                Text("\(progress.completedCount(of: plan)) of \(plan.totalSessions) sessions")
                    .font(.caption).foregroundStyle(.secondary)
                if let next = progress.nextSession(of: plan) {
                    Text("Next: \(next.title) · \(next.estimatedMinutes) min")
                        .font(.subheadline.weight(.medium))
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "play.circle.fill").font(.largeTitle).foregroundStyle(plan.kind.style.start)
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
