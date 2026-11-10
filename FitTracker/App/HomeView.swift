import SwiftUI
import Domain
import DesignSystem
import PlansFeature
import SleepFeature
import MedicationFeature
import PrayerFeature

/// The first screen: a greeting, today's suggested session as a large card, the day's rings,
/// and short rows of things to do next. Each part links straight to where it's done.
struct HomeView: View {
    let container: AppContainer
    @Binding var selectedTab: RootView.AppTab

    private var plans: PlansViewModel { container.plansViewModel }
    private var sleep: SleepViewModel { container.sleepViewModel }
    private var medication: MedicationViewModel { container.medicationViewModel }
    private var prayer: PrayerViewModel { container.prayerViewModel }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                header
                if let suggestion { heroCard(suggestion) }
                yourDay
                quickSessions
                tonight
                rituals
            }
            .padding(Spacing.m)
        }
        .calmBackground(timeOfDay.style)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: WorkoutPlan.self) { plan in
            PlanDetailView(plan: plan, viewModel: plans)
        }
        // Each feature loads its own data; Home needs all four, even before their tabs open.
        .task {
            async let p: Void = plans.load()
            async let s: Void = sleep.load()
            async let m: Void = medication.load()
            async let r: Void = prayer.load()
            _ = await (p, s, m, r)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(Palette.textSecondary)
                Text(timeOfDay.greeting)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Palette.textPrimary)
                Text(timeOfDay.line)
                    .font(.subheadline)
                    .foregroundStyle(Palette.textSecondary)
            }
            Spacer()
            Image(systemName: timeOfDay.symbol)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(timeOfDay.style.gradient)
                .frame(width: 48, height: 48)
                .background(Palette.surface, in: .circle)
                .overlay(Circle().strokeBorder(Palette.surfaceBorder))
                .symbolEffect(.breathe, options: .repeating)
        }
        .padding(.top, Spacing.m)
    }

    // MARK: - Hero

    /// The plan to suggest: the one in progress, otherwise one that suits the time of day.
    private var suggestion: WorkoutPlan? {
        if let active = plans.activePlans.first { return active }
        let id = switch timeOfDay {
        case .morning: "morning-yoga"
        case .afternoon: "home-strength"
        case .evening: "sleep-yoga"
        }
        return PlanCatalog.plan(id: id)
    }

    private func heroCard(_ plan: WorkoutPlan) -> some View {
        NavigationLink(value: plan) {
            SceneArt(style: plan.style, kind: plan.sceneKind, seed: plan.artSeed)
                .frame(height: 260)
                .overlay(alignment: .bottomLeading) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(plans.progress.completedCount(of: plan) > 0 ? "CONTINUE" : "SUGGESTED FOR YOU")
                                .font(.caption.weight(.bold)).tracking(1)
                                .foregroundStyle(.white.opacity(0.8))
                            Text(plan.title)
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                            if let next = plans.progress.nextSession(of: plan) {
                                Text("\(next.title) · \(next.estimatedMinutes) min")
                                    .font(.subheadline).foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Palette.night)
                            .frame(width: 54, height: 54)
                            .background(.white, in: .circle)
                            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                    }
                    .padding(Spacing.l)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                }
                .clipShape(.rect(cornerRadius: 32, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start \(plan.title)")
    }

    // MARK: - Your day

    private var yourDay: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Your day")
            HStack(spacing: Spacing.l) {
                RingStack(rings: [
                    .init(id: "Train", progress: min(Double(plans.sessionsToday), 1), style: .move),
                    .init(id: "Sleep", progress: sleep.goalFraction, style: .sleep),
                    .init(id: "Medication", progress: medication.todayFraction, style: .medication),
                    .init(id: "Prayer", progress: prayer.todayFraction, style: .prayer)
                ], lineWidth: 12, gap: 3)
                .frame(width: 140)

                VStack(alignment: .leading, spacing: Spacing.s) {
                    legend("Train", value: plans.sessionsToday == 0 ? "Not yet" : "\(plans.sessionsToday) done", style: .move, tab: .train)
                    legend("Sleep", value: sleepValue, style: .sleep, tab: .sleep)
                    legend("Meds", value: medsValue, style: .medication, tab: .rituals)
                    legend("Prayer", value: "\(prayer.journal.count(on: prayer.today)) of 5", style: .prayer, tab: .rituals)
                }
            }
            .card()
        }
    }

    private func legend(_ title: String, value: String, style: RingStyle, tab: RootView.AppTab) -> some View {
        Button { selectedTab = tab } label: {
            HStack(spacing: Spacing.s) {
                Circle().fill(style.gradient).frame(width: 8, height: 8)
                Text(title).font(.subheadline).foregroundStyle(Palette.textSecondary)
                Spacer(minLength: Spacing.s)
                Text(value).font(.subheadline.weight(.semibold)).foregroundStyle(style.end)
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rows

    private var quickSessions: some View {
        let quick = PlanCatalog.all.filter { ($0.sessions.first?.estimatedMinutes ?? 99) <= 15 }
        return VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Quick sessions", subtitle: "15 minutes or less") {
                Button("See all") { selectedTab = .train }.tint(Palette.peach)
            }
            CardRow {
                ForEach(quick) { plan in
                    NavigationLink(value: plan) {
                        ArtCard(title: plan.title, subtitle: plan.cardSubtitle, style: plan.style, kind: plan.sceneKind, seed: plan.artSeed, width: 190, artHeight: 110) {
                            ArtBadge("\(plan.sessions.first?.estimatedMinutes ?? 0) min", symbol: "clock")
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var tonight: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("For tonight", subtitle: "Same bedtime, better sleep")
            HStack(spacing: Spacing.m) {
                if let windDown = PlanCatalog.plan(id: "sleep-yoga") {
                    NavigationLink(value: windDown) {
                        ArtCard(title: "Wind down", subtitle: "Stretch and breathe", style: .sleep, kind: .night, seed: 11, width: nil, artHeight: 110)
                    }
                    .buttonStyle(.plain)
                }
                Button { selectedTab = .sleep } label: {
                    ArtCard(
                        title: sleep.lastNight == nil ? "Log last night" : "Last night \(sleepValue)",
                        subtitle: sleep.weekStats?.consistency.map { "Consistency \($0)" } ?? "Track your rhythm",
                        style: .sleep, kind: .waves, seed: 23, width: nil, artHeight: 110
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var rituals: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SectionHeader("Daily rituals")
            HStack(spacing: Spacing.m) {
                ritualTile(title: "Medication", value: medsValue, detail: medsDetail, symbol: "pills.fill", style: .medication)
                ritualTile(title: "Prayer", value: "\(prayer.journal.count(on: prayer.today)) of 5", detail: "\(prayer.streak) day streak", symbol: "moon.stars.fill", style: .prayer)
            }
        }
    }

    private func ritualTile(title: String, value: String, detail: String, symbol: String, style: RingStyle) -> some View {
        Button { selectedTab = .rituals } label: {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(Palette.night)
                    .frame(width: 40, height: 40)
                    .background(style.gradient, in: .rect(cornerRadius: 12, style: .continuous))
                Text(title).font(.caption).foregroundStyle(Palette.textSecondary)
                Text(value).font(.system(.title3, design: .rounded, weight: .bold)).contentTransition(.numericText())
                Text(detail).font(.caption).foregroundStyle(Palette.textSecondary).lineLimit(1)
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Wording

    private var sleepValue: String {
        guard let night = sleep.lastNight else { return "—" }
        return Duration.seconds(night.duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private var medsValue: String {
        let doses = medication.todaysDoses
        return doses.isEmpty ? "None" : "\(doses.count { $0.status == .taken }) of \(doses.count)"
    }

    private var medsDetail: String {
        if !medication.book.runningLow.isEmpty { return "Refill soon" }
        guard let next = medication.todaysDoses.first(where: { $0.status == nil }) else {
            return medication.todaysDoses.isEmpty ? "Add a medication" : "All done today"
        }
        return "Next: \(next.medication.name)"
    }

    private var timeOfDay: TimeOfDay { TimeOfDay(hour: Calendar.current.component(.hour, from: .now)) }
}

/// Changes the greeting, suggestion and background glow through the day.
private enum TimeOfDay {
    case morning, afternoon, evening

    init(hour: Int) {
        self = switch hour {
        case 5..<12: .morning
        case 12..<17: .afternoon
        default: .evening
        }
    }

    var greeting: String {
        switch self {
        case .morning: "Good morning"
        case .afternoon: "Good afternoon"
        case .evening: "Good evening"
        }
    }

    var line: String {
        switch self {
        case .morning: "A gentle start sets the tone."
        case .afternoon: "A short session keeps you going."
        case .evening: "Slow down and get ready to rest."
        }
    }

    var symbol: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "moon.stars.fill"
        }
    }

    var style: RingStyle {
        switch self {
        case .morning: .plan
        case .afternoon: .move
        case .evening: .sleep
        }
    }
}
