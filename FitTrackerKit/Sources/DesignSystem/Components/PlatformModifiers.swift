import SwiftUI

/// iOS-only presentation calls wrapped so the package still builds on macOS, where
/// `swift test` runs. On macOS each falls back to the nearest equivalent.
extension View {
    /// A small title in the navigation bar instead of a large one.
    public func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Covers the whole screen on iPhone; a sheet elsewhere.
    public func fullScreenPresentation<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }

    /// Stops the screen dimming and locking while this view is on screen.
    public func keepsScreenOn() -> some View {
        #if os(iOS)
        onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        #else
        self
        #endif
    }
}
