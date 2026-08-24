import Foundation

final class SleepAssertionController {
    #if os(macOS)
    private var activity: NSObjectProtocol?
    #endif

    func begin() {
        #if os(macOS)
        guard activity == nil else { return }
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.idleSystemSleepDisabled, .userInitiated],
            reason: "An active Vipassana timer must continue while its window is closed."
        )
        #endif
    }

    func end() {
        #if os(macOS)
        guard let activity else { return }
        ProcessInfo.processInfo.endActivity(activity)
        self.activity = nil
        #endif
    }

    deinit {
        end()
    }
}
