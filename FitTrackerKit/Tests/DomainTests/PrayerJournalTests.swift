import Foundation
import Testing
@testable import Domain

@Suite("Prayer journal")
struct PrayerJournalTests {
    func completeDays(_ days: [Day]) -> PrayerJournal {
        var journal = PrayerJournal()
        for day in days {
            for prayer in DailyPrayer.allCases { journal.set(.onTime, for: prayer, on: day) }
        }
        return journal
    }

    @Test("A tap cycles not prayed → on time → late → not prayed")
    func cycle() {
        var journal = PrayerJournal()
        journal.cycle(.fajr, on: march3)
        #expect(journal.status(of: .fajr, on: march3) == .onTime)
        journal.cycle(.fajr, on: march3)
        #expect(journal.status(of: .fajr, on: march3) == .late)
        journal.cycle(.fajr, on: march3)
        #expect(journal.status(of: .fajr, on: march3) == nil)
        #expect(journal.days.isEmpty, "An empty day is removed, not stored")
    }

    @Test("Late prayers still count towards a complete day")
    func lateCounts() {
        var journal = completeDays([march3])
        journal.set(.late, for: .asr, on: march3)
        #expect(journal.isComplete(on: march3))
    }

    @Test("The streak counts back through complete days")
    func streak() {
        let days = march3.lastDays(3, calendar: utc)
        #expect(completeDays(days).streak(endingOn: march3, calendar: utc) == 3)
    }

    @Test("An unfinished today doesn't break yesterday's streak")
    func todayInProgress() {
        var journal = completeDays(march3.adding(days: -1, calendar: utc).lastDays(2, calendar: utc))
        journal.set(.onTime, for: .fajr, on: march3)
        #expect(journal.streak(endingOn: march3, calendar: utc) == 2)
    }

    @Test("A missed day ends the streak")
    func gapBreaks() {
        let journal = completeDays([march3, march3.adding(days: -2, calendar: utc)])
        #expect(journal.streak(endingOn: march3, calendar: utc) == 1)
    }
}
