import SwiftUI
import Domain
import DesignSystem

/// Today's doses as a checklist, weekly adherence, refill warnings, and the medication list.
/// Embed it in a `NavigationStack`; it sets its own title.
public struct MedicationView: View {
    @State private var viewModel: MedicationViewModel
    @State private var editing: Medication?
    @State private var isAdding = false

    public init(viewModel: MedicationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.m) {
                summaryCard
                if !viewModel.book.runningLow.isEmpty { refillCard }
                todayCard
                listCard
                Text("FitTracker helps you remember doses you already take. It doesn't give medical advice; ask your doctor or pharmacist about changes.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.m)
        }
        .calmBackground(.medication)
        .navigationTitle("Medication")
        .toolbar {
            Button("Add Medication", systemImage: "plus") { isAdding = true }
        }
        .sheet(isPresented: $isAdding) {
            MedicationEditor(viewModel: viewModel, medication: nil)
        }
        .sheet(item: $editing) { medication in
            MedicationEditor(viewModel: viewModel, medication: medication)
        }
        .task { await viewModel.load() }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var summaryCard: some View {
        HStack(spacing: Spacing.l) {
            ZStack {
                ProgressRing(progress: viewModel.todayFraction, style: .medication, lineWidth: 14)
                Image(systemName: "pills.fill")
                    .font(.title)
                    .foregroundStyle(RingStyle.medication.gradient)
                    .symbolEffect(.bounce, value: viewModel.todayFraction)
            }
            .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                let doses = viewModel.todaysDoses
                Text("\(doses.count { $0.status == .taken }) of \(doses.count) taken")
                    .font(.title3.bold())
                    .contentTransition(.numericText())
                Text("today").foregroundStyle(.secondary)
                if let adherence = viewModel.weekAdherence {
                    Text("\(adherence, format: .percent.precision(.fractionLength(0))) this week")
                        .font(.subheadline.weight(.medium))
                }
            }
            Spacer(minLength: 0)
        }
        .card()
    }

    private var refillCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Label("Running low", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
                .symbolEffect(.wiggle, options: .nonRepeating)
            ForEach(viewModel.book.runningLow) { medication in
                Text("\(medication.name): \(medication.remaining ?? 0) left")
                    .font(.subheadline)
            }
        }
        .card()
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Today").font(.headline)
            if viewModel.todaysDoses.isEmpty {
                Text("Add a medication to see today's doses here.").font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(viewModel.todaysDoses) { dose in
                DoseRow(dose: dose) {
                    Task { await viewModel.toggleTaken(dose) }
                } skip: {
                    Task { await viewModel.skip(dose) }
                }
            }
        }
        .card()
        .animation(.spring(duration: 0.35), value: viewModel.todaysDoses)
    }

    private var listCard: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Medications").font(.headline)
            ForEach(viewModel.book.medications) { medication in
                Button { editing = medication } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(medication.name).font(.body.weight(.medium))
                            Text(([medication.dose] + medication.times.map(\.text)).filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .card()
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil && !isAdding && editing == nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }
}

extension DoseTime {
    /// "08:00" in the user's locale.
    var text: String {
        (Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? .now)
            .formatted(date: .omitted, time: .shortened)
    }
}

private struct DoseRow: View {
    let dose: ScheduledDose
    let toggle: () -> Void
    let skip: () -> Void

    var body: some View {
        HStack(spacing: Spacing.m) {
            Button(action: toggle) {
                ZStack {
                    Circle().strokeBorder(RingStyle.medication.start, lineWidth: 2)
                    if dose.status == .taken {
                        Circle().fill(RingStyle.medication.gradient)
                        Image(systemName: "checkmark").font(.caption.weight(.heavy)).foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.success, trigger: dose.status == .taken)
            .accessibilityLabel(dose.status == .taken ? "Taken. Tap to undo" : "Mark as taken")

            VStack(alignment: .leading) {
                Text(dose.medication.name)
                    .strikethrough(dose.status == .skipped)
                Text([dose.key.time.text, dose.medication.dose].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if dose.status == .skipped {
                Text("Skipped").font(.caption).foregroundStyle(.secondary)
            } else if dose.status == nil {
                Button("Skip", action: skip).font(.caption).buttonStyle(.bordered)
            }
        }
    }
}

private struct MedicationEditor: View {
    let viewModel: MedicationViewModel
    let original: Medication?

    @State private var name: String
    @State private var dose: String
    @State private var times: [Date]
    @State private var tracksStock: Bool
    @State private var remaining: Int
    @Environment(\.dismiss) private var dismiss

    init(viewModel: MedicationViewModel, medication: Medication?) {
        self.viewModel = viewModel
        self.original = medication
        self.name = medication?.name ?? ""
        self.dose = medication?.dose ?? ""
        let calendar = Calendar.current
        self.times = (medication?.times ?? [DoseTime(hour: 8)]).map {
            calendar.date(from: DateComponents(hour: $0.hour, minute: $0.minute)) ?? .now
        }
        self.tracksStock = medication?.remaining != nil
        self.remaining = medication?.remaining ?? 30
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Dose (e.g. 500 mg)", text: $dose)
                }
                Section("Times") {
                    ForEach(times.indices, id: \.self) { index in
                        DatePicker("Dose \(index + 1)", selection: $times[index], displayedComponents: .hourAndMinute)
                    }
                    .onDelete { times.remove(atOffsets: $0) }
                    Button("Add Time", systemImage: "plus") {
                        times.append(Calendar.current.date(from: DateComponents(hour: 20)) ?? .now)
                    }
                }
                Section {
                    Toggle("Track pack size", isOn: $tracksStock)
                    if tracksStock {
                        Stepper("\(remaining) doses left", value: $remaining, in: 0...999)
                    }
                } footer: {
                    Text("You'll see a warning when about three days of doses are left.")
                }
                if let error = viewModel.errorMessage {
                    Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                }
                if let original {
                    Section {
                        Button("Delete Medication", role: .destructive) {
                            Task {
                                await viewModel.remove(original.id)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .calmBackground(.medication)
            .navigationTitle(original == nil ? "New Medication" : "Edit Medication")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.errorMessage = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                }
            }
        }
    }

    private func save() async {
        let calendar = Calendar.current
        let medication = Medication(
            id: original?.id ?? UUID(),
            name: name,
            dose: dose,
            times: times.map {
                let parts = calendar.dateComponents([.hour, .minute], from: $0)
                return DoseTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
            },
            remaining: tracksStock ? remaining : nil,
            startDay: original?.startDay ?? viewModel.today
        )
        if await viewModel.save(medication) { dismiss() }
    }
}
