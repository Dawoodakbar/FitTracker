import SwiftUI
import Domain
import DesignSystem

/// Every plan, grouped into rows by type, with plans in progress first.
/// Embed it in a `NavigationStack`; it sets its own title.
public struct PlanLibraryView<Extra: View>: View {
    @State private var viewModel: PlansViewModel
    /// Extra content the app adds at the top (live heart-rate workout, history).
    private let extra: Extra

    public init(viewModel: PlansViewModel, @ViewBuilder extra: () -> Extra = { EmptyView() }) {
        self.viewModel = viewModel
        self.extra = extra()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                extra

                if !viewModel.activePlans.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        SectionHeader("Continue", subtitle: "Pick up where you left off")
                        CardRow {
                            ForEach(viewModel.activePlans) { plan in
                                NavigationLink(value: plan) {
                                    ArtCard(
                                        title: plan.title,
                                        subtitle: nextText(for: plan),
                                        style: plan.style, kind: plan.sceneKind, seed: plan.artSeed
                                    ) {
                                        ArtBadge("\(Int(viewModel.progress.fraction(of: plan) * 100))%", symbol: "chart.pie.fill")
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                filterBar

                if let kind = viewModel.kindFilter {
                    // One type: full-width cards, one under another.
                    LazyVStack(spacing: Spacing.l) {
                        ForEach(viewModel.visiblePlans) { plan in
                            planLink(plan, width: nil, artHeight: 170)
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }
                    .id(kind)
                } else {
                    // Everything: a row per type, like browsing shelves.
                    ForEach(ActivityKind.allCases) { kind in
                        let plans = viewModel.plans.filter { $0.kind == kind }
                        if !plans.isEmpty {
                            VStack(alignment: .leading, spacing: Spacing.m) {
                                SectionHeader(kind.title, subtitle: kind.tagline) {
                                    Button("See all") {
                                        withAnimation(.smooth) { viewModel.kindFilter = kind }
                                    }
                                    .tint(kind.style.end)
                                }
                                CardRow {
                                    ForEach(plans) { planLink($0, width: 220, artHeight: 130) }
                                }
                            }
                        }
                    }
                }
            }
            .padding(Spacing.m)
            .animation(.spring(duration: 0.45, bounce: 0.15), value: viewModel.kindFilter)
        }
        .calmBackground(viewModel.kindFilter?.style ?? .move)
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

    private func planLink(_ plan: WorkoutPlan, width: CGFloat?, artHeight: CGFloat) -> some View {
        NavigationLink(value: plan) {
            ArtCard(
                title: plan.title, subtitle: plan.cardSubtitle,
                style: plan.style, kind: plan.sceneKind, seed: plan.artSeed,
                width: width, artHeight: artHeight
            ) {
                ArtBadge("\(plan.weeks) wk", symbol: plan.kind.symbol)
            }
        }
        .buttonStyle(.plain)
    }

    private func nextText(for plan: WorkoutPlan) -> String {
        guard let next = viewModel.progress.nextSession(of: plan) else { return "Finished" }
        return "Next: \(next.title) · \(next.estimatedMinutes) min"
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                FilterChip(title: "All", symbol: "sparkles", style: .move, isOn: viewModel.kindFilter == nil) {
                    viewModel.kindFilter = nil
                }
                ForEach(ActivityKind.allCases) { kind in
                    FilterChip(title: kind.title, symbol: kind.symbol, style: kind.style, isOn: viewModel.kindFilter == kind) {
                        viewModel.kindFilter = kind
                    }
                }
            }
            .padding(.horizontal, Spacing.m)
        }
        .scrollClipDisabled()
        .padding(.horizontal, -Spacing.m)
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

private struct FilterChip: View {
    let title: String
    let symbol: String
    let style: RingStyle
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isOn ? AnyShapeStyle(Palette.night) : AnyShapeStyle(Palette.textPrimary))
        .background {
            if isOn {
                Capsule().fill(style.gradient)
            } else {
                Capsule().fill(Palette.surface).overlay(Capsule().strokeBorder(Palette.surfaceBorder))
            }
        }
        .animation(.snappy, value: isOn)
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
