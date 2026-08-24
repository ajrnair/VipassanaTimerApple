#if os(iOS)
import UIKit
#endif

/// Feedback fired at the gesture rather than declared on a view.
///
/// `.sensoryFeedback` is the tidier spelling, but it delivers through the view that declares it,
/// which makes it unreliable here: the press-and-hold to end removes its own button in the same
/// turn it fires, and a modifier attached to a departing view has nothing left to deliver
/// through. Calling the generator at the call site has no such dependency.
///
/// The generator is prepared before use. Without that the Taptic Engine may still be idle and
/// the first tap of a session — the one that tells you the app is responsive — is the one most
/// likely to be dropped.
enum Haptics {
    /// A choice registered: a length, or the mode.
    static func selection() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    /// A held gesture reaching the point where it takes.
    static func committed() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}
