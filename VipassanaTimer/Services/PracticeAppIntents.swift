import AppIntents
import Foundation

extension Notification.Name {
    static let startMeditationIntent = Notification.Name("VipassanaTimer.startMeditationIntent")
}

struct StartMeditationIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Meditation"
    static var description = IntentDescription("Begin a quiet, gong-timed sitting.")
    static var openAppWhenRun = true

    @Parameter(title: "Minutes", default: 60)
    var minutes: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Start a \(\.$minutes)-minute meditation")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(
            name: .startMeditationIntent,
            object: nil,
            userInfo: ["minutes": min(240, max(1, minutes))]
        )
        return .result()
    }
}

struct PracticeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartMeditationIntent(),
            phrases: [
                "Start meditation with \(.applicationName)",
                "Sit with \(.applicationName)"
            ],
            shortTitle: "Start Meditation",
            systemImageName: "timer"
        )
    }
}
