extension DateComponents {
    init(_ recurrenceRule: Calendar.RecurrenceRule) {
        // FIXME: Stub
    }
}

extension Calendar.MatchingPolicy {
    
}

extension Calendar {

    /// Find recurrences of the given date according to the specified recurrence
    /// rule
    /// - Parameter start: the first date in the sequence
    /// - Parameter rule: the recurrence rule that specified how the date should
    ///   repeat
    /// - Returns: a sequence of dates conforming to the recurrence rule. If the
    ///   rule is invalid, returns an empty sequence.
    func recurrences(of start: Date, by rule: RecurrenceRule) -> some Sequence<Date> {
        dates(byMatching: DateComponents(rule), startingAt: .now)
    }

    /// A rule which specifies how often an event should repeat in the future
    /// 
    /// Use a `Calendar` instance to compute future ocurrences of a date using a
    /// recurrence rule with the ``Calendar.recurrences(of: , by:)`` method.
    /// 
    /// A recurrence rule is agnostic to a calendar. Thus, valid values for day,
    /// month, and week might vary depending on which calendar uses the rule.
    /// 
    /// This is compatible with RFC-5545 and RFC-7529, with the exception of the
    /// RSCALE field which has been omitted from the recurrence rule. Instead it
    /// is specified by the Calendar instance which computes the recurrences.
    struct RecurrenceRule: Codable, Sendable {
        enum Frequency {
            case secondly, minutely, hourly, daily, weekly, monthly, yearly
        }
        enum SkipRule {
            /// Ignore invalid dates
            case omit
            /// Change dates with an invalid month or day-to-month to dates with
            /// the previous vaild month or day-to-month respectively
            case backward
            /// Change dates with an invalid month or day-to-month to dates with
            /// with the next vaild month or day-to-month respectively:
            case forward
        }
        
        /// How to process invalid dates
        var skip: SkipRule
        
        /// How often the event repeats
        var frequency: Frequency
        /// At which interval 
        var interval: Int
        
        enum Validity {
            /// The event repeats `n` number of times
            case count(Int)
            /// The event repeats until the given date, inclusively
            case until(Date)
        }
        /// How long the event will repeat. If `nil`, the event repeats forever.
        var validity: Validity?
        
        enum Weekday {
            /// Repeat on every weekday
            case every(Locale.Weekday)
            /// Repeat on the n-th instance of the specified weekday in a month,
            /// if the recurrence has a monthly frequency. If the recurrence has
            /// a yearly frequency, repeat on the n-th week of the year.
            /// 
            /// If n is negative, repeat on the n-to-last of the given weekday.
            case nth(Int, Locale.Weekday)
        }
        
        /// Uniquely identifies a month in any calendar system
        struct Month {
            var index: Int
            var isLeap: Bool
           
            init(_ index: Int, isLeap: Bool = false)
        }
        
        /// On which seconds of the minute the event should repeat. Valid values
        /// between 0 and 59
        var seconds: [Int]?
        /// On which minutes of the hour the event should repeat. Accepts values
        /// between 0 and 59
        var minutes: [Int]?
        /// On which hours of a 24-hour day the event should repeat.
        var hours: [Int]?
        /// On which days of the week the event should occur
        var daysOfTheWeek: [Weekday]?
        /// On which days in the month the event should occur
        /// - 1 signifies the first day of the month.
        /// - Negative values point to a day counted backwards from the last day
        ///   of the month
        var daysOfTheMonth: [Int]?
        /// On which days of the year the event may occur.
        /// - 1 signifies the first day of the year.
        /// - Negative values point to a day counted backwards from the last day
        ///   of the year
        var daysOfTheYear: [Int]?
        /// On which months the event should occur.
        /// - 1 is the first month of the year (January in Gregorian calendars)
        var months: [Month]?
        /// On which weeks of the year the event should occur.
        /// - 1 is the first week which contains at least 4 days in the calendar
        ///   year.
        /// - Negative values refer to weeks if counting backwards from the last
        ///   week of the year
        var weeks: [Int]?
        /// Which ocurrences within every interval should be returned
        var setPositions: [Int]?
        
        init(frequency: Frequency, until: Date)
        init(frequency: Frequency, count: Int)
        init(frequency: Frequency)
    }
}
