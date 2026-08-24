import Foundation

public enum GuidanceMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case silent
    case guided

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .silent: "Silent"
        case .guided: "Guided"
        }
    }
}

public enum GuidedProgramCatalog {
    public static let supportedMinutes = [15, 30, 45, 60]

    public static func supports(minutes: Int) -> Bool {
        supportedMinutes.contains(minutes)
    }

    public static func fileName(minutes: Int) -> String? {
        guard supports(minutes: minutes) else { return nil }
        return "guide-program-guided-\(minutes)-v2-en"
    }
}
