import Foundation

public struct MeditationRecord: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var plannedDuration: TimeInterval
    public var creditedDuration: TimeInterval
    public var meditationStartedAt: Date
    public var endedAt: Date
    public var completedAutomatically: Bool
    public var note: String?
    public var modifiedAt: Date?
    public var healthKitSavedAt: Date?

    public init(
        id: UUID,
        plannedDuration: TimeInterval,
        creditedDuration: TimeInterval,
        meditationStartedAt: Date,
        endedAt: Date,
        completedAutomatically: Bool,
        note: String? = nil,
        modifiedAt: Date? = nil,
        healthKitSavedAt: Date? = nil
    ) {
        self.id = id
        self.plannedDuration = plannedDuration
        self.creditedDuration = creditedDuration
        self.meditationStartedAt = meditationStartedAt
        self.endedAt = endedAt
        self.completedAutomatically = completedAutomatically
        self.note = note
        self.modifiedAt = modifiedAt
        self.healthKitSavedAt = healthKitSavedAt
    }

    /// Applies a log-editor result without rewriting session provenance: the planned
    /// duration and automatic-completion flag always survive, and timing fields change
    /// only when the user actually edited the end time or the credited minutes.
    public func applyingEdit(endedAt: Date, minutes: Int, note: String?) -> MeditationRecord {
        var edited = self
        edited.note = note
        let editorMinutes = max(1, Int(creditedDuration / 60))
        guard endedAt != self.endedAt || minutes != editorMinutes else { return edited }
        let duration = TimeInterval(minutes * 60)
        edited.creditedDuration = duration
        edited.meditationStartedAt = endedAt.addingTimeInterval(-duration)
        edited.endedAt = endedAt
        return edited
    }
}

public struct DailyTotal: Equatable, Identifiable, Sendable {
    public var date: Date
    public var totalDuration: TimeInterval
    public var sessionCount: Int

    public init(date: Date, totalDuration: TimeInterval, sessionCount: Int) {
        self.date = date
        self.totalDuration = totalDuration
        self.sessionCount = sessionCount
    }

    public var id: Date { date }
}

public struct HistoryLoadResult: Equatable, Sendable {
    public var records: [MeditationRecord]
    public var hadUnreadableEntries: Bool

    public init(records: [MeditationRecord], hadUnreadableEntries: Bool) {
        self.records = records
        self.hadUnreadableEntries = hadUnreadableEntries
    }
}

public struct HistoryTombstone: Codable, Equatable, Sendable {
    public var id: UUID
    public var deletedAt: Date

    public init(id: UUID, deletedAt: Date) {
        self.id = id
        self.deletedAt = deletedAt
    }
}

public struct HistorySyncSnapshot: Codable, Equatable, Sendable {
    public var records: [MeditationRecord]
    public var tombstones: [HistoryTombstone]

    public init(records: [MeditationRecord], tombstones: [HistoryTombstone]) {
        self.records = records
        self.tombstones = tombstones
    }
}

public final class HistoryStore: @unchecked Sendable {
    private let recordsDirectory: URL
    private let tombstonesURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSRecursiveLock()

    public init(baseDirectory: URL? = nil) {
        let root = baseDirectory ?? Self.defaultApplicationSupportDirectory()
        recordsDirectory = root.appendingPathComponent("History", isDirectory: true)
        tombstonesURL = root.appendingPathComponent("history-tombstones.json")
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    @discardableResult
    public func add(_ record: MeditationRecord) throws -> Bool {
        try synchronized {
            try FileManager.default.createDirectory(
                at: recordsDirectory,
                withIntermediateDirectories: true
            )
            let destination = recordsDirectory.appendingPathComponent("\(record.id.uuidString).json")
            guard !FileManager.default.fileExists(atPath: destination.path) else { return false }
            try encoder.encode(record).write(to: destination, options: .atomic)
            return true
        }
    }

    public func update(_ record: MeditationRecord) throws {
        try synchronized {
            try FileManager.default.createDirectory(
                at: recordsDirectory,
                withIntermediateDirectories: true
            )
            let destination = recordsDirectory.appendingPathComponent("\(record.id.uuidString).json")
            try encoder.encode(record).write(to: destination, options: .atomic)
        }
    }

    @discardableResult
    public func markHealthKitSaved(id: UUID, at date: Date) throws -> Bool {
        try synchronized {
            let destination = recordsDirectory.appendingPathComponent("\(id.uuidString).json")
            guard FileManager.default.fileExists(atPath: destination.path) else { return false }

            var current = try decoder.decode(MeditationRecord.self, from: Data(contentsOf: destination))
            current.healthKitSavedAt = date
            current.modifiedAt = max(current.modifiedAt ?? .distantPast, date)
            try encoder.encode(current).write(to: destination, options: .atomic)
            return true
        }
    }

    public func delete(id: UUID, at date: Date = Date()) throws {
        try synchronized {
            let destination = recordsDirectory.appendingPathComponent("\(id.uuidString).json")
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            var tombstones = loadTombstones()
            if let index = tombstones.firstIndex(where: { $0.id == id }) {
                tombstones[index].deletedAt = max(tombstones[index].deletedAt, date)
            } else {
                tombstones.append(HistoryTombstone(id: id, deletedAt: date))
            }
            try saveTombstones(tombstones)
        }
    }

    public func syncSnapshot() -> HistorySyncSnapshot {
        synchronized {
            HistorySyncSnapshot(records: load().records, tombstones: loadTombstones())
        }
    }

    @discardableResult
    public func merge(_ incoming: HistorySyncSnapshot) throws -> Bool {
        try synchronized {
            var didChange = false
            var recordsByID = Dictionary(uniqueKeysWithValues: load().records.map { ($0.id, $0) })
            var tombstonesByID = Dictionary(uniqueKeysWithValues: loadTombstones().map { ($0.id, $0) })

            for tombstone in incoming.tombstones {
                if tombstone.deletedAt > (tombstonesByID[tombstone.id]?.deletedAt ?? .distantPast) {
                    tombstonesByID[tombstone.id] = tombstone
                    didChange = true
                }
            }

            for record in incoming.records {
                let incomingRevision = record.modifiedAt ?? record.endedAt
                if let tombstone = tombstonesByID[record.id], tombstone.deletedAt >= incomingRevision {
                    continue
                }
                let localRevision = recordsByID[record.id].map { $0.modifiedAt ?? $0.endedAt } ?? .distantPast
                if incomingRevision > localRevision {
                    recordsByID[record.id] = record
                    didChange = true
                }
            }

            var deletedIDs: [UUID] = []
            for (id, record) in recordsByID {
                let revision = record.modifiedAt ?? record.endedAt
                if let tombstone = tombstonesByID[id], tombstone.deletedAt >= revision {
                    deletedIDs.append(id)
                    let destination = recordsDirectory.appendingPathComponent("\(id.uuidString).json")
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    didChange = true
                }
            }
            deletedIDs.forEach { recordsByID[$0] = nil }

            for record in recordsByID.values {
                try update(record)
            }
            try saveTombstones(Array(tombstonesByID.values))
            return didChange
        }
    }

    public func load() -> HistoryLoadResult {
        synchronized {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: recordsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else {
                return HistoryLoadResult(records: [], hadUnreadableEntries: false)
            }

            var records: [MeditationRecord] = []
            var hadUnreadableEntries = false
            for file in files where file.pathExtension == "json" {
                do {
                    let record = try decoder.decode(MeditationRecord.self, from: Data(contentsOf: file))
                    records.append(record)
                } catch {
                    hadUnreadableEntries = true
                }
            }
            return HistoryLoadResult(
                records: records.sorted { $0.endedAt > $1.endedAt },
                hadUnreadableEntries: hadUnreadableEntries
            )
        }
    }

    public static func dailyTotals(
        from records: [MeditationRecord],
        calendar: Calendar = .autoupdatingCurrent
    ) -> [DailyTotal] {
        let groups = Dictionary(grouping: records) { calendar.startOfDay(for: $0.endedAt) }
        return groups.map { date, records in
            DailyTotal(
                date: date,
                totalDuration: records.reduce(0) { $0 + $1.creditedDuration },
                sessionCount: records.count
            )
        }
        .sorted { $0.date > $1.date }
    }

    private static func defaultApplicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("VipassanaTimer", isDirectory: true)
    }

    private func loadTombstones() -> [HistoryTombstone] {
        guard let data = try? Data(contentsOf: tombstonesURL),
              let tombstones = try? decoder.decode([HistoryTombstone].self, from: data) else {
            return []
        }
        return tombstones
    }

    private func saveTombstones(_ tombstones: [HistoryTombstone]) throws {
        try FileManager.default.createDirectory(
            at: tombstonesURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoder.encode(tombstones).write(to: tombstonesURL, options: .atomic)
    }

    private func synchronized<T>(_ operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }
}

public final class SessionStore {
    private let stateURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(baseDirectory: URL? = nil) {
        let root = baseDirectory ?? Self.defaultApplicationSupportDirectory()
        stateURL = root.appendingPathComponent("session-state.json")
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    public func load() throws -> PersistedSessionState {
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            return PersistedSessionState()
        }
        return try decoder.decode(PersistedSessionState.self, from: Data(contentsOf: stateURL))
    }

    public func save(_ state: PersistedSessionState) throws {
        try FileManager.default.createDirectory(
            at: stateURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try encoder.encode(state).write(to: stateURL, options: .atomic)
    }

    private static func defaultApplicationSupportDirectory() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("VipassanaTimer", isDirectory: true)
    }
}
