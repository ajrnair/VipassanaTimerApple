import Foundation

public enum PracticeLifecycleState: Equatable, Sendable {
    case idle
    case starting(UUID)
    case active(ActiveSession)
    case cancelling(UUID)
    case completed(CompletionPresentation)

    public var activeSession: ActiveSession? {
        guard case let .active(session) = self else { return nil }
        return session
    }

    public var completion: CompletionPresentation? {
        guard case let .completed(completion) = self else { return nil }
        return completion
    }

    public var isTransitioning: Bool {
        switch self {
        case .starting, .cancelling:
            return true
        case .idle, .active, .completed:
            return false
        }
    }

    public var blocksStarting: Bool {
        self != .idle
    }
}

public struct PracticeLifecycle: Equatable, Sendable {
    public private(set) var state: PracticeLifecycleState

    public init(state: PracticeLifecycleState = .idle) {
        self.state = state
    }

    @discardableResult
    public mutating func requestStart(token: UUID = UUID()) -> UUID? {
        guard state == .idle else { return nil }
        state = .starting(token)
        return token
    }

    @discardableResult
    public mutating func startSucceeded(token: UUID, session: ActiveSession) -> Bool {
        guard state == .starting(token) else { return false }
        state = .active(session)
        return true
    }

    @discardableResult
    public mutating func startFailed(token: UUID) -> Bool {
        guard state == .starting(token) else { return false }
        state = .idle
        return true
    }

    public mutating func requestCancellation() -> ActiveSession? {
        guard case let .active(session) = state else { return nil }
        state = .cancelling(session.id)
        return session
    }

    @discardableResult
    public mutating func cancellationFinished(sessionID: UUID) -> Bool {
        guard state == .cancelling(sessionID) else { return false }
        state = .idle
        return true
    }

    @discardableResult
    public mutating func complete(session: ActiveSession) -> CompletionPresentation? {
        guard state == .active(session) else { return nil }
        let presentation = CompletionPresentation(
            sessionID: session.id,
            mode: session.mode,
            duration: session.plannedDuration,
            completedAt: session.expectedEndDate
        )
        state = .completed(presentation)
        return presentation
    }

    public mutating func clearCompletion() -> UUID? {
        guard case let .completed(completion) = state else { return nil }
        state = .idle
        return completion.sessionID
    }

    public mutating func restore(
        activeSession: ActiveSession?,
        completion: CompletionPresentation?
    ) {
        if let activeSession {
            state = .active(activeSession)
        } else if let completion {
            state = .completed(completion)
        } else {
            state = .idle
        }
    }
}
