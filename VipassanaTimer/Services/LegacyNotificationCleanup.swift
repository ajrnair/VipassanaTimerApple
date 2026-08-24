import UserNotifications

/// Builds before 2.0.0 delivered every gong as a local notification. Gongs are ordinary app audio
/// now — see `PracticeGongPlayer` — and nothing in the app schedules a notification or asks for
/// notification permission, so any pending or delivered notification belongs to an older build.
///
/// Clearing them once at launch is the whole job. Removing requests needs no authorization, so
/// this never prompts. This exists only so an upgrading user does not receive a gong from a
/// session that ended before they updated; it can be deleted a release after 2.0.0 ships.
enum LegacyNotificationCleanup {
    static func removeAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
