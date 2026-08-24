import Foundation

public struct AwarenessConfiguration: Equatable, Sendable {
    public var hours: Int
    public var intervalMinutes: Int

    public init(hours: Int, intervalMinutes: Int) {
        self.hours = hours
        self.intervalMinutes = intervalMinutes
    }

    public var totalMinutes: Int {
        hours * 60
    }

    public var totalSeconds: TimeInterval {
        TimeInterval(totalMinutes * 60)
    }

    public var intervalSeconds: TimeInterval {
        TimeInterval(intervalMinutes * 60)
    }
}
public enum AwarenessValidationError: Error, Equatable, Sendable {
    case hoursOutsideAllowedRange
    case intervalOutsideAllowedRange
    case tooManyScheduledGongs(minimumIntervalMinutes: Int)

    public var message: String {
        switch self {
        case .hoursOutsideAllowedRange:
            return "Choose a whole-number duration from 1 through 24 hours."
        case .intervalOutsideAllowedRange:
            return "Choose a whole-number gong interval from 1 through 1,440 minutes."
        case let .tooManyScheduledGongs(minimumIntervalMinutes):
            return "For this duration, use an interval of at least \(minimumIntervalMinutes) minutes so every gong can be scheduled reliably."
        }
    }
}

public enum AwarenessPolicy {
    public static let defaultHours = 8
    public static let defaultIntervalMinutes = 10
    public static let minimumHours = 1
    public static let maximumHours = 24
    public static let minimumIntervalMinutes = 1
    public static let maximumIntervalMinutes = 1_440
    public static let maximumPendingActions = 64
    public static let maximumIntermediateGongs = maximumPendingActions - 1

    /// - Parameter maximumActions: the platform's ceiling on pending scheduled
    ///   actions, or `nil` where there is none. Only notification-delivered gongs
    ///   are capped: the Watch schedules one local notification per gong and so
    ///   passes the default, while iPhone, iPad and Mac now sound every gong from
    ///   a live audio session and are bounded by nothing.
    public static func validate(
        hours: Int,
        intervalMinutes: Int,
        maximumActions: Int? = maximumPendingActions
    ) -> Result<AwarenessConfiguration, AwarenessValidationError> {
        guard (minimumHours...maximumHours).contains(hours) else {
            return .failure(.hoursOutsideAllowedRange)
        }

        guard (minimumIntervalMinutes...maximumIntervalMinutes).contains(intervalMinutes) else {
            return .failure(.intervalOutsideAllowedRange)
        }

        let configuration = AwarenessConfiguration(hours: hours, intervalMinutes: intervalMinutes)

        if let maximumActions {
            let count = intermediateGongCount(
                totalMinutes: configuration.totalMinutes,
                intervalMinutes: intervalMinutes
            )
            guard count <= maximumActions - 1 else {
                return .failure(
                    .tooManyScheduledGongs(
                        minimumIntervalMinutes: minimumReliableIntervalMinutes(hours: hours)
                    )
                )
            }
        }

        return .success(configuration)
    }

    public static func intermediateGongCount(totalMinutes: Int, intervalMinutes: Int) -> Int {
        guard totalMinutes > 0, intervalMinutes > 0, intervalMinutes < totalMinutes else {
            return 0
        }
        return (totalMinutes - 1) / intervalMinutes
    }

    public static func scheduledActionCount(totalMinutes: Int, intervalMinutes: Int) -> Int {
        intermediateGongCount(totalMinutes: totalMinutes, intervalMinutes: intervalMinutes) + 1
    }

    public static func minimumReliableIntervalMinutes(hours: Int) -> Int {
        let boundedHours = max(minimumHours, min(maximumHours, hours))
        let totalMinutes = boundedHours * 60
        return (totalMinutes + maximumPendingActions - 1) / maximumPendingActions
    }
}
