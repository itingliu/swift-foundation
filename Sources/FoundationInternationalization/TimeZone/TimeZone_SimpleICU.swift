//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
import FoundationEssentials
#endif

enum TimeZoneError: Error {
    case invalidDate
    case calculateError
}

// Like ICU's SimpleTimeZone: TimeZone that works with Gregorian Calendar
internal final class TimeZone_SimpleICU: _TimeZoneProtocol {

    var rawOffset: Int {
        fatalError()
    }

    let useDaylight: Bool
    init?(secondsFromGMT: Int) {
        fatalError("Unexpected init")
    }

    let identifier: String
    init?(identifier: String) {
        self.identifier = identifier
        // TODO:
        self.useDaylight = false
    }
    
    func secondsFromGMT(for date: Date) -> Int {
        fatalError()
    }
    
    func rawAndDaylightSavingTimeOffset(for date: Date, repeatedTimePolicy: TimeZone.DaylightSavingTimePolicy, skippedTimePolicy: TimeZone.DaylightSavingTimePolicy) -> (rawOffset: Int, daylightSavingOffset: TimeInterval) {
        fatalError()
    }
    
    func abbreviation(for date: Date) -> String? {
        fatalError()
    }
    
    func isDaylightSavingTime(for date: Date) -> Bool {
        fatalError()
    }
    
    func daylightSavingTimeOffset(for date: Date) -> TimeInterval {
        fatalError()
    }
    
    func nextDaylightSavingTimeTransition(after date: Date) -> Date? {
        fatalError()
    }
    
    func localizedName(for style: TimeZone.NameStyle, locale: Locale?) -> String? {
        fatalError()
    }

    // MARK: --- ICU Clone

    // TimeZone::getOffset(UDate...) local == false
    func dstOffsetNotLocal(ofDate date: Date) throws -> Int {
        guard useDaylight else {
            return 0
        }

        // TODO: cap date
        // Add raw offset to convert to local standard millis (since local == false)
        let adjustedDate = date.addingTimeInterval(Double(rawOffset))

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([ .year, .month, .day, .weekday, .nanosecond], from: adjustedDate)

        guard let year = components.year,
              let month = components.month,
              let dom = components.day,
              let dow = components.weekday, let nanos = components.nanosecond
        else {
            throw TimeZoneError.invalidDate
        }

        let monthLength = _CalendarGregorian.numberOfDaysInMonth(month, year: year)
        let prevMonthLength = if month > 0 { _CalendarGregorian.numberOfDaysInMonth(month - 1, year: year)
        } else {
            31
        }
        // Call the DST offset calculation with the calendar fields
        let totalOffset = try totalOffset(ofEra: 1, year: year, month: month - 1, // Convert to 0-based month
                                       dom: dom, dow: dow - 1, // Convert to 0-based weekday
                                          nanos: nanos, monthLength: monthLength, previousMonthLength: prevMonthLength)

        // Return only the DST portion (subtract raw offset)
        return totalOffset - rawOffset
    }

    // int32_t SimpleTimeZone::getOffset(uint8_t era, int32_t year, int32_t month, int32_t day, uint8_t dayOfWeek, int32_t millis, int32_t monthLength, int32_t prevMonthLength, UErrorCode& status)
    // use rawOffset directly to get it
    func totalOffset(ofEra era: Int, year: Int, month: Int, dom: Int, dow: Int, nanos: Int, monthLength: Int, previousMonthLength: Int) throws -> Int {
        // TODO: verify input

        guard useDaylight else {
            return rawOffset
        }
        var result = rawOffset

        fatalError()
    }

    // SimpleTimeZone::compareToRule
    func compareToRule() {

    }

}
