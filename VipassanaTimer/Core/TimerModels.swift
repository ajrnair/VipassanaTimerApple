import Foundation

#if canImport(Darwin)
import Darwin
#endif

public enum SessionMode: String, Codable, Sendable {
    case standard
    case awareness
}

public enum SessionPhase: String, Codable, Sendable {
    case preparing
    case meditating
    case awareness
    case completed
}

public struct SessionClock: Equatable, Sendable {
    public var wallDate: Date
    public var uptime: TimeInterval
    public var bootTime: TimeInterval?

    public init(wallDate: Date, uptime: TimeInterval, bootTime: TimeInterval? = nil) {
        self.wallDate = wallDate
        self.uptime = uptime
        self.bootTime = bootTime
    }

    public static var live: SessionClock {
        SessionClock(
            wallDate: Date(),
            uptime: ProcessInfo.processInfo.systemUptime,
            bootTime: SystemBootIdentity.current
        )
    }
}

public enum SystemBootIdentity {
    public static var current: TimeInterval? {
        #if canImport(Darwin)
        var bootTime = timeval()
        var size = MemoryLayout<timeval>.size
        guard sysctlbyname("kern.boottime", &bootTime, &size, nil, 0) == 0 else {
            return nil
        }
        return TimeInterval(bootTime.tv_sec) + TimeInterval(bootTime.tv_usec) / 1_000_000
        #else
        return nil
        #endif
    }
}

public struct ActiveSession: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var mode: SessionMode
    public var createdAt: Date
    public var anchorUptime: TimeInterval
    public var anchorBootTime: TimeInterval?
    public var plannedDuration: TimeInterval
    public var preparationDuration: TimeInterval
    public var interval: TimeInterval?
    /// The materialized random gong schedule, present only for a random
    /// Awareness session. Optional and additive: state persisted before this
    /// field existed decodes to `nil` and follows the fixed-interval path, and
    /// a random session also carries `interval` (set to the minimum gap) so an
    /// older build restoring it degrades to a sane fixed schedule rather than
    /// silence. `PersistedSessionState.schemaVersion` stays at 1.
    public var gongOffsets: [TimeInterval]?
    public var handledEventIDs: Set<String>

    public init(
        id: UUID = UUID(),
        mode: SessionMode,
        createdAt: Date,
        anchorUptime: TimeInterval,
        anchorBootTime: TimeInterval? = nil,
        plannedDuration: TimeInterval,
        preparationDuration: TimeInterval,
        interval: TimeInterval? = nil,
        gongOffsets: [TimeInterval]? = nil,
        handledEventIDs: Set<String> = []
    ) {
        self.id = id
        self.mode = mode
        self.createdAt = createdAt
        self.anchorUptime = anchorUptime
        self.anchorBootTime = anchorBootTime
        self.plannedDuration = plannedDuration
        self.preparationDuration = preparationDuration
        self.interval = interval
        self.gongOffsets = gongOffsets
        self.handledEventIDs = handledEventIDs
    }

    public var totalTimelineDuration: TimeInterval {
        preparationDuration + plannedDuration
    }

    public var expectedEndDate: Date {
        createdAt.addingTimeInterval(totalTimelineDuration)
    }
}

public struct TimerSnapshot: Equatable, Sendable {
    public var phase: SessionPhase
    public var elapsedTimeline: TimeInterval
    public var remaining: TimeInterval
    public var progressRemaining: Double

    public init(
        phase: SessionPhase,
        elapsedTimeline: TimeInterval,
        remaining: TimeInterval,
        progressRemaining: Double
    ) {
        self.phase = phase
        self.elapsedTimeline = elapsedTimeline
        self.remaining = remaining
        self.progressRemaining = progressRemaining
    }
}

public enum TimerEvent: Hashable, Sendable {
    case meditationStarted
    case warning
    case awarenessInterval(index: Int)
    case completed

    public var identifier: String {
        switch self {
        case .meditationStarted:
            return "meditation-started"
        case .warning:
            return "warning"
        case let .awarenessInterval(index):
            return "awareness-interval-\(index)"
        case .completed:
            return "completed"
        }
    }
}

public struct TimedEvent: Equatable, Sendable {
    public var event: TimerEvent
    public var timelineOffset: TimeInterval

    public init(event: TimerEvent, timelineOffset: TimeInterval) {
        self.event = event
        self.timelineOffset = timelineOffset
    }
}

public struct CompletionPresentation: Codable, Equatable, Sendable {
    public var sessionID: UUID
    public var mode: SessionMode
    public var duration: TimeInterval
    public var completedAt: Date

    public init(sessionID: UUID, mode: SessionMode, duration: TimeInterval, completedAt: Date) {
        self.sessionID = sessionID
        self.mode = mode
        self.duration = duration
        self.completedAt = completedAt
    }
}

public struct PersistedSessionState: Codable, Equatable, Sendable {
    public var schemaVersion: Int
    public var activeSession: ActiveSession?
    public var completion: CompletionPresentation?

    public init(
        schemaVersion: Int = 1,
        activeSession: ActiveSession? = nil,
        completion: CompletionPresentation? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.activeSession = activeSession
        self.completion = completion
    }
}

public enum PracticeDeepLink: Equatable, Sendable {
    case sit(minutes: Int)
    case awareness(hours: Int, intervalMinutes: Int)
    /// The app draws the schedule; the link only says how long.
    case awarenessRandom(hours: Int)
}

public enum PracticeURLParser {
    public static func parse(_ url: URL) -> PracticeDeepLink? {
        guard url.scheme == "vipassanatimer" else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        // Read the first matching item directly. Unlike Dictionary(uniqueKeysWithValues:),
        // this remains deterministic and cannot trap on repeated external URL parameters.
        func value(named name: String, default fallback: String) -> String {
            items.first(where: { $0.name == name })?.value ?? fallback
        }

        switch url.host {
        case "sit":
            let minutes = min(240, max(1, Int(value(named: "minutes", default: "60")) ?? 60))
            return .sit(minutes: minutes)
        case "aware":
            guard PracticeFeatures.awarenessEnabled else { return nil }
            let hours = min(24, max(1, Int(value(named: "hours", default: "8")) ?? 8))
            if value(named: "gongs", default: "") == "random" {
                return .awarenessRandom(hours: hours)
            }
            let interval = max(1, Int(value(named: "interval", default: "10")) ?? 10)
            return .awareness(hours: hours, intervalMinutes: interval)
        default:
            return nil
        }
    }
}
