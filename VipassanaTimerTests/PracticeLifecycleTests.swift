import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import VipassanaCore
#endif

@Suite("Practice lifecycle")
struct PracticeLifecycleTests {
    private let clock = SessionClock(
        wallDate: Date(timeIntervalSince1970: 1_700_000_000),
        uptime: 100
    )

    @Test("Only one re-entrant start request can enter the starting state")
    func reentrantStartIsRejected() {
        var lifecycle = PracticeLifecycle()
        let firstToken = UUID()

        #expect(lifecycle.requestStart(token: firstToken) == firstToken)
        #expect(lifecycle.requestStart(token: UUID()) == nil)
        #expect(lifecycle.state == .starting(firstToken))
    }

    @Test("A late start callback cannot replace a newer lifecycle state")
    func staleStartCallbackIsIgnored() {
        var lifecycle = PracticeLifecycle()
        let acceptedToken = lifecycle.requestStart()!
        let staleToken = UUID()
        let session = TimerEngine.startStandard(minutes: 30, clock: clock)

        let staleAccepted = lifecycle.startSucceeded(token: staleToken, session: session)
        #expect(!staleAccepted)
        #expect(lifecycle.state == .starting(acceptedToken))
        let currentAccepted = lifecycle.startSucceeded(token: acceptedToken, session: session)
        #expect(currentAccepted)
        #expect(lifecycle.state == .active(session))
    }

    @Test("Cancellation blocks a second start until notification cleanup finishes")
    func cancellationIsAnExplicitState() {
        let session = TimerEngine.startStandard(minutes: 30, clock: clock)
        var lifecycle = PracticeLifecycle(state: .active(session))

        #expect(lifecycle.requestCancellation() == session)
        #expect(lifecycle.state == .cancelling(session.id))
        #expect(lifecycle.requestStart() == nil)
        let cancellationFinished = lifecycle.cancellationFinished(sessionID: session.id)
        #expect(cancellationFinished)
        #expect(lifecycle.state == .idle)
    }

    @Test("Automatic completion uses the scheduled boundary, not a late callback time")
    func completionUsesExpectedEndDate() {
        let session = TimerEngine.startStandard(minutes: 30, clock: clock)
        var lifecycle = PracticeLifecycle(state: .active(session))

        let completion = lifecycle.complete(session: session)

        #expect(completion?.completedAt == session.expectedEndDate)
        #expect(lifecycle.state == .completed(completion!))
    }
}
