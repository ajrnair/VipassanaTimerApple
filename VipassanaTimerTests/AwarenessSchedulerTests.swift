import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

/// A tiny deterministic generator so schedule tests are reproducible.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

@Suite("Awareness scheduler")
struct AwarenessSchedulerTests {
    @Test("The gap range follows the session length")
    func boundsFollowLength() {
        let oneHour = AwarenessScheduler.randomBounds(totalSeconds: 3_600)
        #expect(oneHour.minimum == 5 * 60)
        #expect(oneHour.maximum == 10 * 60)

        let fourHours = AwarenessScheduler.randomBounds(totalSeconds: 4 * 3_600)
        #expect(fourHours.minimum == 10 * 60)
        #expect(fourHours.maximum == 20 * 60)

        let eightHours = AwarenessScheduler.randomBounds(totalSeconds: 8 * 3_600)
        #expect(eightHours.minimum == 20 * 60)
        #expect(eightHours.maximum == 40 * 60)

        let day = AwarenessScheduler.randomBounds(totalSeconds: 24 * 3_600)
        #expect(day.minimum == 20 * 60)
        #expect(day.maximum == 40 * 60)
    }

    @Test("Offsets are strictly increasing, inside the bounds, and end before the session")
    func offsetsWellFormed() {
        let total: TimeInterval = 8 * 3_600
        var rng = SplitMix64(seed: 42)
        let offsets = AwarenessScheduler.gongOffsets(totalSeconds: total, using: &rng)
        let bounds = AwarenessScheduler.randomBounds(totalSeconds: total)

        #expect(!offsets.isEmpty)
        #expect(offsets == offsets.sorted())
        #expect(offsets.allSatisfy { $0 < total })

        var previous: TimeInterval = 0
        for offset in offsets {
            let gap = offset - previous
            #expect(gap >= bounds.minimum)
            #expect(gap <= bounds.maximum)
            previous = offset
        }
    }

    @Test("The same seed draws the same schedule")
    func deterministicUnderSeed() {
        var first = SplitMix64(seed: 7)
        var second = SplitMix64(seed: 7)
        let a = AwarenessScheduler.gongOffsets(totalSeconds: 6 * 3_600, using: &first)
        let b = AwarenessScheduler.gongOffsets(totalSeconds: 6 * 3_600, using: &second)
        #expect(a == b)
    }

    @Test("A random session replays its exact schedule through the timeline")
    func timelineFromOffsets() {
        var rng = SplitMix64(seed: 11)
        let session = TimerEngine.startAwarenessRandom(
            hours: 8,
            clock: SessionClock(wallDate: Date(timeIntervalSince1970: 1_000), uptime: 100, bootTime: 50),
            using: &rng
        )
        let events = TimerEngine.timelineEvents(for: session)
        let offsets = session.gongOffsets ?? []

        #expect(events.count == offsets.count + 1)
        for (index, offset) in offsets.enumerated() {
            #expect(events[index].event == .awarenessInterval(index: index + 1))
            #expect(events[index].timelineOffset == offset)
        }
        #expect(events.last?.event == .completed)
        #expect(events.last?.timelineOffset == session.plannedDuration)
    }

    @Test("A persisted random session decodes to the identical timeline")
    func codableRoundTripPreservesSchedule() throws {
        var rng = SplitMix64(seed: 3)
        let session = TimerEngine.startAwarenessRandom(
            hours: 12,
            clock: SessionClock(wallDate: Date(timeIntervalSince1970: 2_000), uptime: 5, bootTime: 1),
            using: &rng
        )
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(ActiveSession.self, from: data)

        #expect(decoded.gongOffsets == session.gongOffsets)
        #expect(TimerEngine.timelineEvents(for: decoded) == TimerEngine.timelineEvents(for: session))
    }

    @Test("State persisted before the field existed takes the fixed path")
    func legacyStateDecodesToFixed() throws {
        // An awareness session as builds through 2.0.0 (28) wrote it: no gongOffsets key.
        let legacy = """
        {"id":"11111111-2222-3333-4444-555555555555","mode":"awareness",
         "createdAt":0,"anchorUptime":10,"plannedDuration":28800,
         "preparationDuration":0,"interval":600,"handledEventIDs":[]}
        """
        let decoder = JSONDecoder()
        let session = try decoder.decode(ActiveSession.self, from: Data(legacy.utf8))

        #expect(session.gongOffsets == nil)
        let events = TimerEngine.timelineEvents(for: session)
        #expect(events.count == 48)
        #expect(events.first?.timelineOffset == 600)
    }

    @Test("A random session keeps a fixed-interval fallback for older readers")
    func downgradeFallback() {
        var rng = SplitMix64(seed: 9)
        let session = TimerEngine.startAwarenessRandom(
            hours: 8,
            clock: SessionClock(wallDate: Date(), uptime: 0, bootTime: nil),
            using: &rng
        )
        let bounds = AwarenessScheduler.randomBounds(totalSeconds: session.plannedDuration)
        #expect(session.interval == bounds.minimum)
    }

    @Test("The aware deep link accepts random gongs, when the practice is enabled")
    func deepLinkParsing() throws {
        let url = try #require(URL(string: "vipassanatimer://aware?hours=6&gongs=random"))
        let parsed = PracticeURLParser.parse(url)
        if PracticeFeatures.awarenessEnabled {
            #expect(parsed == .awarenessRandom(hours: 6))
        } else {
            #expect(parsed == nil)
        }

        let fixed = try #require(URL(string: "vipassanatimer://aware?hours=6&interval=15"))
        if PracticeFeatures.awarenessEnabled {
            #expect(PracticeURLParser.parse(fixed) == .awareness(hours: 6, intervalMinutes: 15))
        }
    }
}
