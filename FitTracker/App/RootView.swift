import SwiftUI
import Domain
import HistoryFeature
import SettingsFeature
import WorkoutFeature

/// The app's top level: one tab per feature.
///
/// On iOS 26 and later the system draws the tab bar in Liquid Glass automatically.
struct RootView: View {
    /// The tabs, as values, so the selected tab can be stored and reacted to.
    enum AppTab: Hashable {
        case workout, history, zones, settings
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
        self.selectedTab = .workout
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Workout", systemImage: "figure.run", value: AppTab.workout) {
                NavigationStack {
                    LiveWorkoutView(viewModel: liveWorkoutViewModel)
                }
            }

            Tab("History", systemImage: "list.bullet.rectangle", value: AppTab.history) {
                NavigationStack {
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
            }

            Tab("Zones", systemImage: "heart.circle", value: AppTab.zones) {
                ContentView()
            }

            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    SettingsView(viewModel: container.settingsViewModel)
                }
            }
        }
        // A workout recorded on the Workout tab should be in the list as soon as History opens.
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .history {
                Task { await historyViewModel.load() }
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

#Preview {
    if let container = try? AppContainer.inMemory() {
        RootView(container: container)
    }
}
