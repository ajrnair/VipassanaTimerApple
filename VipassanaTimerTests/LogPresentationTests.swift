import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Log presentation")
struct LogPresentationTests {
    /// A fixed calendar so the suite is deterministic on any machine.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        calendar.firstWeekday = 2 // Monday
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func record(
        endedAt: Date,
        minutes: Double = 45,
        note: String? = nil
    ) -> MeditationRecord {
        MeditationRecord(
            id: UUID(),
            plannedDuration: minutes * 60,
            creditedDuration: minutes * 60,
            meditationStartedAt: endedAt.addingTimeInterval(-minutes * 60),
            endedAt: endedAt,
            completedAutomatically: true,
            note: note
        )
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 7) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test("Month sections preserve arrival order and never re-sort")
    func sectionOrderPreserved() {
        let records = [
            record(endedAt: date(2026, 8, 27)),
            record(endedAt: date(2026, 8, 25)),
            record(endedAt: date(2026, 7, 31)),
            record(endedAt: date(2026, 7, 1))
        ]
        let sections = LogPresentation.monthSections(from: records, calendar: calendar)
        #expect(sections.map(\.id) == ["2026-08", "2026-07"])
        #expect(sections[0].records.map(\.endedAt) == [date(2026, 8, 27), date(2026, 8, 25)])
        #expect(sections[1].records.count == 2)
    }

    @Test("A month's total is the sum of its credited durations")
    func monthTotals() {
        let records = [
            record(endedAt: date(2026, 8, 27), minutes: 45),
            record(endedAt: date(2026, 8, 25), minutes: 60),
            record(endedAt: date(2026, 7, 1), minutes: 30)
        ]
        let sections = LogPresentation.monthSections(from: records, calendar: calendar)
        #expect(sections[0].totalDuration == 105 * 60)
        #expect(sections[1].totalDuration == 30 * 60)
    }

    @Test("Sittings credited under a minute stay out of the sections")
    func subMinuteFiltered() {
        let records = [
            record(endedAt: date(2026, 8, 27), minutes: 45),
            record(endedAt: date(2026, 8, 26), minutes: 0.5)
        ]
        let sections = LogPresentation.monthSections(from: records, calendar: calendar)
        #expect(sections.count == 1)
        #expect(sections[0].records.count == 1)
        #expect(sections[0].totalDuration == 45 * 60)
    }

    @Test("December and January land in distinct sections with distinct ids")
    func yearBoundary() {
        let records = [
            record(endedAt: date(2026, 1, 2)),
            record(endedAt: date(2025, 12, 30))
        ]
        let sections = LogPresentation.monthSections(from: records, calendar: calendar)
        #expect(sections.map(\.id) == ["2026-01", "2025-12"])
        #expect(sections[0].title != sections[1].title)
    }

    @Test("The grid's leading blanks honor the calendar's first weekday")
    func leadingBlanks() {
        // August 2026 begins on a Saturday. Monday-first: 5 blanks; Sunday-first: 6.
        let monthStart = date(2026, 8, 1, hour: 0)
        let mondayFirst = LogPresentation.monthGrid(for: monthStart, totals: [], calendar: calendar)
        #expect(mondayFirst.leadingBlanks == 5)
        #expect(mondayFirst.days.count == 31)

        var sundayCalendar = calendar
        sundayCalendar.firstWeekday = 1
        let sundayFirst = LogPresentation.monthGrid(for: monthStart, totals: [], calendar: sundayCalendar)
        #expect(sundayFirst.leadingBlanks == 6)
    }

    @Test("Practiced days line up with the daily totals, across a DST change")
    func practicedDays() {
        // 29 March 2026 is the spring DST transition in Europe/Berlin.
        let records = [
            record(endedAt: date(2026, 3, 29, hour: 6)),
            record(endedAt: date(2026, 3, 15))
        ]
        let totals = HistoryStore.dailyTotals(from: records, calendar: calendar)
        let grid = LogPresentation.monthGrid(
            for: date(2026, 3, 1, hour: 0),
            totals: totals,
            calendar: calendar
        )
        let practiced = grid.days.filter(\.practiced).map(\.dayNumber)
        #expect(practiced == [15, 29])
        #expect(grid.days.count == 31)
    }
}
