import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Timer engine")
struct TimerEngineTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Standard meditation begins after the eight-second preparation")
    func standardTransition() {
        let session = TimerEngine.startStandard(
            minutes: 60,
            clock: SessionClock(wallDate: start, uptime: 100)
        )

        #expect(
            TimerEngine.snapshot(
                for: session,
                at: SessionClock(wallDate: start.addingTimeInterval(7), uptime: 107)
            ).phase == .preparing
        )
        #expect(
            TimerEngine.snapshot(
                for: session,
                at: SessionClock(wallDate: start.addingTimeInterval(8), uptime: 108)
            ).phase == .meditating
        )
    }

    @Test("The warning exists only above 30 minutes")
    func warningBoundary() {
        let thirty = TimerEngine.startStandard(
            minutes: 30,
            clock: SessionClock(wallDate: start, uptime: 100)
        )
        let fortyFive = TimerEngine.startStandard(
            minutes: 45,
            clock: SessionClock(wallDate: start, uptime: 100)
        )

        #expect(!TimerEngine.timelineEvents(for: thirty).contains { $0.event == .warning })
        #expect(TimerEngine.timelineEvents(for: fortyFive).contains { $0.event == .warning })
    }

    @Test("Ending preparation credits zero")
    func preparationCredit() {
        let session = TimerEngine.startStandard(
            minutes: 60,
            clock: SessionClock(wallDate: start, uptime: 100)
        )
        let credited = TimerEngine.creditedDuration(
            for: session,
            at: SessionClock(wallDate: start.addingTimeInterval(5), uptime: 105)
        )
        #expect(credited == 0)
    }

    @Test("Manual ending credits only elapsed meditation time")
    func manualEndCredit() {
        let session = TimerEngine.startStandard(
            minutes: 60,
            clock: SessionClock(wallDate: start, uptime: 100)
        )
        let credited = TimerEngine.creditedDuration(
            for: session,
            at: SessionClock(wallDate: start.addingTimeInterval(128), uptime: 228)
        )
        #expect(credited == 120)
    }

    @Test("System uptime prevents a wall-clock jump from extending the session")
    func wallClockJump() {
        let session = TimerEngine.startStandard(
            minutes: 15,
            clock: SessionClock(wallDate: start, uptime: 100)
        )
        let snapshot = TimerEngine.snapshot(
            for: session,
            at: SessionClock(wallDate: start.addingTimeInterval(-3_600), uptime: 168)
        )
        #expect(snapshot.phase == .meditating)
        #expect(snapshot.remaining == 840)
    }

    @Test("Awareness has no interval gong at its final boundary")
    func awarenessFinalBoundary() throws {
        let configuration = try AwarenessPolicy.validate(hours: 8, intervalMinutes: 10).get()
        let session = TimerEngine.startAwareness(
            configuration: configuration,
            clock: SessionClock(wallDate: start, uptime: 100)
        )
        let events = TimerEngine.timelineEvents(for: session)
        let intervalCount = events.filter { event in
            if case .awarenessInterval = event.event { return true }
            return false
        }.count
        #expect(intervalCount == 47)
        #expect(events.last?.event == .completed)
        #expect(events.last!.timelineOffset == 28_800.0)
    }

    @Test("Repeated shortcut parameters are handled without trapping")
    func repeatedShortcutParameters() throws {
        let url = try #require(URL(string: "vipassanatimer://sit?minutes=30&minutes=60"))
        #expect(PracticeURLParser.parse(url) == .sit(minutes: 30))
    }

    /// Awareness is out of scope for 1.0. The deep link must not start a practice the app has no
    /// interface for, and its bounding must still hold the moment the flag is turned back on.
    @Test("An awareness shortcut is refused while Awareness is out of scope, and bounded when not")
    func boundedAwarenessShortcut() throws {
        let url = try #require(URL(string: "vipassanatimer://aware?hours=99&interval=0"))
        if PracticeFeatures.awarenessEnabled {
            #expect(PracticeURLParser.parse(url) == .awareness(hours: 24, intervalMinutes: 1))
        } else {
            #expect(PracticeURLParser.parse(url) == nil)
        }
    }

    @Test("A sitting shortcut still works while Awareness is out of scope")
    func sittingShortcutUnaffected() throws {
        let url = try #require(URL(string: "vipassanatimer://sit?minutes=45"))
        #expect(PracticeURLParser.parse(url) == .sit(minutes: 45))
    }
}
