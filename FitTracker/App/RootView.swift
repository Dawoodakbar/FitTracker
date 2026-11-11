import SwiftUI
import Domain
import DesignSystem
import HistoryFeature
import SettingsFeature
import WorkoutFeature
import PlansFeature
import SleepFeature
import MedicationFeature
import PrayerFeature

/// The app's top level, organised like a calm wellness app: Home suggests what to do,
/// and each other tab is one part of the day.
///
/// On iOS 26 and later the system draws the tab bar in Liquid Glass automatically.
struct RootView: View {
    /// The tabs, as values, so Home's cards can switch tabs.
    enum AppTab: Hashable {
        case home, train, sleep, rituals, profile
    }

    let container: AppContainer

    // Created once, not in `body`, so switching tabs keeps each screen's state.
    // No initial value: `@State` is a macro in SDK 27 and is assigned only in `init`.
    @State private var historyViewModel: WorkoutHistoryViewModel
    @State private var liveWorkoutViewModel: LiveWorkoutViewModel
    @State private var selectedTab: AppTab
    @State private var ritual: RitualsView.Ritual

    init(container: AppContainer) {
        self.container = container
        self.historyViewModel = container.makeHistoryViewModel()
        self.liveWorkoutViewModel = container.makeLiveWorkoutViewModel()
        self.selectedTab = .home
        self.ritual = .medication
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "sparkles", value: AppTab.home) {
                NavigationStack {
                    HomeView(container: container, selectedTab: $selectedTab)
                }
            }

            Tab("Train", systemImage: "figure.mind.and.body", value: AppTab.train) {
                NavigationStack {
                    PlanLibraryView(viewModel: container.plansViewModel) { trainingLinks }
                }
            }

            Tab("Sleep", systemImage: "moon.zzz", value: AppTab.sleep) {
                NavigationStack { SleepView(viewModel: container.sleepViewModel) }
            }

            Tab("Rituals", systemImage: "leaf", value: AppTab.rituals) {
                NavigationStack { RitualsView(container: container, ritual: $ritual) }
            }

            Tab("Profile", systemImage: "person.crop.circle", value: AppTab.profile) {
                NavigationStack {
                    ProfileView(container: container) { historyScreen }
                }
            }
        }
        .tint(Palette.lavender)
        // The calm night look is the app's identity, so it stays dark regardless of the system setting.
        .preferredColorScheme(.dark)
        // When the user changes age or formula, every screen starts using the new zones.
        .onChange(of: container.settingsViewModel.settings) { _, settings in
            historyViewModel.calculator = settings.calculator
            liveWorkoutViewModel.calculator = settings.calculator
        }
        // Keep the screen on while recording, so the live heart rate stays visible.
        .onChange(of: liveWorkoutViewModel.phase) { _, phase in
            UIApplication.shared.isIdleTimerDisabled = phase == .recording
        }
    }

    /// The live heart-rate workout, shown above the plan library on the Train tab.
    private var trainingLinks: some View {
        NavigationLink {
            LiveWorkoutView(viewModel: liveWorkoutViewModel)
        } label: {
            TrainingLink(title: "Free workout", subtitle: "Record live heart rate and zones", symbol: "heart.circle.fill", style: .move)
        }
        .buttonStyle(.plain)
    }

    private var historyScreen: some View {
        WorkoutHistoryView(viewModel: historyViewModel)
            #if DEBUG
            .toolbar {
                ToolbarItem {
                    Button("Add Sample Workout", systemImage: "plus") {
                        Task { await addSampleWorkout() }
                    }
                }
            }
            #endif
    }

    #if DEBUG
    /// Saves a generated workout, then reloads History so it appears.
    /// Debug builds only.
    private func addSampleWorkout() async {
        do {
            try await container.workoutRepository.save(SampleWorkout.make(endingAt: .now))
        } catch {
            historyViewModel.deleteError = "Couldn't save the sample workout."
        }
        await historyViewModel.load()
    }
    #endif
}

private struct TrainingLink: View {
    let title: String
    let subtitle: String?
    let symbol: String
    let style: RingStyle

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(Palette.night)
                .frame(width: 44, height: 44)
                .background(style.gradient, in: .rect(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading) {
                Text(title).font(.headline).lineLimit(1).minimumScaleFactor(0.8)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
            // Half-width tiles have no subtitle and no room for a chevron.
            if subtitle != nil {
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
        }
        .card()
    }
}

#Preview {
    if let container = try? AppContainer.inMemory() {
        RootView(container: container)
    }
}
