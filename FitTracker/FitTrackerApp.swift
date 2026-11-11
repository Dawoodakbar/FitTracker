import SwiftUI

@main struct FitTrackerApp: App {
    /// Built once at launch. `App` is created a single time, so a plain `let` is enough.
    private let container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
