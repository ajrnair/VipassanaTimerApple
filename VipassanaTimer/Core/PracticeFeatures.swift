import Foundation

/// Release scope for the shipping build.
///
/// The first App Store release (2.0.0) ships the silent sitting timer only. Awareness is finished and still fully tested
/// — `AwarenessPolicy`, the `TimerEngine` interval logic, and their tests are untouched and keep
/// running in CI — but it is held out of the first release for three reasons:
///
/// 1. Its Watch screen needs the redraw rework (system-ticked `Text(timerInterval:)` rather than
///    an app-driven ticker).
/// 2. Its battery cost over a multi-hour session is unmeasured on both platforms.
/// 3. A practice that can hold an audio session open for up to 24 hours is the weakest point of
///    an App Store review under Guideline 2.5.4, and there is no notification fallback left.
///
/// A 2-hour sitting is a straightforward story to defend; a 24-hour near-silent keepalive is not.
/// Restoring Awareness in a later release is flipping this one flag back to `true`.
public enum PracticeFeatures {
    public static let awarenessEnabled = false
}
