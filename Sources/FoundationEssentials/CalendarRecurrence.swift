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

    func dates(byMatching recurrence: RecurrenceRule, startingAt: Date) {}
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
        enum Frequency: Codable {
            case secondly, minutely, hourly, daily, weekly, monthly, yearly
        }
        enum SkipRule: Codable {
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
        var skip: SkipRule = .omit

        /// How often the event repeats
        var frequency: Frequency
        /// At which interval. e.g. Frequency = .daily --> 1 = everyday; 8 = every 8 days
        var interval: Int = 1

        enum Validity: Codable {
            /// The event repeats `n` number of times
            case count(Int)
            /// The event repeats until the given date, inclusively
            case until(Date)
        }
        /// How long the event will repeat. If `nil`, the event repeats forever.
        var validity: Validity? = nil

        enum Weekday: Codable {
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
        struct Month: Codable /*ExpressibleByIntegerLiteral*/ {
//            typealias IntegerLiteralType = Int.self

            var index: Int
            var isLeap: Bool
           
            init(_ index: Int, isLeap: Bool = false) {
                self.index = index
                self.isLeap = isLeap
            }
        }
        
        /// On which seconds of the minute the event should repeat. Valid values
        /// between 0 and 59
        /// Q: nil means every second?
        var seconds: [Int]? = nil
        /// On which minutes of the hour the event should repeat. Accepts values
        /// between 0 and 59
        var minutes: [Int]? = nil
        /// On which hours of a 24-hour day the event should repeat.
        var hours: [Int]? = nil
        /// On which days of the week the event should occur
        var daysOfTheWeek: [Weekday]? = nil
        /// On which days in the month the event should occur
        /// - 1 signifies the first day of the month.
        /// - Negative values point to a day counted backwards from the last day
        ///   of the month
        var daysOfTheMonth: [Int]? = nil
        /// On which days of the year the event may occur.
        /// - 1 signifies the first day of the year.
        /// - Negative values point to a day counted backwards from the last day
        ///   of the year
        var daysOfTheYear: [Int]? = nil
        /// On which months the event should occur.
        /// - 1 is the first month of the year (January in Gregorian calendars)
        /// Valid only for recurrence rules that were initialized with specific days of the month and a frequency type of monthly?
        var months: [Month]? = nil
        /// On which weeks of the year the event should occur.
        /// - 1 is the first week which contains at least 4 days in the calendar
        ///   year.
        /// - Negative values refer to weeks if counting backwards from the last
        ///   week of the year
        var weeks: [Int]? = nil
        /// Which ocurrences within every interval should be returned
        /// freq = monthly / daysOfWeek = Sunday / setPositions = [3] -> Every month on the third Sunday
        var setPositions: [Int]? = nil


        /// Should until be optional?
        init(frequency: Frequency, until: Date?) {
            self.frequency = frequency
            if let until {
                self.validity = .until(until)
            }
        }

        init(frequency: Frequency, count: Int) {
            self.frequency = frequency
            self.validity = .count(count)
        }
        init(frequency: Frequency) {
            self.frequency = frequency
        }


        // MARK: -

//        secondly, minutely, hourly, daily, weekly, monthly, yearly

        static func hourlyRecurrence(onMinutesAndSeconds timeInDay: [(Int, Int)], until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .hourly, until: until)
            //...
            return r
        }

        // daily

        static func dailyRecurrence(onHours hours: [Int]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .daily, until: until)
            r.hours = hours
            return r
        }

        static func dailyRecurrence(onTimeInDay hms: [(hour: Int, minute: Int, second: Int)]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .daily, until: until)
            // ...
            return r
        }

        // weekly

        static func weeklyRecurrence(onDaysOfTheWeek daysOfTheWeek: [Weekday]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .weekly, until: until)
            r.daysOfTheWeek = daysOfTheWeek
            return r
        }

        static func weeklyRecurrence(on weeks: [Int]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .weekly, until: until)
            r.weeks = weeks
            return r
        }

        // monthly
        static func monthlyRecurrence(onDaysOfMonth days: [Int]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .monthly, until: until)
            r.daysOfTheMonth = days
            return r
        }

        static func monthlyRecurrence(onDaysOfWeek daysOfTheWeek: [Weekday]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .monthly, until: until)
            r.daysOfTheWeek = daysOfTheWeek
            return r
        }

        // yearly

        static func yearlyRecurrence(onDaysOfTheWeek daysOfTheWeek: [Weekday]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .yearly, until: until)
            r.daysOfTheWeek = daysOfTheWeek
            return r
        }

        static func yearlyRecurrence(onWeeks weeks: [Int]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .yearly, until: until)
            r.weeks = weeks
            return r
        }

        static func yearlyRecurrence(onMonths months: [Month]?, until: Date? = nil) -> RecurrenceRule {
            var r = RecurrenceRule(frequency: .yearly, until: until)
            r.months = months
            return r
        }
    }
}

// MARK: ----
// Q: Do we need to support secondly?
typealias Month = Calendar.RecurrenceRule.Month
func invalid() {
    var invalid1 = Calendar.RecurrenceRule(frequency: .hourly)
    invalid1.months = [ Month(3) ]
    invalid1.months  = [ 3 ]

    var invalid2 = Calendar.RecurrenceRule(frequency: .hourly)
    invalid2.hours = [ 6, 18 ]

    // can we make this valid
    var r2 = Calendar.RecurrenceRule.monthlyRecurrence(onDaysOfMonth: [15])
    r2.daysOfTheYear = [300]

    // every 4 months, on the 2nd thursday,
    var weekly = Calendar.RecurrenceRule(frequency: .monthly)
    weekly.daysOfTheWeek = [.nth(2, .thursday)]
    weekly.interval = 4
}


func validSmaller() {
    var r = Calendar.RecurrenceRule(frequency: .daily)
    r.hours = [6, 18]
    r.minutes = [0, 30]
    r.seconds = [0, 3, 50]
    // Everyday at 06:00, 06:30, 18:00, 18:30?


    var r2 = Calendar.RecurrenceRule.dailyRecurrence(onTimeInDay: [(6, 0, 0), (7, 30, 0)]) // not valid rule
}

func test() {

    var r = Calendar.RecurrenceRule(frequency: .yearly)
    r.months = [Month(1)]
    r.daysOfTheMonth = [1]

    var c = Calendar(identifier: .chinese)
    _ = c.recurrences(of: .now, by: r)
}

func test2() {
}

protocol Recurring {}

struct YearlyRecurrence: Recurring {}
struct MonthlyRecurrence: Recurring {}

