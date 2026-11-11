import SwiftUI
import DesignSystem
import MedicationFeature
import PrayerFeature

/// The daily rituals in one place: medication and prayer, switched with a segmented control.
struct RitualsView: View {
    enum Ritual: String, CaseIterable, Identifiable {
        case medication = "Medication"
        case prayer = "Prayer"
        var id: Self { self }
    }

    let container: AppContainer
    @Binding var ritual: Ritual

    var body: some View {
        Group {
            switch ritual {
            case .medication: MedicationView(viewModel: container.medicationViewModel)
            case .prayer: PrayerView(viewModel: container.prayerViewModel)
            }
        }
        .safeAreaInset(edge: .top) {
            Picker("Ritual", selection: $ritual.animation(.smooth)) {
                ForEach(Ritual.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.s)
        }
    }
}
