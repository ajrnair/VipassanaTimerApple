import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Awareness policy")
struct AwarenessPolicyTests {
    @Test("The default schedule has 47 intermediate gongs")
    func defaultSchedule() throws {
        let configuration = try AwarenessPolicy.validate(hours: 8, intervalMinutes: 10).get()
        #expect(
            AwarenessPolicy.intermediateGongCount(
                totalMinutes: configuration.totalMinutes,
                intervalMinutes: configuration.intervalMinutes
            ) == 47
        )
        #expect(
            AwarenessPolicy.scheduledActionCount(
                totalMinutes: configuration.totalMinutes,
                intervalMinutes: configuration.intervalMinutes
            ) == 48
        )
    }

    @Test("Twenty-four hours requires at least a 23-minute interval")
    func twentyFourHourBoundary() throws {
        #expect(AwarenessPolicy.minimumReliableIntervalMinutes(hours: 24) == 23)
        #expect(
            AwarenessPolicy.validate(hours: 24, intervalMinutes: 22)
                == .failure(.tooManyScheduledGongs(minimumIntervalMinutes: 23))
        )
        _ = try AwarenessPolicy.validate(hours: 24, intervalMinutes: 23).get()
    }

    @Test("Duration is limited to 24 hours")
    func durationBoundary() throws {
        #expect(
            AwarenessPolicy.validate(hours: 25, intervalMinutes: 30)
                == .failure(.hoursOutsideAllowedRange)
        )
        _ = try AwarenessPolicy.validate(hours: 1, intervalMinutes: 1).get()
    }

    @Test("An interval at or beyond the total has no intermediate gong")
    func intervalAtEnd() {
        #expect(AwarenessPolicy.intermediateGongCount(totalMinutes: 60, intervalMinutes: 60) == 0)
        #expect(AwarenessPolicy.intermediateGongCount(totalMinutes: 60, intervalMinutes: 90) == 0)
    }
}
