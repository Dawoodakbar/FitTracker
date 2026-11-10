import Foundation
@testable import Domain

/// A fixed UTC Gregorian calendar, so day boundaries in tests never depend on the Mac's time zone.
let utc: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar
}()

/// `day` at `hour:minute` UTC.
func date(_ day: Day, _ hour: Int, _ minute: Int = 0) -> Date {
    day.startDate(in: utc).addingTimeInterval(TimeInterval(hour * 3600 + minute * 60))
}

let march3 = Day(year: 2027, month: 3, day: 3)
