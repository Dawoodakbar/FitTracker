import Foundation
import Testing
@testable import Domain

@Suite("Day")
struct DayTests {
    @Test("A date maps to its calendar day")
    func fromDate() {
        #expect(Day(date(march3, 23, 59), calendar: utc) == march3)
    }

    @Test("Adding days crosses month and year ends", arguments: [
        (Day(year: 2027, month: 1, day: 31), 1, Day(year: 2027, month: 2, day: 1)),
        (Day(year: 2027, month: 1, day: 1), -1, Day(year: 2026, month: 12, day: 31)),
        (Day(year: 2028, month: 2, day: 28), 1, Day(year: 2028, month: 2, day: 29))
    ])
    func adding(start: Day, days: Int, expected: Day) {
        #expect(start.adding(days: days, calendar: utc) == expected)
    }

    @Test("lastDays ends on the day itself, oldest first")
    func lastDays() {
        let days = march3.lastDays(3, calendar: utc)
        #expect(days == [Day(year: 2027, month: 3, day: 1), Day(year: 2027, month: 3, day: 2), march3])
    }

    @Test("Days compare by date")
    func comparable() {
        #expect(Day(year: 2027, month: 2, day: 28) < march3)
    }
}
