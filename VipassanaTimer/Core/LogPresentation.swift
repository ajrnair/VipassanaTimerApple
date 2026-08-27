import Foundation

/// One month of the log, ready for the screen: the records in their arriving
/// order, the month's total sitting time, and a stable identity the list can
/// scroll to. Records arrive newest first and are never re-sorted here.
public struct MonthSection: Equatable, Identifiable, Sendable {
    /// Stable across renders and locales — "2026-08" — so it can anchor a
    /// `ScrollViewReader` jump and an expanded/collapsed set.
    public let id: String
    /// "August 2026", in the current locale.
    public let title: String
    public let records: [MeditationRecord]
    public let totalDuration: TimeInterval
    /// Midnight on the first day of the month, for calendar layout.
    public let monthStart: Date

    public init(
        id: String,
        title: String,
        records: [MeditationRecord],
        totalDuration: TimeInterval,
        monthStart: Date
    ) {
        self.id = id
        self.title = title
        self.records = records
        self.totalDuration = totalDuration
        self.monthStart = monthStart
    }
}

/// A month laid out for the calendar grid. A day either held practice or it
/// did not — deliberately nothing else. No counts, no chains, no completeness:
/// the constitution rules out anything that reads as a streak or a score, and
/// this type is shaped so a louder calendar cannot be built on it by accident.
public struct MonthGrid: Equatable, Sendable {
    /// Empty cells before day 1, honoring the calendar's first weekday.
    public let leadingBlanks: Int
    public let days: [Day]

    public struct Day: Equatable, Identifiable, Sendable {
        public let date: Date
        public let dayNumber: Int
        public let practiced: Bool
        public var id: Date { date }

        public init(date: Date, dayNumber: Int, practiced: Bool) {
            self.date = date
            self.dayNumber = dayNumber
            self.practiced = practiced
        }
    }

    public init(leadingBlanks: Int, days: [Day]) {
        self.leadingBlanks = leadingBlanks
        self.days = days
    }
}

/// Pure presentation math for the log screen, kept in Core so it is tested.
/// The view used to do the month grouping inline; a log holding years of daily
/// practice deserves the grouping, the totals, and the grid to be computed
/// once per data change rather than on every render — `AppModel` calls these
/// from `reloadHistory()`.
public enum LogPresentation {
    /// Sittings credited under a minute are not practice worth recording.
    /// Newer builds no longer store them; older ones did, so the floor is
    /// applied here for every consumer of the sections.
    public static let minimumVisibleDuration: TimeInterval = 60

    /// Groups records (already newest-first) under month headings, preserving
    /// the incoming order, and sums each month's credited time.
    public static func monthSections(
        from records: [MeditationRecord],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [MonthSection] {
        let titleFormatter = DateFormatter()
        titleFormatter.calendar = calendar
        titleFormatter.timeZone = calendar.timeZone
        titleFormatter.dateFormat = "LLLL yyyy"

        var sections: [MonthSection] = []
        var working: (id: String, title: String, monthStart: Date, records: [MeditationRecord], total: TimeInterval)?

        func flush() {
            if let section = working {
                sections.append(MonthSection(
                    id: section.id,
                    title: section.title,
                    records: section.records,
                    totalDuration: section.total,
                    monthStart: section.monthStart
                ))
            }
            working = nil
        }

        for record in records where record.creditedDuration >= minimumVisibleDuration {
            let components = calendar.dateComponents([.year, .month], from: record.endedAt)
            guard let year = components.year, let month = components.month,
                  let monthStart = calendar.date(from: components) else { continue }
            let id = String(format: "%04d-%02d", year, month)

            if working?.id == id {
                working?.records.append(record)
                working?.total += record.creditedDuration
            } else {
                flush()
                working = (
                    id: id,
                    title: titleFormatter.string(from: record.endedAt),
                    monthStart: monthStart,
                    records: [record],
                    total: record.creditedDuration
                )
            }
        }
        flush()
        return sections
    }

    /// Lays one month out for the seven-column grid. `totals` is the practiced
    /// day list (`HistoryStore.dailyTotals`); only membership is read from it.
    public static func monthGrid(
        for monthStart: Date,
        totals: [DailyTotal],
        calendar: Calendar = .autoupdatingCurrent
    ) -> MonthGrid {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return MonthGrid(leadingBlanks: 0, days: [])
        }

        let practicedDays: Set<Date> = Set(totals.compactMap { total in
            calendar.startOfDay(for: total.date)
        })

        // How many empty cells sit before day 1 in a week laid out from the
        // calendar's own first weekday (Monday-first in much of the world,
        // Sunday-first in the US).
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var days: [MonthGrid.Day] = []
        for dayNumber in dayRange {
            guard let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: monthStart) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            days.append(MonthGrid.Day(
                date: dayStart,
                dayNumber: dayNumber,
                practiced: practicedDays.contains(dayStart)
            ))
        }
        return MonthGrid(leadingBlanks: leadingBlanks, days: days)
    }
}
