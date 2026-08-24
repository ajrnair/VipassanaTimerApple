import Darwin
import Foundation
import VipassanaCore

private struct CheckRunner {
    var failureCount = 0

    mutating func check(_ condition: Bool, _ message: String) {
        if condition {
            print("PASS  \(message)")
        } else {
            failureCount += 1
            print("FAIL  \(message)")
        }
    }
}

private var runner = CheckRunner()

private func makeRecord(
    id: UUID,
    endedAt: Date,
    credited: TimeInterval = 1_800
) -> MeditationRecord {
    MeditationRecord(
        id: id,
        plannedDuration: 1_800,
        creditedDuration: credited,
        meditationStartedAt: endedAt.addingTimeInterval(-credited),
        endedAt: endedAt,
        completedAutomatically: credited == 1_800
    )
}

let start = Date(timeIntervalSince1970: 1_700_000_000)

do {
    let configuration = try AwarenessPolicy.validate(hours: 8, intervalMinutes: 10).get()
    runner.check(
        AwarenessPolicy.intermediateGongCount(
            totalMinutes: configuration.totalMinutes,
            intervalMinutes: configuration.intervalMinutes
        ) == 47,
        "8h / 10m schedules 47 intermediate gongs"
    )
    runner.check(
        AwarenessPolicy.scheduledActionCount(
            totalMinutes: configuration.totalMinutes,
            intervalMinutes: configuration.intervalMinutes
        ) == 48,
        "default awareness uses 48 pending actions including completion"
    )
} catch {
    runner.check(false, "default awareness configuration validates")
}

runner.check(
    AwarenessPolicy.minimumReliableIntervalMinutes(hours: 24) == 23,
    "24 hours requires a minimum 23-minute interval"
)
runner.check(
    AwarenessPolicy.validate(hours: 24, intervalMinutes: 22)
        == .failure(.tooManyScheduledGongs(minimumIntervalMinutes: 23)),
    "an excessive 24-hour schedule is rejected with an adjustment"
)
runner.check(
    AwarenessPolicy.validate(hours: 25, intervalMinutes: 30)
        == .failure(.hoursOutsideAllowedRange),
    "awareness rejects durations above 24 hours"
)

let standard = TimerEngine.startStandard(
    minutes: 60,
    clock: SessionClock(wallDate: start, uptime: 100)
)
runner.check(
    TimerEngine.snapshot(
        for: standard,
        at: SessionClock(wallDate: start.addingTimeInterval(7), uptime: 107)
    ).phase == .preparing,
    "standard session remains in preparation before 8 seconds"
)
runner.check(
    TimerEngine.snapshot(
        for: standard,
        at: SessionClock(wallDate: start.addingTimeInterval(8), uptime: 108)
    ).phase == .meditating,
    "standard meditation begins at 8 seconds"
)
runner.check(
    TimerEngine.creditedDuration(
        for: standard,
        at: SessionClock(wallDate: start.addingTimeInterval(5), uptime: 105)
    ) == 0,
    "ending during preparation credits zero"
)
runner.check(
    TimerEngine.creditedDuration(
        for: standard,
        at: SessionClock(wallDate: start.addingTimeInterval(128), uptime: 228)
    ) == 120,
    "manual ending credits elapsed meditation only"
)

let thirty = TimerEngine.startStandard(
    minutes: 30,
    clock: SessionClock(wallDate: start, uptime: 100)
)
runner.check(
    !TimerEngine.timelineEvents(for: thirty).contains { $0.event == .warning },
    "30-minute sessions omit the five-minute warning"
)
runner.check(
    TimerEngine.timelineEvents(for: standard).contains { $0.event == .warning },
    "sessions longer than 30 minutes include the warning"
)

let jumpedClockSnapshot = TimerEngine.snapshot(
    for: TimerEngine.startStandard(
        minutes: 15,
        clock: SessionClock(wallDate: start, uptime: 100)
    ),
    at: SessionClock(wallDate: start.addingTimeInterval(-3_600), uptime: 168)
)
runner.check(
    jumpedClockSnapshot.phase == .meditating && jumpedClockSnapshot.remaining == 840,
    "uptime protects an active session from a wall-clock jump"
)

let previousBootSession = TimerEngine.startStandard(
    minutes: 15,
    clock: SessionClock(wallDate: start, uptime: 100, bootTime: 1_600_000_000)
)
let rebootedSnapshot = TimerEngine.snapshot(
    for: previousBootSession,
    at: SessionClock(
        wallDate: start.addingTimeInterval(608),
        uptime: 200,
        bootTime: 1_700_000_000
    )
)
runner.check(
    rebootedSnapshot.phase == .meditating && rebootedSnapshot.remaining == 300,
    "a changed boot identity falls back to persisted wall time"
)

let temporaryDirectory = FileManager.default.temporaryDirectory
    .appendingPathComponent("VipassanaCoreChecks-\(UUID().uuidString)", isDirectory: true)
defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

do {
    try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    let historyStore = HistoryStore(baseDirectory: temporaryDirectory)
    let record = makeRecord(id: UUID(), endedAt: start)
    let firstInsertion = try historyStore.add(record)
    let duplicateInsertion = try historyStore.add(record)
    runner.check(firstInsertion, "first history insertion succeeds")
    runner.check(!duplicateInsertion, "duplicate history insertion is ignored")

    let corruptURL = temporaryDirectory
        .appendingPathComponent("History", isDirectory: true)
        .appendingPathComponent("corrupt.json")
    try Data("not-json".utf8).write(to: corruptURL)
    let loadResult = historyStore.load()
    runner.check(loadResult.records == [record], "valid history survives an unrelated corrupt entry")
    runner.check(loadResult.hadUnreadableEntries, "partial history corruption is disclosed")

    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let dailyTotals = HistoryStore.dailyTotals(
        from: [
            makeRecord(id: UUID(), endedAt: start, credited: 1_800),
            makeRecord(id: UUID(), endedAt: start.addingTimeInterval(3_600), credited: 2_700),
            makeRecord(id: UUID(), endedAt: start.addingTimeInterval(86_400), credited: 900)
        ],
        calendar: calendar
    )
    runner.check(
        dailyTotals.count == 2
            && dailyTotals[0].totalDuration == 900
            && dailyTotals[1].totalDuration == 4_500,
        "history groups credited time into newest-first daily totals"
    )

    let sessionStore = SessionStore(baseDirectory: temporaryDirectory)
    let state = PersistedSessionState(activeSession: standard)
    try sessionStore.save(state)
    let restoredState = try sessionStore.load()
    runner.check(restoredState == state, "active session state round-trips")
} catch {
    runner.check(false, "persistence checks complete: \(error.localizedDescription)")
}

if runner.failureCount == 0 {
    print("\nAll Vipassana core checks passed.")
    exit(EXIT_SUCCESS)
} else {
    print("\n\(runner.failureCount) Vipassana core check(s) failed.")
    exit(EXIT_FAILURE)
}
