import Foundation
import Testing
@testable import Domain

@Suite("Medication book")
struct MedicationBookTests {
    let morning = DoseTime(hour: 8)
    let evening = DoseTime(hour: 20)

    func medication(remaining: Int? = nil, startDay: Day = march3) -> Medication {
        Medication(name: "  Metformin ", dose: "500 mg", times: [evening, morning, morning], remaining: remaining, startDay: startDay)
    }

    @Test("Names are trimmed and times sorted without duplicates")
    func normalizes() {
        let med = medication()
        #expect(med.name == "Metformin")
        #expect(med.times == [morning, evening])
    }

    @Test("Dose times clamp to a real clock time")
    func clampsTime() {
        #expect(DoseTime(hour: 25, minute: -3) == DoseTime(hour: 23, minute: 0))
    }

    @Test("A day lists one dose per time, earliest first")
    func dosesOnDay() {
        var book = MedicationBook()
        book.save(medication())
        #expect(book.doses(on: march3).map(\.key.time) == [morning, evening])
    }

    @Test("Medications that start later aren't due yet")
    func respectsStartDay() {
        var book = MedicationBook()
        book.save(medication(startDay: march3.adding(days: 1, calendar: utc)))
        #expect(book.doses(on: march3).isEmpty)
    }

    @Test("Taking a dose uses one from the pack, and undoing puts it back")
    func stock() throws {
        var book = MedicationBook()
        let med = medication(remaining: 10)
        book.save(med)
        let key = DoseKey(medicationID: med.id, day: march3, time: morning)

        book.mark(key, as: .taken)
        #expect(book.medications[0].remaining == 9)
        book.mark(key, as: .taken)
        #expect(book.medications[0].remaining == 9, "Marking taken twice must not count twice")
        book.mark(key, as: nil)
        #expect(book.medications[0].remaining == 10)
    }

    @Test("Adherence is taken ÷ scheduled over the window")
    func adherence() throws {
        var book = MedicationBook()
        let med = medication()
        book.save(med)
        book.mark(DoseKey(medicationID: med.id, day: march3, time: morning), as: .taken)
        book.mark(DoseKey(medicationID: med.id, day: march3, time: evening), as: .skipped)
        #expect(book.adherence(endingOn: march3, days: 1, calendar: utc) == 0.5)
    }

    @Test("Adherence is nil when nothing was scheduled")
    func adherenceEmpty() {
        #expect(MedicationBook().adherence(endingOn: march3, calendar: utc) == nil)
    }

    @Test("Running low means three days of doses or fewer", arguments: [(6, true), (7, false)])
    func runningLow(remaining: Int, isLow: Bool) {
        var book = MedicationBook()
        book.save(medication(remaining: remaining))  // 2 doses a day → 6 is three days
        #expect(book.runningLow.isEmpty == !isLow)
    }

    @Test("Removing a medication removes its records")
    func removeCleansUp() {
        var book = MedicationBook()
        let med = medication()
        book.save(med)
        book.mark(DoseKey(medicationID: med.id, day: march3, time: morning), as: .taken)
        book.remove(id: med.id)
        #expect(book.records.isEmpty)
    }

    @Test("A book survives a JSON round trip")
    func codable() throws {
        var book = MedicationBook()
        let med = medication(remaining: 4)
        book.save(med)
        book.mark(DoseKey(medicationID: med.id, day: march3, time: morning), as: .taken)
        let decoded = try JSONDecoder().decode(MedicationBook.self, from: JSONEncoder().encode(book))
        #expect(decoded == book)
    }
}
