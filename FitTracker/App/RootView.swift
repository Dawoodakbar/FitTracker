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

/// The app's top level: Today, then one tab per area of the user's day.
///
/// On iOS 26 and later the system draws the tab bar in Liquid Glass automatically.
struct RootView: View {
    /// The tabs, as values, so the selected tab can be stored and changed from the Today cards.
    enum AppTab: Hashable {
        case today, train, sleep, medication, prayer
    }

    let container: AppContainer

    // Created once, not in `body`, so switching tabs keeps each screen's state.
    // No initial value: `@State` is a macro in SDK 27 and is assigned only in `init`.
    @State private var historyViewModel: WorkoutHistoryViewModel
    @State private var liveWorkoutViewModel: LiveWorkoutViewModel
    @State private var selectedTab: AppTab

    init(container: AppContainer) {
        self.container = container
        self.historyViewModel = container.makeHistoryViewModel()
        self.liveWorkoutViewModel = container.makeLiveWorkoutViewModel()
        self.selectedTab = .today
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "circle.circle", value: AppTab.today) {
                NavigationStack {
                    TodayView(container: container, selectedTab: $selectedTab)
                }
            }

            Tab("Train", systemImage: "figure.strengthtraining.traditional", value: AppTab.train) {
                NavigationStack {
                    PlanLibraryView(viewModel: container.plansViewModel) { trainingLinks }
                }
            }

            Tab("Sleep", systemImage: "bed.double", value: AppTab.sleep) {
                NavigationStack { SleepView(viewModel: container.sleepViewModel) }
            }

            Tab("Meds", systemImage: "pills", value: AppTab.medication) {
                NavigationStack { MedicationView(viewModel: container.medicationViewModel) }
            }

            Tab("Prayer", systemImage: "moon.stars", value: AppTab.prayer) {
                NavigationStack { PrayerView(viewModel: container.prayerViewModel) }
            }
        }
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

    /// The heart-rate tools, shown above the plan library on the Train tab.
    private var trainingLinks: some View {
        VStack(spacing: Spacing.s) {
            NavigationLink {
                LiveWorkoutView(viewModel: liveWorkoutViewModel)
            } label: {
                TrainingLink(title: "Free workout", subtitle: "Record live heart rate and zones", symbol: "heart.circle.fill", style: .move)
            }
            HStack(spacing: Spacing.s) {
                NavigationLink {
                    historyScreen
                } label: {
                    TrainingLink(title: "History", subtitle: nil, symbol: "list.bullet.rectangle.fill", style: .medication)
                }
                NavigationLink {
                    ContentView(age: container.settingsViewModel.settings.age)
                } label: {
                    TrainingLink(title: "Zones", subtitle: nil, symbol: "heart.text.square.fill", style: .plan)
                }
            }
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
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(style.gradient, in: .rect(cornerRadius: 12))
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
