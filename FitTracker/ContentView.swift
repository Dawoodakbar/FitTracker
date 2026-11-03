import SwiftUI
import Domain

/// A playground screen for the Domain module: pick an age, a formula and a BPM,
/// and watch the same code the tests check turn them into a heart rate zone.
///
/// Flow: age → `MaxHeartRateFormula` → `HeartRateZoneCalculator` → `HeartRateSample` → `HeartRateZone`.
struct ContentView: View {
    @State private var age: Int
    @State private var formula: FormulaChoice
    @State private var bpm: Double

    init(age: Int = 30, formula: FormulaChoice = .fox, bpm: Int = 150) {
        _age = State(initialValue: age)
        _formula = State(initialValue: formula)
        _bpm = State(initialValue: Double(bpm))
    }

    // MARK: - Domain calls

    /// Step 1 + 2: the formula estimates max heart rate, the calculator stores it.
    private var calculator: HeartRateZoneCalculator? {
        switch formula {
        case .fox: try? HeartRateZoneCalculator(age: age, formula: .fox)
        case .tanaka: try? HeartRateZoneCalculator(age: age, formula: .tanaka)
        }
    }

    /// Step 3: one validated reading.
    private var sample: HeartRateSample? {
        try? HeartRateSample(bpm: Int(bpm), date: .now)
    }

    /// Step 4: the sample asks the calculator which zone it is in.
    private var zone: HeartRateZone? {
        guard let calculator, let sample else { return nil }
        return sample.zone(using: calculator)
    }

    // MARK: - UI

    var body: some View {
        NavigationStack {
            Form {
                Section("1. You") {
                    Stepper("Age: \(age)", value: $age, in: 1...120)
                    Picker("Formula", selection: $formula) {
                        ForEach(FormulaChoice.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("2. Max heart rate") {
                    LabeledContent("Estimated max", value: calculator.map { "\($0.maxHeartRate) BPM" } ?? "—")
                    Text(formula.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("3. Heart rate right now") {
                    LabeledContent("Reading", value: "\(Int(bpm)) BPM")
                    Slider(value: $bpm, in: 40...220, step: 1)
                }

                Section("4. Your zone") {
                    ZoneCard(zone: zone, percentOfMax: percentOfMax)
                }

                Section("All zones for max \(calculator?.maxHeartRate ?? 0)") {
                    ForEach(HeartRateZone.allCases, id: \.self) { zone in
                        ZoneRow(zone: zone, lowestBPM: calculator?.lowestBPM(in: zone), isCurrent: zone == self.zone)
                    }
                }
            }
            .navigationTitle("Heart rate zones")
        }
    }

    private var percentOfMax: Int? {
        guard let max = calculator?.maxHeartRate else { return nil }
        return Int(bpm) * 100 / max
    }
}

// MARK: - Formula choice

/// The formulas the user can pick. `MaxHeartRateFormula` is a protocol, so the picker
/// needs a concrete, `Hashable` list to choose from.
enum FormulaChoice: String, CaseIterable, Identifiable {
    case fox, tanaka

    var id: Self { self }

    var title: String {
        switch self {
        case .fox: "Fox"
        case .tanaka: "Tanaka"
        }
    }

    var explanation: String {
        switch self {
        case .fox: "Fox: 220 − age. Simple and widely known."
        case .tanaka: "Tanaka: 208 − 0.7 × age, rounding .5 up. Better for adults over 40."
        }
    }
}

// MARK: - Zone views

private struct ZoneCard: View {
    let zone: HeartRateZone?
    let percentOfMax: Int?

    var body: some View {
        HStack(spacing: 16) {
            Text(zone.map { "\($0.number)" } ?? "–")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .frame(width: 72, height: 72)
                .background(zone?.color.opacity(0.2) ?? Color.secondary.opacity(0.15), in: .rect(cornerRadius: 16))
                .foregroundStyle(zone?.color ?? .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(zone?.name ?? "Resting")
                    .font(.title2.bold())
                Text(percentOfMax.map { "\($0)% of your max" } ?? "")
                    .foregroundStyle(.secondary)
                if zone == nil {
                    Text("Below 50% of max, so no zone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ZoneRow: View {
    let zone: HeartRateZone
    let lowestBPM: Int?
    let isCurrent: Bool

    var body: some View {
        HStack {
            Circle().fill(zone.color).frame(width: 10, height: 10)
            Text("\(zone.number). \(zone.name)")
                .fontWeight(isCurrent ? .bold : .regular)
            Spacer()
            Text(lowestBPM.map { "from \($0) BPM" } ?? "—")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

/// Display-only details. These belong in DesignSystem once that module has real code.
private extension HeartRateZone {
    var name: String {
        switch self {
        case .recovery: "Recovery"
        case .endurance: "Endurance"
        case .aerobic: "Aerobic"
        case .threshold: "Threshold"
        case .maximum: "Maximum"
        }
    }

    var color: Color {
        switch self {
        case .recovery: .gray
        case .endurance: .blue
        case .aerobic: .green
        case .threshold: .orange
        case .maximum: .red
        }
    }
}

// MARK: - Previews
// Each preview is one case from the Domain tests, so you can see what the test checks.

#Preview("Age 30, 150 BPM → zone 3 aerobic") {
    // HeartRateSampleTests.zoneUsingCalculator: (150, .aerobic)
    ContentView(age: 30, bpm: 150)
}

#Preview("Resting 90 BPM → no zone") {
    // HeartRateZoneTests.returnsNilBelowFirstZone + HeartRateSampleTests: (90, nil)
    ContentView(age: 30, bpm: 90)
}

#Preview("Exactly 50% → zone 1 starts") {
    // HeartRateZoneTests.mapsBPMToZone: max 200, (100, .recovery). Age 20 gives max 200.
    ContentView(age: 20, bpm: 100)
}

#Preview("Just below 60% → still zone 1") {
    // HeartRateZoneTests.mapsBPMToZone: max 200, (119, .recovery)
    ContentView(age: 20, bpm: 119)
}

#Preview("190 BPM → zone 5 maximum") {
    // HeartRateSampleTests.zoneUsingCalculator: (190, .maximum)
    ContentView(age: 30, bpm: 190)
}

#Preview("Tanaka, age 25 → max 191") {
    // MaxHeartRateFormulaTests.calculatorUsesGivenFormula: 190.5 rounds up to 191
    ContentView(age: 25, formula: .tanaka, bpm: 150)
}

#Preview("Age 25 → zone 1 starts at 98, not 97") {
    // HeartRateZoneTests.lowestBPMRoundsUp: 50% of 195 = 97.5, rounded up
    ContentView(age: 25, bpm: 98)
}

#Preview("Fox and Tanaka agree at 40 → max 180") {
    // MaxHeartRateFormulaTests.dotSyntax: both formulas give 180 at age 40
    ContentView(age: 40, formula: .tanaka, bpm: 150)
}
