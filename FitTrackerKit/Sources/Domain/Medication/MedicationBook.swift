import Foundation

/// The user's medications and the record of which doses were taken.
public struct MedicationBook: Codable, Equatable, Sendable {
    /// A pack with this many days of doses left (or fewer) is "running low".
    public static let lowStockDays = 3

    public private(set) var medications: [Medication]
    public private(set) var records: [DoseKey: DoseStatus]

    public init(medications: [Medication] = [], records: [DoseKey: DoseStatus] = [:]) {
        self.medications = medications
        self.records = records
    }

    // MARK: - Editing

    /// Adds `medication`, or replaces the one with the same id.
    public mutating func save(_ medication: Medication) {
        if let index = medications.firstIndex(where: { $0.id == medication.id }) {
            medications[index] = medication
        } else {
            medications.append(medication)
        }
    }

    /// Removes a medication and its dose records.
    public mutating func remove(id: Medication.ID) {
        medications.removeAll { $0.id == id }
        records = records.filter { $0.key.medicationID != id }
    }

    /// Records a dose as taken or skipped, or clears the mark with `nil`.
    /// Taking a dose uses one from the pack; undoing that puts it back.
    public mutating func mark(_ key: DoseKey, as status: DoseStatus?) {
        let previous = records[key]
        guard previous != status else { return }
        records[key] = status
        guard let index = medications.firstIndex(where: { $0.id == key.medicationID }),
              let remaining = medications[index].remaining else { return }
        if status == .taken {
            medications[index].remaining = max(remaining - 1, 0)
        } else if previous == .taken {
            medications[index].remaining = remaining + 1
        }
    }

    // MARK: - Reading

    /// Every dose due on `day`, earliest first. Medications that start later aren't included.
    public func doses(on day: Day) -> [ScheduledDose] {
        medications
            .filter { $0.startDay <= day }
            .flatMap { medication in
                medication.times.map { time in
                    let key = DoseKey(medicationID: medication.id, day: day, time: time)
                    return ScheduledDose(medication: medication, key: key, status: records[key])
                }
            }
            .sorted { ($0.key.time, $0.medication.name) < ($1.key.time, $1.medication.name) }
    }

    /// The share of scheduled doses taken over the `days` days ending on `day` (0...1).
    /// `nil` when nothing was scheduled in that time.
    public func adherence(endingOn day: Day, days: Int = 7, calendar: Calendar = .current) -> Double? {
        let scheduled = day.lastDays(days, calendar: calendar).flatMap { doses(on: $0) }
        guard !scheduled.isEmpty else { return nil }
        return Double(scheduled.count { $0.status == .taken }) / Double(scheduled.count)
    }

    /// Medications with a tracked pack that will run out within `lowStockDays`.
    public var runningLow: [Medication] {
        medications.filter { medication in
            guard let remaining = medication.remaining, !medication.times.isEmpty else { return false }
            return remaining <= medication.times.count * Self.lowStockDays
        }
    }
}
