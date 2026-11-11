import SwiftUI
import Domain
import DesignSystem
import ZonePresentation

/// Age and max-heart-rate formula, which decide where each zone starts.
/// Embed it in a `NavigationStack`; it sets its own title.
public struct SettingsView: View {
    // No initial value: `@State` is a macro in SDK 27 and is assigned only in `init`.
    @State private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section {
                Stepper("Age: \(viewModel.age)", value: $viewModel.age, in: 1...120)
                Picker("Formula", selection: $viewModel.formulaKind) {
                    ForEach(MaxHeartRateFormulaKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("You")
            } footer: {
                Text(viewModel.formulaKind.explanation)
            }

            Section("Your zones") {
                LabeledContent("Estimated max", value: "\(viewModel.settings.calculator.maxHeartRate) BPM")

                ForEach(HeartRateZone.allCases, id: \.self) { zone in
                    ZoneRow(
                        tone: zone.tone,
                        title: "\(zone.number). \(zone.name)",
                        detail: "from \(viewModel.settings.calculator.lowestBPM(in: zone)) BPM"
                    )
                }
            }
        }
        .calmBackground(.plan)
        .navigationTitle("Settings")
    }
}

extension MaxHeartRateFormulaKind {
    /// Wording shown to users. (To move into a String Catalog when the app is localized.)
    var title: String {
        switch self {
        case .fox: "Fox"
        case .tanaka: "Tanaka"
        }
    }

    var explanation: String {
        switch self {
        case .fox: "Fox: 220 − age. Simple and widely known."
        case .tanaka: "Tanaka: 208 − 0.7 × age. Often more accurate for adults over 40."
        }
    }
}

// MARK: - Previews

#if DEBUG
private final class PreviewSettingsStore: SettingsStore, @unchecked Sendable {
    func load() -> UserSettings { .standard }
    func save(_ settings: UserSettings) {}
}

#Preview("Settings") {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(store: PreviewSettingsStore()))
    }
}
#endif
