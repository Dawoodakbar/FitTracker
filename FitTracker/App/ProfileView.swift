import SwiftUI
import Domain
import DesignSystem
import HistoryFeature
import SettingsFeature
import WorkoutFeature
import PlansFeature
import SleepFeature
import PrayerFeature

/// The user's corner: a summary of their streaks, then everything that isn't a daily action.
struct ProfileView<History: View>: View {
    let container: AppContainer
    let history: History

    init(container: AppContainer, @ViewBuilder history: () -> History) {
        self.container = container
        self.history = history()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                summary

                SectionHeader("Training")
                VStack(spacing: 0) {
                    row("Workout history", symbol: "list.bullet.rectangle.fill", style: .medication) { history }
                    Divider().overlay(Palette.surfaceBorder)
                    row("Heart-rate zones", symbol: "heart.text.square.fill", style: .move) {
                        ContentView(age: container.settingsViewModel.settings.age)
                    }
                }
                .card(padding: Spacing.s)

                SectionHeader("Settings")
                VStack(spacing: 0) {
                    row("Age and max heart rate", symbol: "person.crop.circle.fill", style: .plan) {
                        SettingsView(viewModel: container.settingsViewModel)
                    }
                }
                .card(padding: Spacing.s)

                Text("Everything you log stays on this iPhone and is encrypted while it's locked.")
                    .font(.footnote)
                    .foregroundStyle(Palette.textTertiary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.m)
        }
        .calmBackground(.plan)
        .navigationTitle("Profile")
    }

    private var summary: some View {
        HStack(spacing: Spacing.m) {
            stat(value: "\(container.prayerViewModel.streak)", label: "Prayer streak", style: .prayer)
            stat(value: "\(container.plansViewModel.progress.completions.count)", label: "Sessions", style: .move)
            stat(value: container.sleepViewModel.weekStats?.consistency.map { "\($0)" } ?? "—", label: "Sleep rhythm", style: .sleep)
        }
    }

    private func stat(value: String, label: String, style: RingStyle) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(style.gradient)
                .contentTransition(.numericText())
            Text(label).font(.caption).foregroundStyle(Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func row<Destination: View>(_ title: String, symbol: String, style: RingStyle, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: Spacing.m) {
                Image(systemName: symbol)
                    .foregroundStyle(Palette.night)
                    .frame(width: 34, height: 34)
                    .background(style.gradient, in: .rect(cornerRadius: 10, style: .continuous))
                Text(title).foregroundStyle(Palette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Palette.textTertiary)
            }
            .padding(Spacing.s)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
