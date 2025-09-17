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

// Like ICU's SimpleTimeZone: TimeZone that works with Gregorian Calendar
internal final class TimeZone_SimpleICU: _TimeZoneProtocol {

    var rawOffset: Int {
        fatalError()
    }

    init?(secondsFromGMT: Int) {
        fatalError("Unexpected init")
    }

    let identifier: String
    init?(identifier: String) {
        self.identifier = identifier
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

    // SimpleTimeZone::getOffset
    func offset(ofEra era: Int, year: Int, month: Int, dom: Int, dow: Int, millis: Int, monthLength: Int) -> Int? {
        fatalError()
    }


}
