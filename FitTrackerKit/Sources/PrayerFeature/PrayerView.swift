import SwiftUI
import Domain
import DesignSystem

/// The five daily prayers as large tap targets, a week of rings, and the current streak.
/// Private by design: everything stays on the device. Embed it in a `NavigationStack`.
public struct PrayerView: View {
    @State private var viewModel: PrayerViewModel
    @State private var celebration: Date?

    public init(viewModel: PrayerViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                streakCard
                dayCard
                Text("Tap once for on time, again for prayed late, and once more to clear. Your log never leaves this phone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.m)
            }
            .padding(Spacing.m)
        }
        .overlay { if let celebration { ConfettiBurst(startDate: celebration) } }
        .calmBackground(.prayer)
        .navigationTitle("Prayer")
        .task { await viewModel.load() }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var streakCard: some View {
        VStack(spacing: Spacing.m) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.largeTitle)
                    .foregroundStyle(RingStyle.plan.gradient)
                    .symbolEffect(.bounce, value: viewModel.streak)
                VStack(alignment: .leading) {
                    Text("\(viewModel.streak) day streak")
                        .font(.title2.bold())
                        .contentTransition(.numericText())
                    Text("Days with all five prayers").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            DayDots(
                dots: viewModel.week.enumerated().map { index, entry in
                    DayDots.Dot(
                        id: index,
                        label: entry.day.startDate().formatted(.dateTime.weekday(.narrow)),
                        fraction: entry.fraction,
                        isToday: entry.day == viewModel.today
                    )
                },
                style: .prayer
            )
        }
        .card()
        .animation(.smooth, value: viewModel.streak)
    }

    private var dayCard: some View {
        VStack(spacing: Spacing.m) {
            HStack {
                Button("Previous Day", systemImage: "chevron.left") { viewModel.step(days: -1) }
                    .labelStyle(.iconOnly)
                Spacer()
                Text(viewModel.selectedDay == viewModel.today ? "Today" : viewModel.selectedDay.startDate().formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.headline)
                    .contentTransition(.opacity)
                Spacer()
                Button("Next Day", systemImage: "chevron.right") { viewModel.step(days: 1) }
                    .labelStyle(.iconOnly)
                    .disabled(!viewModel.canGoForward)
            }
            .animation(.smooth, value: viewModel.selectedDay)

            ForEach(DailyPrayer.allCases) { prayer in
                PrayerButton(prayer: prayer, status: viewModel.status(of: prayer)) {
                    Task {
                        let wasComplete = viewModel.journal.isComplete(on: viewModel.selectedDay)
                        await viewModel.cycle(prayer)
                        if !wasComplete, viewModel.journal.isComplete(on: viewModel.selectedDay) {
                            celebration = .now
                        }
                    }
                }
            }
        }
        .card()
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

extension DailyPrayer {
    var title: String {
        switch self {
        case .fajr: "Fajr"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }

    /// Roughly where the sun is, so the row reads at a glance.
    var symbol: String {
        switch self {
        case .fajr: "sunrise.fill"
        case .dhuhr: "sun.max.fill"
        case .asr: "sun.min.fill"
        case .maghrib: "sunset.fill"
        case .isha: "moon.stars.fill"
        }
    }
}

private struct PrayerButton: View {
    let prayer: DailyPrayer
    let status: PrayerStatus?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: prayer.symbol)
                    .font(.title2)
                    .symbolRenderingMode(.multicolor)
                    .frame(width: 36)
                Text(prayer.title).font(.title3.weight(.semibold))
                Spacer()
                Text(statusText).font(.subheadline.weight(.medium))
                    .contentTransition(.opacity)
                Image(systemName: status == nil ? "circle" : "checkmark.circle.fill")
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .foregroundStyle(status == nil ? AnyShapeStyle(Palette.textPrimary) : AnyShapeStyle(Palette.night))
            .padding(Spacing.m)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(fill)
            }
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.35, bounce: 0.3), value: status)
        .sensoryFeedback(.selection, trigger: status)
        .accessibilityLabel(prayer.title)
        .accessibilityValue(statusText.isEmpty ? "Not prayed" : statusText)
        .accessibilityHint("Tap to change")
    }

    private var statusText: String {
        switch status {
        case nil: ""
        case .onTime: "On time"
        case .late: "Late"
        }
    }

    private var fill: AnyShapeStyle {
        switch status {
        case nil: AnyShapeStyle(Palette.surface)
        case .onTime: AnyShapeStyle(RingStyle.prayer.gradient)
        case .late: AnyShapeStyle(RingStyle.plan.gradient)
        }
    }
}
