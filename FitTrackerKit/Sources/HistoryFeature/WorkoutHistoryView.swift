import SwiftUI
import Domain
import DesignSystem
import ZonePresentation

/// The list of past workouts, newest first, with swipe-to-delete.
///
/// Embed it in a `NavigationStack`; it sets its own title. All behaviour lives in
/// `WorkoutHistoryViewModel`; this view only renders `state` and forwards actions.
public struct WorkoutHistoryView: View {
    // No initial value: `@State` is a macro in SDK 27, so it's assigned once, in `init`.
    @State private var viewModel: WorkoutHistoryViewModel
    /// The row waiting for the user to confirm deletion; drives the confirmation dialog.
    @State private var pendingDeletion: WorkoutHistoryRow?

    public init(viewModel: WorkoutHistoryViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        content
            .calmBackground(.medication)
            .navigationTitle("History")
            // Runs when the view appears, and is cancelled automatically if it disappears.
            .task { await viewModel.load() }
            .confirmationDialog("Delete this workout?", item: $pendingDeletion) { row in
                Button("Delete Workout", role: .destructive) {
                    Task { await viewModel.delete(row.id) }
                }
            } message: { row in
                Text("The workout from \(row.startDate.formatted(date: .abbreviated, time: .shortened)) will be removed.")
            }
            .alert("Delete Failed", item: $viewModel.deleteError) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            ContentUnavailableView(
                "No Workouts Yet",
                systemImage: "heart.text.square",
                description: Text("Workouts you record will appear here.")
            )
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't Load Workouts", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try Again") {
                    Task { await viewModel.load() }
                }
            }
        case .loaded(let rows):
            List(rows) { row in
                WorkoutHistoryRowView(row: row)
                    .swipeActions {
                        // No `.destructive` role here: that role animates the row away at once,
                        // but we only delete after the user confirms in the dialog.
                        Button("Delete", systemImage: "trash") {
                            pendingDeletion = row
                        }
                        .tint(.red)
                    }
            }
        }
    }
}

/// One workout: its main-zone badge, when it happened, how long, and average heart rate.
struct WorkoutHistoryRowView: View {
    let row: WorkoutHistoryRow

    var body: some View {
        HStack(spacing: Spacing.m) {
            ZoneBadge(tone: row.summary.mainZone?.tone)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(row.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Text(row.summary.duration, format: .units(allowed: [.hours, .minutes], width: .abbreviated))
                    .foregroundStyle(.secondary)
                if let averageBPM = row.summary.averageBPM {
                    Text("Avg \(averageBPM) BPM")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        // VoiceOver reads the row as one element instead of four.
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#if DEBUG
/// A preview-only stub. `TestSupport`'s fake can't be used here: depending on it from a
/// feature module would ship test code in the app.
private struct PreviewWorkoutRepository: WorkoutRepository {
    var stored: [Workout] = []
    var fails = false

    func save(_ workout: Workout) async throws {}
    func delete(id: Workout.ID) async throws {}

    func workouts() async throws -> [Workout] {
        if fails { throw CancellationError() }
        return stored
    }

    /// Three workouts from the last few days at different intensities.
    static var sample: PreviewWorkoutRepository {
        let workouts = [(hoursAgo: 2.0, bpm: 150), (26, 170), (50, 120)].compactMap { item in
            let start = Date.now.addingTimeInterval(-item.hoursAgo * 3600)
            return try? Workout(
                startDate: start,
                endDate: start.addingTimeInterval(45 * 60),
                samples: [HeartRateSample(bpm: item.bpm, date: start)]
            )
        }
        return PreviewWorkoutRepository(stored: workouts)
    }
}

/// Wraps the screen in a `NavigationStack`, as the app will.
private struct HistoryPreview: View {
    let repository: PreviewWorkoutRepository

    var body: some View {
        if let calculator = try? HeartRateZoneCalculator(age: 30) {
            NavigationStack {
                WorkoutHistoryView(
                    viewModel: WorkoutHistoryViewModel(repository: repository, calculator: calculator)
                )
            }
        }
    }
}

#Preview("Workouts") {
    HistoryPreview(repository: .sample)
}

#Preview("Workouts, dark") {
    HistoryPreview(repository: .sample)
        .preferredColorScheme(.dark)
}

#Preview("Empty") {
    HistoryPreview(repository: PreviewWorkoutRepository())
}

#Preview("Load failed") {
    HistoryPreview(repository: PreviewWorkoutRepository(fails: true))
}
#endif
