import Foundation
import Testing
@testable import Domain

@Suite("Sleep journal")
struct SleepJournalTests {
    /// A night ending on `day`: in bed the evening before at `bed`, up at `wake`.
    func night(endingOn day: Day, bed: (Int, Int) = (23, 0), wake: (Int, Int) = (7, 0), quality: Int = 3) throws -> SleepEntry {
        try SleepEntry(
            bedtime: date(day.adding(days: -1, calendar: utc), bed.0, bed.1),
            wakeTime: date(day, wake.0, wake.1),
            quality: quality
        )
    }

    @Test("Rejects a wake time not after bedtime")
    func rejectsBackwards() {
        #expect(throws: SleepError.wakeNotAfterBedtime) {
            try SleepEntry(bedtime: date(march3, 7), wakeTime: date(march3, 7))
        }
    }

    @Test("Rejects a night longer than 24 hours")
    func rejectsTooLong() {
        #expect(throws: SleepError.longerThanADay) {
            try SleepEntry(bedtime: date(march3, 0), wakeTime: date(march3.adding(days: 1, calendar: utc), 1))
        }
    }

    @Test("Quality is clamped to 1...5", arguments: [(0, 1), (3, 3), (9, 5)])
    func clampsQuality(input: Int, expected: Int) throws {
        #expect(try night(endingOn: march3, quality: input).quality == expected)
    }

    @Test("Logging the same day again replaces the earlier night")
    func oneNightPerDay() throws {
        var journal = SleepJournal()
        journal.log(try night(endingOn: march3, wake: (6, 0)), calendar: utc)
        journal.log(try night(endingOn: march3, wake: (8, 0)), calendar: utc)
        #expect(journal.entries.count == 1)
        #expect(journal.entry(on: march3, calendar: utc)?.duration == TimeInterval(9 * 3600))
    }

    @Test("Stats average only the logged nights")
    func average() throws {
        var journal = SleepJournal()
        journal.log(try night(endingOn: march3, wake: (7, 0)), calendar: utc)                       // 8 h
        journal.log(try night(endingOn: march3.adding(days: -2, calendar: utc), wake: (5, 0)), calendar: utc)  // 6 h
        let stats = try #require(journal.stats(endingOn: march3, days: 7, calendar: utc))
        #expect(stats.nights == 2)
        #expect(stats.averageDuration == TimeInterval(7 * 3600))
        #expect(stats.consistency == nil)
    }

    @Test("Identical times every night score 100")
    func perfectConsistency() throws {
        var journal = SleepJournal()
        for offset in 0..<5 {
            journal.log(try night(endingOn: march3.adding(days: -offset, calendar: utc)), calendar: utc)
        }
        #expect(journal.stats(endingOn: march3, calendar: utc)?.consistency == 100)
    }

    @Test("Bedtimes either side of midnight are close, not 23 hours apart")
    func midnightWraps() throws {
        var journal = SleepJournal()
        let day2 = march3.adding(days: -1, calendar: utc), day1 = march3.adding(days: -2, calendar: utc)
        journal.log(try night(endingOn: day1, bed: (23, 30)), calendar: utc)
        journal.log(try SleepEntry(bedtime: date(day2, 0, 30), wakeTime: date(day2, 7)), calendar: utc)
        journal.log(try SleepEntry(bedtime: date(march3, 0, 0), wakeTime: date(march3, 7)), calendar: utc)
        // Bedtimes 23:30, 00:30, 00:00 vary by about 25 minutes: still a fairly regular week.
        let consistency = try #require(journal.stats(endingOn: march3, calendar: utc)?.consistency)
        #expect(consistency > 80)
    }

    @Test("Very irregular nights score low")
    func irregular() throws {
        var journal = SleepJournal()
        let times: [((Int, Int), (Int, Int))] = [((21, 0), (5, 0)), ((2, 0), (10, 0)), ((20, 0), (4, 0)), ((3, 0), (11, 0))]
        for (offset, time) in times.enumerated() {
            let day = march3.adding(days: -offset, calendar: utc)
            // Bedtimes after midnight belong to the same calendar day as the wake time.
            let bedDay = time.0.0 < 12 ? day : day.adding(days: -1, calendar: utc)
            journal.log(try SleepEntry(bedtime: date(bedDay, time.0.0), wakeTime: date(day, time.1.0)), calendar: utc)
        }
        #expect(try #require(journal.stats(endingOn: march3, calendar: utc)?.consistency) < 30)
    }

    @Test("Decoding runs the same validation")
    func decodingValidates() throws {
        let json = #"{"id":"00000000-0000-0000-0000-000000000000","bedtime":10,"wakeTime":5,"quality":3}"#
        #expect(throws: SleepError.self) {
            try JSONDecoder().decode(SleepEntry.self, from: Data(json.utf8))
        }
    }
}
