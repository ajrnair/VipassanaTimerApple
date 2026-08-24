import Foundation

public enum TimerEngine {
    public static let preparationDuration: TimeInterval = 8
    public static let warningOffset: TimeInterval = 5 * 60
    public static let warningMinimumSessionDuration: TimeInterval = 30 * 60

    public static func startStandard(minutes: Int, clock: SessionClock) -> ActiveSession {
        ActiveSession(
            mode: .standard,
            createdAt: clock.wallDate,
            anchorUptime: clock.uptime,
            anchorBootTime: clock.bootTime,
            plannedDuration: TimeInterval(minutes * 60),
            preparationDuration: preparationDuration
        )
    }

    public static func startAwareness(
        configuration: AwarenessConfiguration,
        clock: SessionClock
    ) -> ActiveSession {
        ActiveSession(
            mode: .awareness,
            createdAt: clock.wallDate,
            anchorUptime: clock.uptime,
            anchorBootTime: clock.bootTime,
            plannedDuration: configuration.totalSeconds,
            preparationDuration: 0,
            interval: configuration.intervalSeconds
        )
    }

    public static func elapsed(for session: ActiveSession, at clock: SessionClock) -> TimeInterval {
        let bootIdentityMatches: Bool
        switch (session.anchorBootTime, clock.bootTime) {
        case let (.some(anchor), .some(current)):
            bootIdentityMatches = abs(anchor - current) < 0.001
        case (.none, .none):
            bootIdentityMatches = true
        default:
            bootIdentityMatches = false
        }

        if bootIdentityMatches, clock.uptime >= session.anchorUptime {
            return max(0, clock.uptime - session.anchorUptime)
        }
        return max(0, clock.wallDate.timeIntervalSince(session.createdAt))
    }

    public static func snapshot(for session: ActiveSession, at clock: SessionClock) -> TimerSnapshot {
        let elapsedTimeline = elapsed(for: session, at: clock)

        switch session.mode {
        case .standard:
            if elapsedTimeline < session.preparationDuration {
                let remaining = session.preparationDuration - elapsedTimeline
                return TimerSnapshot(
                    phase: .preparing,
                    elapsedTimeline: elapsedTimeline,
                    remaining: remaining,
                    progressRemaining: min(1, max(0, remaining / session.preparationDuration))
                )
            }

            let meditationElapsed = elapsedTimeline - session.preparationDuration
            let remaining = max(0, session.plannedDuration - meditationElapsed)
            let phase: SessionPhase = remaining > 0 ? .meditating : .completed
            return TimerSnapshot(
                phase: phase,
                elapsedTimeline: elapsedTimeline,
                remaining: remaining,
                progressRemaining: session.plannedDuration > 0 ? remaining / session.plannedDuration : 0
            )

        case .awareness:
            let remaining = max(0, session.plannedDuration - elapsedTimeline)
            return TimerSnapshot(
                phase: remaining > 0 ? .awareness : .completed,
                elapsedTimeline: elapsedTimeline,
                remaining: remaining,
                progressRemaining: session.plannedDuration > 0 ? remaining / session.plannedDuration : 0
            )
        }
    }

    public static func timelineEvents(for session: ActiveSession) -> [TimedEvent] {
        switch session.mode {
        case .standard:
            var events = [
                TimedEvent(event: .meditationStarted, timelineOffset: session.preparationDuration)
            ]
            if session.plannedDuration > warningMinimumSessionDuration {
                events.append(
                    TimedEvent(
                        event: .warning,
                        timelineOffset: session.preparationDuration + session.plannedDuration - warningOffset
                    )
                )
            }
            events.append(
                TimedEvent(event: .completed, timelineOffset: session.totalTimelineDuration)
            )
            return events.sorted { $0.timelineOffset < $1.timelineOffset }

        case .awareness:
            guard let interval = session.interval, interval > 0 else {
                return [TimedEvent(event: .completed, timelineOffset: session.plannedDuration)]
            }

            var events: [TimedEvent] = []
            var index = 1
            var offset = interval
            while offset < session.plannedDuration {
                events.append(
                    TimedEvent(event: .awarenessInterval(index: index), timelineOffset: offset)
                )
                index += 1
                offset = interval * Double(index)
            }
            events.append(TimedEvent(event: .completed, timelineOffset: session.plannedDuration))
            return events
        }
    }

    public static func eventsCrossed(
        for session: ActiveSession,
        from previousElapsed: TimeInterval,
        through currentElapsed: TimeInterval
    ) -> [TimerEvent] {
        guard currentElapsed >= previousElapsed else { return [] }
        return timelineEvents(for: session)
            .filter { $0.timelineOffset > previousElapsed && $0.timelineOffset <= currentElapsed }
            .map(\.event)
    }

    public static func creditedDuration(for session: ActiveSession, at clock: SessionClock) -> TimeInterval {
        guard session.mode == .standard else { return 0 }
        let meditationElapsed = elapsed(for: session, at: clock) - session.preparationDuration
        return min(session.plannedDuration, max(0, meditationElapsed))
    }
}

public enum DurationFormatter {
    public static func meditationCountdown(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(ceil(seconds)))
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    public static func awarenessCountdown(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(ceil(seconds)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let remainingSeconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    public static func concise(_ seconds: TimeInterval) -> String {
        let clampedSeconds = max(0, seconds)
        if clampedSeconds > 0, clampedSeconds < 60 { return "<1m" }
        let totalMinutes = Int(clampedSeconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0, minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }
}
