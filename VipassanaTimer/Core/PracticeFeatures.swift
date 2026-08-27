import Foundation

/// Release scope for the shipping build.
///
/// The first App Store release (2.0.0) ships the silent sitting timer only. Awareness is finished and still fully tested
/// — `AwarenessPolicy`, `AwarenessScheduler`, the `TimerEngine` interval logic, and their tests
/// are untouched and keep running in CI — but it is held out of the first release for three
/// reasons:
///
/// 1. Its Watch screen needs the redraw rework (system-ticked `Text(timerInterval:)` rather than
///    an app-driven ticker).
/// 2. Its battery cost over a multi-hour session is unmeasured on both platforms. The measurement
///    procedure is written and waiting in `docs/awareness-battery-measurement.md`.
/// 3. A practice that can hold an audio session open for up to 24 hours is the weakest point of
///    an App Store review under Guideline 2.5.4, and there is no notification fallback left.
///
/// A 2-hour sitting is a straightforward story to defend; a 24-hour near-silent keepalive is not.
///
/// ## Flag-flip checklist
///
/// Flipping this flag to `true` restores the screens, the tab, and the deep link — but three
/// pieces were *removed* rather than gated (`AppShortcutsBuilder` takes no runtime conditionals),
/// and must come back by hand in the same release. The originals were removed in the archive
/// repository's commit `259b160`; restore them as:
///
/// 1. **`StartAwarenessIntent`** in `Services/PracticeAppIntents.swift`, updated for the gong
///    modes (fixed interval, or random where the app draws the schedule):
///
///        extension Notification.Name {
///            static let startAwarenessIntent = Notification.Name("VipassanaTimer.startAwarenessIntent")
///        }
///
///        struct StartAwarenessIntent: AppIntent {
///            static var title: LocalizedStringResource = "Start Awareness"
///            static var description = IntentDescription("Begin periodic awareness reminders for up to 24 hours.")
///            static var openAppWhenRun = true
///
///            @Parameter(title: "Hours", default: 8)
///            var hours: Int
///
///            @Parameter(title: "Gong interval in minutes (0 lets the app choose at random)", default: 10)
///            var intervalMinutes: Int
///
///            static var parameterSummary: some ParameterSummary {
///                Summary("Start \(\.$hours) hours of awareness with a gong every \(\.$intervalMinutes) minutes")
///            }
///
///            @MainActor
///            func perform() async throws -> some IntentResult {
///                NotificationCenter.default.post(
///                    name: .startAwarenessIntent,
///                    object: nil,
///                    userInfo: [
///                        "hours": min(24, max(1, hours)),
///                        "intervalMinutes": min(1_440, max(0, intervalMinutes))
///                    ]
///                )
///                return .result()
///            }
///        }
///
///    plus its observer in `AppModel.observeAppIntents()` routing `intervalMinutes == 0` to
///    `startAwarenessRandom(hours:)`.
///
/// 2. **The App Shortcut** entry in the same file's `AppShortcutsProvider`:
///
///        AppShortcut(
///            intent: StartAwarenessIntent(),
///            phrases: ["Start awareness with \(.applicationName)"],
///            shortTitle: "Start Awareness",
///            systemImageName: "bell"
///        )
///
/// 3. **The widget quick link** in `VipassanaTimerWidgets/VipassanaTimerWidgets.swift`:
///
///        practiceLink("Awareness", subtitle: "8 hours · every 10 min", icon: "bell",
///                     url: "vipassanatimer://aware?hours=8&interval=10")
///
///    and restore the widget description to "Begin a sitting or Awareness practice."
///
/// Beyond code: run the battery procedure above and record its results; add an Awareness
/// screenshot to the store set; add the Awareness line back to the listing copy; and rerun the
/// physical audio matrix with an 8-hour random session included.
public enum PracticeFeatures {
    public static let awarenessEnabled = false
}
