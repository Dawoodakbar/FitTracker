/// Schedules "time for your medication" reminders. The app implements this with local
/// notifications; tests and previews use an implementation that does nothing.
public protocol MedicationReminders: Sendable {
    /// Makes the scheduled reminders match `medications` exactly, replacing any earlier ones.
    func sync(with medications: [Medication]) async
}

/// For previews and tests, and for when reminders are turned off.
public struct NoMedicationReminders: MedicationReminders {
    public init() {}
    public func sync(with medications: [Medication]) async {}
}
