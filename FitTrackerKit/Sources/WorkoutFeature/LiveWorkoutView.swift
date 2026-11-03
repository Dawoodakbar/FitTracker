import SwiftUI
import Domain
import DesignSystem
import ZonePresentation

/// Records a workout: live heart rate and zone in the content layer, with floating
/// Liquid Glass controls above it (the functional layer, as Apple's guidelines describe).
public struct LiveWorkoutView: View {
    // No initial value: `@State` is a macro in SDK 27 and is assigned only in `init`.
    @State private var viewModel: LiveWorkoutViewModel
    @Namespace private var glassNamespace

    public init(viewModel: LiveWorkoutViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Spacing.m)
            .navigationTitle("Workout")
            // Controls float above the content and never cover it, even at large text sizes.
            .safeAreaInset(edge: .bottom) {
                controls
                    .padding(.bottom, Spacing.m)
            }
            .animation(.smooth, value: viewModel.phase)
    }

    // MARK: - Content layer

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle:
            ContentUnavailableView(
                "Ready When You Are",
                systemImage: "heart.circle",
                description: Text("Put on your heart-rate monitor, then tap Start.")
            )
        case .recording, .saving:
            LiveReadingView(
                bpm: viewModel.currentBPM,
                zone: viewModel.currentZone,
                startDate: viewModel.startDate
            )
        case .finished(let summary):
            WorkoutSummaryCard(summary: summary, notice: viewModel.notice)
        case .failed(let message):
            ContentUnavailableView(
                "Workout Not Saved",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }

    // MARK: - Functional layer (Liquid Glass)

    /// One container, so the glass buttons blend and morph into each other as the phase changes.
    private var controls: some View {
        GlassEffectContainer(spacing: Spacing.l) {
            HStack(spacing: Spacing.m) {
                switch viewModel.phase {
                case .idle:
                    Button("Start", systemImage: "play.fill") {
                        viewModel.start()
                    }
                    .buttonStyle(.glassProminent)
                    .glassEffectID("primary", in: glassNamespace)

                case .recording:
                    Button("Stop", systemImage: "stop.fill") {
                        Task { await viewModel.stop() }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .glassEffectID("primary", in: glassNamespace)

                case .saving:
                    ProgressView("Saving…")
                        .padding(.horizontal, Spacing.m)
                        .padding(.vertical, Spacing.s)
                        .glassEffect()
                        .glassEffectID("primary", in: glassNamespace)

                case .finished:
                    Button("Done", systemImage: "checkmark") {
                        viewModel.reset()
                    }
                    .buttonStyle(.glassProminent)
                    .glassEffectID("primary", in: glassNamespace)

                case .failed:
                    Button("Discard", systemImage: "trash") {
                        viewModel.reset()
                    }
                    .buttonStyle(.glass)
                    .glassEffectID("secondary", in: glassNamespace)

                    Button("Try Again", systemImage: "arrow.clockwise") {
                        Task { await viewModel.retrySave() }
                    }
                    .buttonStyle(.glassProminent)
                    .glassEffectID("primary", in: glassNamespace)
                }
            }
            .controlSize(.extraLarge)
        }
    }
}

// MARK: - Live reading

/// The big live number, its zone, and elapsed time.
struct LiveReadingView: View {
    let bpm: Int?
    let zone: HeartRateZone?
    let startDate: Date?

    @ScaledMetric(relativeTo: .largeTitle) private var bpmSize: CGFloat = 96

    var body: some View {
        VStack(spacing: Spacing.l) {
            ZoneBadge(tone: zone?.tone)

            VStack(spacing: Spacing.xs) {
                Text(bpm.map { "\($0)" } ?? "--")
                    .font(.system(size: bpmSize, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    // Digits roll smoothly as the number changes, instead of jumping.
                    .contentTransition(.numericText())
                Text("BPM")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            Text(zone?.name ?? "Below zone 1")
                .font(.title2.bold())
                .foregroundStyle(zone.map { AnyShapeStyle(.zone($0.tone)) } ?? AnyShapeStyle(.secondary))

            if let startDate {
                // The system updates a timer-style Text every second without re-running `body`.
                Text(startDate, style: .timer)
                    .font(.title3)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text("Elapsed time"))
            }
        }
        .animation(.snappy, value: bpm)
    }
}

// MARK: - Summary

/// What the user sees right after saving.
struct WorkoutSummaryCard: View {
    let summary: WorkoutSummary
    let notice: String?

    var body: some View {
        VStack(spacing: Spacing.l) {
            ZoneBadge(tone: summary.mainZone?.tone)

            Text("Workout Saved")
                .font(.title.bold())

            Grid(alignment: .leading, horizontalSpacing: Spacing.l, verticalSpacing: Spacing.s) {
                GridRow {
                    Text("Duration").foregroundStyle(.secondary)
                    Text(summary.duration, format: .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated))
                }
                if let averageBPM = summary.averageBPM, let maxBPM = summary.maxBPM {
                    GridRow {
                        Text("Average").foregroundStyle(.secondary)
                        Text("\(averageBPM) BPM")
                    }
                    GridRow {
                        Text("Max").foregroundStyle(.secondary)
                        Text("\(maxBPM) BPM")
                    }
                }
                if let mainZone = summary.mainZone {
                    GridRow {
                        Text("Main zone").foregroundStyle(.secondary)
                        Text(mainZone.name)
                    }
                }
            }
            .monospacedDigit()

            if let notice {
                Label(notice, systemImage: "exclamationmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
/// A preview-only source: a gentle wave of readings, twice a second. (Features don't depend
/// on the `Sensors` module, so previews bring their own.)
private struct PreviewHeartRateSource: HeartRateSource {
    func readings() -> AsyncThrowingStream<HeartRateSample, any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var tick = 0.0
                while !Task.isCancelled {
                    if let sample = try? HeartRateSample(bpm: 140 + Int(25 * sin(tick / 6)), date: .now) {
                        continuation.yield(sample)
                    }
                    tick += 1
                    try? await Task.sleep(for: .milliseconds(500))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private struct PreviewWorkoutRepository: WorkoutRepository {
    func save(_ workout: Workout) async throws {}
    func workouts() async throws -> [Workout] { [] }
    func delete(id: Workout.ID) async throws {}
}

private struct LiveWorkoutPreview: View {
    var body: some View {
        if let calculator = try? HeartRateZoneCalculator(age: 30) {
            NavigationStack {
                LiveWorkoutView(
                    viewModel: LiveWorkoutViewModel(
                        source: PreviewHeartRateSource(),
                        repository: PreviewWorkoutRepository(),
                        calculator: calculator
                    )
                )
            }
        }
    }
}

#Preview("Live workout") {
    LiveWorkoutPreview()
}

#Preview("Live workout, dark") {
    LiveWorkoutPreview()
        .preferredColorScheme(.dark)
}
#endif
