import Foundation
import UserNotifications
import Domain

/// Schedules one repeating local notification per medication dose time.
///
/// Notifications say only "Time for your medication" plus the name, never the dose, so a
/// locked screen shows as little health detail as possible.
public struct LocalNotificationMedicationReminders: MedicationReminders {
    /// Every request this type creates starts with this, so it can remove only its own.
    static let prefix = "medication."

    public init() {}

    public func sync(with medications: [Medication]) async {
        let center = UNUserNotificationCenter.current()
        guard !medications.isEmpty else {
            await removeExisting(from: center)
            return
        }
        // Asked the first time the user adds a medication, when the reason is obvious.
        guard (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true else { return }
        await removeExisting(from: center)

        for medication in medications {
            for time in medication.times {
                let content = UNMutableNotificationContent()
                content.title = "Time for your medication"
                content.body = medication.name
                content.sound = .default
                content.interruptionLevel = .timeSensitive
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(hour: time.hour, minute: time.minute),
                    repeats: true
                )
                let id = "\(Self.prefix)\(medication.id.uuidString).\(time.hour).\(time.minute)"
                try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
            }
        }
    }

    private func removeExisting(from center: UNUserNotificationCenter) async {
        let ids = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
