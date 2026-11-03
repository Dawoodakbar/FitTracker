import SwiftUI
import Domain
import HistoryFeature

/// The app's top level: one tab per feature.
///
/// On iOS 26 and later the system draws the tab bar in Liquid Glass automatically.
struct RootView: View {
    let container: AppContainer

    // Created once, not in `body`, so switching tabs keeps the loaded list.
    // No initial value: `@State` is a macro in SDK 27 and is assigned only in `init`.
    @State private var historyViewModel: WorkoutHistoryViewModel

    init(container: AppContainer) {
        self.container = container
        self.historyViewModel = container.makeHistoryViewModel()
    }

    var body: some View {
        TabView {
            Tab("Zones", systemImage: "heart.circle") {
                ContentView()
            }

            Tab("History", systemImage: "list.bullet.rectangle") {
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
        }
    }

    #if DEBUG
    /// Saves a generated workout, then reloads History so it appears.
    /// Debug builds only, until Live Workout records real ones.
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
