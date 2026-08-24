import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Persistence")
struct PersistenceTests {
    @Test("History insertion is idempotent")
    func idempotentHistory() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = HistoryStore(baseDirectory: temporaryDirectory)
        let record = makeRecord(id: UUID(), endedAt: Date(timeIntervalSince1970: 1_700_000_000))

        #expect(try store.add(record))
        #expect(try !store.add(record))
        #expect(store.load().records == [record])
    }

    @Test("History records can be edited and deleted")
    func editableHistory() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = HistoryStore(baseDirectory: temporaryDirectory)
        var record = makeRecord(id: UUID(), endedAt: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(try store.add(record))

        record.creditedDuration = 2_700
        record.note = "Interrupted once, then settled."
        record.modifiedAt = Date(timeIntervalSince1970: 1_700_000_100)
        try store.update(record)
        #expect(store.load().records == [record])

        try store.delete(id: record.id)
        #expect(store.load().records.isEmpty)
    }

    @Test("Health export metadata preserves newer edits and never resurrects deletions")
    func healthExportMetadataIsAtomic() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = HistoryStore(baseDirectory: temporaryDirectory)
        var record = makeRecord(id: UUID(), endedAt: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(try store.add(record))

        record.note = "A note added while Health was saving."
        record.modifiedAt = record.endedAt.addingTimeInterval(30)
        try store.update(record)
        let savedAt = record.endedAt.addingTimeInterval(60)
        #expect(try store.markHealthKitSaved(id: record.id, at: savedAt))
        #expect(store.load().records.first?.note == record.note)
        #expect(store.load().records.first?.healthKitSavedAt == savedAt)

        try store.delete(id: record.id, at: savedAt.addingTimeInterval(1))
        #expect(try !store.markHealthKitSaved(id: record.id, at: savedAt.addingTimeInterval(2)))
        #expect(store.load().records.isEmpty)
    }

    @Test("Records written before notes existed still load")
    func legacyRecordWithoutNoteLoads() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let historyDirectory = temporaryDirectory.appendingPathComponent("History", isDirectory: true)
        try FileManager.default.createDirectory(at: historyDirectory, withIntermediateDirectories: true)

        let id = UUID()
        let endedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let legacyRecord = LegacyMeditationRecord(
            id: id,
            plannedDuration: 1_800,
            creditedDuration: 1_800,
            meditationStartedAt: endedAt.addingTimeInterval(-1_800),
            endedAt: endedAt,
            completedAutomatically: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(legacyRecord).write(
            to: historyDirectory.appendingPathComponent("\(id.uuidString).json")
        )

        let loaded = HistoryStore(baseDirectory: temporaryDirectory).load()
        #expect(!loaded.hadUnreadableEntries)
        #expect(loaded.records.count == 1)
        #expect(loaded.records.first?.note == nil)
    }

    @Test("A synced deletion wins over an older record and does not resurrect")
    func deletionTombstoneWinsDuringMerge() throws {
        let phoneDirectory = try makeTemporaryDirectory()
        let watchDirectory = try makeTemporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: phoneDirectory)
            try? FileManager.default.removeItem(at: watchDirectory)
        }
        let phone = HistoryStore(baseDirectory: phoneDirectory)
        let watch = HistoryStore(baseDirectory: watchDirectory)
        let record = makeRecord(id: UUID(), endedAt: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(try phone.add(record))
        #expect(try watch.add(record))

        try phone.delete(id: record.id, at: record.endedAt.addingTimeInterval(60))
        #expect(try watch.merge(phone.syncSnapshot()))
        #expect(watch.load().records.isEmpty)

        #expect(try !phone.merge(watch.syncSnapshot()))
        #expect(phone.load().records.isEmpty)
    }

    @Test("A corrupt record does not hide independently valid records")
    func partialCorruption() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = HistoryStore(baseDirectory: temporaryDirectory)
        let record = makeRecord(id: UUID(), endedAt: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(try store.add(record))

        let corruptURL = temporaryDirectory
            .appendingPathComponent("History", isDirectory: true)
            .appendingPathComponent("corrupt.json")
        try Data("not-json".utf8).write(to: corruptURL)

        let result = store.load()
        #expect(result.records == [record])
        #expect(result.hadUnreadableEntries)
    }

    @Test("Concurrent history writes remain readable")
    func concurrentHistoryWrites() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = HistoryStore(baseDirectory: temporaryDirectory)
        let endedAt = Date(timeIntervalSince1970: 1_700_000_000)

        DispatchQueue.concurrentPerform(iterations: 100) { index in
            _ = try? store.add(
                makeRecord(
                    id: UUID(),
                    endedAt: endedAt.addingTimeInterval(TimeInterval(index))
                )
            )
        }

        let loaded = store.load()
        #expect(!loaded.hadUnreadableEntries)
        #expect(loaded.records.count == 100)
    }

    @Test("Daily totals group records by local end date")
    func dailyTotals() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let firstDate = Date(timeIntervalSince1970: 1_700_000_000)
        let laterSameDay = firstDate.addingTimeInterval(3_600)
        let nextDay = firstDate.addingTimeInterval(86_400)

        let totals = HistoryStore.dailyTotals(
            from: [
                makeRecord(id: UUID(), endedAt: firstDate, credited: 1_800),
                makeRecord(id: UUID(), endedAt: laterSameDay, credited: 2_700),
                makeRecord(id: UUID(), endedAt: nextDay, credited: 900)
            ],
            calendar: calendar
        )

        #expect(totals.count == 2)
        #expect(totals[0].totalDuration == 900)
        #expect(totals[1].totalDuration == 4_500)
        #expect(totals[1].sessionCount == 2)
    }

    @Test("Active state round-trips")
    func sessionStateRoundTrip() throws {
        let temporaryDirectory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }
        let store = SessionStore(baseDirectory: temporaryDirectory)
        let clock = SessionClock(wallDate: Date(timeIntervalSince1970: 1_700_000_000), uptime: 50)
        let session = TimerEngine.startStandard(minutes: 45, clock: clock)
        let state = PersistedSessionState(activeSession: session)

        try store.save(state)
        #expect(try store.load() == state)
    }

    private func makeTemporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test("A note-only edit preserves session provenance")
    func noteOnlyEditPreservesProvenance() {
        let record = MeditationRecord(
            id: UUID(),
            plannedDuration: 3_600,
            creditedDuration: 2_520,
            meditationStartedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_002_520),
            completedAutomatically: true
        )

        let edited = record.applyingEdit(endedAt: record.endedAt, minutes: 42, note: "quiet")

        #expect(edited.note == "quiet")
        #expect(edited.plannedDuration == record.plannedDuration)
        #expect(edited.creditedDuration == record.creditedDuration)
        #expect(edited.meditationStartedAt == record.meditationStartedAt)
        #expect(edited.endedAt == record.endedAt)
        #expect(edited.completedAutomatically)
    }

    @Test("A duration edit changes credit but keeps the plan and completion")
    func durationEditKeepsProvenance() {
        let record = MeditationRecord(
            id: UUID(),
            plannedDuration: 3_600,
            creditedDuration: 2_520,
            meditationStartedAt: Date(timeIntervalSince1970: 1_700_000_000),
            endedAt: Date(timeIntervalSince1970: 1_700_002_520),
            completedAutomatically: true
        )

        let edited = record.applyingEdit(endedAt: record.endedAt, minutes: 45, note: nil)

        #expect(edited.creditedDuration == 2_700)
        #expect(edited.meditationStartedAt == record.endedAt.addingTimeInterval(-2_700))
        #expect(edited.plannedDuration == record.plannedDuration)
        #expect(edited.completedAutomatically)
    }

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
}

private struct LegacyMeditationRecord: Codable {
    var id: UUID
    var plannedDuration: TimeInterval
    var creditedDuration: TimeInterval
    var meditationStartedAt: Date
    var endedAt: Date
    var completedAutomatically: Bool
}
