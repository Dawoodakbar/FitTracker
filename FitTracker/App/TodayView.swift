import SwiftUI
import Domain
import DesignSystem
import SettingsFeature
import PlansFeature
import SleepFeature
import MedicationFeature
import PrayerFeature

/// The dashboard: one ring per area of the day, then a card for each with its next step.
/// Tapping a card jumps to that tab.
struct TodayView: View {
    let container: AppContainer
    @Binding var selectedTab: RootView.AppTab

    private var plans: PlansViewModel { container.plansViewModel }
    private var sleep: SleepViewModel { container.sleepViewModel }
    private var medication: MedicationViewModel { container.medicationViewModel }
    private var prayer: PrayerViewModel { container.prayerViewModel }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                header
                rings
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.m), GridItem(.flexible(), spacing: Spacing.m)], spacing: Spacing.m) {
                    tile(.train, title: "Train", value: trainValue, detail: nextSessionText, symbol: "flame.fill", style: .move)
                    tile(.sleep, title: "Sleep", value: sleepValue, detail: sleepDetail, symbol: "moon.zzz.fill", style: .sleep)
                    tile(.medication, title: "Meds", value: medsValue, detail: medsDetail, symbol: "pills.fill", style: .medication)
                    tile(.prayer, title: "Prayer", value: "\(prayer.journal.count(on: prayer.today)) of 5", detail: "\(prayer.streak) day streak", symbol: "moon.stars.fill", style: .prayer)
                }
            }
            .padding(Spacing.m)
        }
        .navigationTitle("Today")
        .toolbar {
            NavigationLink {
                SettingsView(viewModel: container.settingsViewModel)
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        // Each feature loads its own data; Today needs all four, even before their tabs open.
        .task {
            async let p: Void = plans.load()
            async let s: Void = sleep.load()
            async let m: Void = medication.load()
            async let r: Void = prayer.load()
            _ = await (p, s, m, r)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)).uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(greeting).font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rings: some View {
        HStack(spacing: Spacing.l) {
            RingStack(rings: [
                .init(id: "Train", progress: min(Double(plans.sessionsToday), 1), style: .move),
                .init(id: "Sleep", progress: sleep.goalFraction, style: .sleep),
                .init(id: "Medication", progress: medication.todaysDoses.isEmpty ? 0 : medication.todayFraction, style: .medication),
                .init(id: "Prayer", progress: prayer.todayFraction, style: .prayer)
            ], lineWidth: 14, gap: 3)
            .frame(width: 170)

            VStack(alignment: .leading, spacing: Spacing.s) {
                legend("Train", value: trainValue, style: .move)
                legend("Sleep", value: sleepValue, style: .sleep)
                legend("Meds", value: medsValue, style: .medication)
                legend("Prayer", value: "\(prayer.journal.count(on: prayer.today))/5", style: .prayer)
            }
        }
        .card()
    }

    private func legend(_ title: String, value: String, style: RingStyle) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline).foregroundStyle(style.start).contentTransition(.numericText())
        }
    }

    private func tile(_ tab: RootView.AppTab, title: String, value: String, detail: String, symbol: String, style: RingStyle) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Image(systemName: symbol)
                    .font(.title2)
                    .foregroundStyle(style.gradient)
                Text(title).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.title3.bold()).contentTransition(.numericText())
                Text(detail).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens \(title)")
    }

    // MARK: - Wording

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
    }

    private var trainValue: String {
        plans.sessionsToday == 0 ? "Not yet" : "\(plans.sessionsToday) done"
    }

    private var nextSessionText: String {
        if let plan = plans.activePlans.first, let next = plans.progress.nextSession(of: plan) {
            return "Next: \(next.title)"
        }
        return "Pick a plan to start"
    }

    private var sleepValue: String {
        guard let night = sleep.lastNight else { return "—" }
        return Duration.seconds(night.duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private var sleepDetail: String {
        guard let consistency = sleep.weekStats?.consistency else { return "Log last night" }
        return "Consistency \(consistency)"
    }

    private var medsValue: String {
        let doses = medication.todaysDoses
        return doses.isEmpty ? "None" : "\(doses.count { $0.status == .taken })/\(doses.count)"
    }

    private var medsDetail: String {
        if !medication.book.runningLow.isEmpty { return "Refill soon" }
        guard let next = medication.todaysDoses.first(where: { $0.status == nil }) else {
            return medication.todaysDoses.isEmpty ? "Add a medication" : "All done today"
        }
        return "Next: \(next.medication.name)"
    }
}
