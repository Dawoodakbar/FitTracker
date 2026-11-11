import SwiftUI
import Domain
import DesignSystem

/// Last night on a 24-hour dial, the week as bars against the goal, and a consistency score.
/// Embed it in a `NavigationStack`; it sets its own title.
public struct SleepView: View {
    @State private var viewModel: SleepViewModel
    @State private var isLogging = false

    public init(viewModel: SleepViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                lastNightCard
                weekCard
                if let stats = viewModel.weekStats { statsCard(stats) }
                historyCard
            }
            .padding(Spacing.m)
        }
        .calmBackground(.sleep)
        .navigationTitle("Sleep")
        .toolbar {
            Button("Log Sleep", systemImage: "plus") { isLogging = true }
        }
        .sheet(isPresented: $isLogging) {
            LogSleepSheet(viewModel: viewModel)
        }
        .task { await viewModel.load() }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var lastNightCard: some View {
        VStack(spacing: Spacing.m) {
            Text("Last night").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            ZStack {
                SleepDial(
                    bedMinutes: viewModel.lastNight.map { viewModel.minutesAfterMidnight($0.bedtime) },
                    wakeMinutes: viewModel.lastNight.map { viewModel.minutesAfterMidnight($0.wakeTime) }
                )
                VStack(spacing: Spacing.xs) {
                    if let night = viewModel.lastNight {
                        Text(Self.hoursText(night.duration))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .contentTransition(.numericText())
                        Text("\(night.bedtime.formatted(date: .omitted, time: .shortened)) – \(night.wakeTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                        QualityStars(quality: night.quality)
                    } else {
                        Text("Not logged").font(.title3.bold())
                        Button("Log last night") { isLogging = true }
                            .buttonStyle(.borderedProminent)
                            .tint(RingStyle.sleep.end)
                            .foregroundStyle(Palette.night)
                    }
                }
            }
            .frame(maxWidth: 280)
            .animation(.smooth, value: viewModel.lastNight)
        }
        .card()
    }

    private var weekCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("This week").font(.headline)
            Text("Dashed line: \(Int(SleepViewModel.goalHours)) h goal").font(.caption).foregroundStyle(.secondary)
            WeekBars(
                bars: viewModel.week.enumerated().map { index, night in
                    WeekBars.Bar(
                        id: index,
                        label: night.day.startDate().formatted(.dateTime.weekday(.narrow)),
                        value: night.hours,
                        isHighlighted: night.day == viewModel.today
                    )
                },
                goal: SleepViewModel.goalHours,
                style: .sleep
            )
            .frame(height: 150)
            // Redraw (and re-animate) when a night is added or removed.
            .id(viewModel.journal.entries.count)
        }
        .card()
    }

    private func statsCard(_ stats: SleepStats) -> some View {
        HStack(spacing: Spacing.m) {
            StatTile(title: "Average", value: Self.hoursText(stats.averageDuration), symbol: "bed.double.fill")
            StatTile(
                title: "Consistency",
                value: stats.consistency.map { "\($0)" } ?? "—",
                symbol: "metronome.fill",
                footnote: stats.consistency == nil ? "Log 3 nights" : "Same times = higher"
            )
        }
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Journal").font(.headline)
            if viewModel.journal.entries.isEmpty {
                Text("Nights you log appear here. Going to bed and waking at the same times each day is one of the best things you can do for your sleep.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(viewModel.journal.entries.prefix(14)) { entry in
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.wakeTime.formatted(.dateTime.weekday(.wide).day().month()))
                        Text("\(entry.bedtime.formatted(date: .omitted, time: .shortened)) – \(entry.wakeTime.formatted(date: .omitted, time: .shortened))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(Self.hoursText(entry.duration)).monospacedDigit().bold()
                }
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task { await viewModel.delete(entry.id) }
                    }
                }
            }
        }
        .card()
    }

    static func hoursText(_ duration: TimeInterval) -> String {
        Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

struct QualityStars: View {
    let quality: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(SleepEntry.qualityRange, id: \.self) { star in
                Image(systemName: star <= quality ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(star <= quality ? AnyShapeStyle(RingStyle.sleep.end) : AnyShapeStyle(.tertiary))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Quality \(quality) of 5")
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let symbol: String
    var footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(title, systemImage: symbol).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.bold()).contentTransition(.numericText())
            if let footnote {
                Text(footnote).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}

private struct LogSleepSheet: View {
    let viewModel: SleepViewModel
    @State private var bedtime: Date
    @State private var wakeTime: Date
    @State private var quality = 3
    @Environment(\.dismiss) private var dismiss

    init(viewModel: SleepViewModel) {
        self.viewModel = viewModel
        let times = viewModel.suggestedTimes()
        self.bedtime = times.bedtime
        self.wakeTime = times.wakeTime
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SleepDial(bedMinutes: viewModel.minutesAfterMidnight(bedtime), wakeMinutes: viewModel.minutesAfterMidnight(wakeTime))
                        .frame(maxWidth: 200)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
                Section {
                    DatePicker("Bedtime", selection: $bedtime)
                    DatePicker("Woke up", selection: $wakeTime)
                }
                if let error = viewModel.errorMessage {
                    Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                }
                Section("How did you sleep?") {
                    Picker("Quality", selection: $quality) {
                        ForEach(SleepEntry.qualityRange, id: \.self) { Text("\($0)").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .calmBackground(.sleep)
            .navigationTitle("Log Sleep")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.log(bedtime: bedtime, wakeTime: wakeTime, quality: quality) { dismiss() }
                        }
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
