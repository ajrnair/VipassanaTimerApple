import SwiftUI

/// A short phone has roughly two hundred points less than the screens this design was drawn
/// against: an iPhone SE is 667 points tall, a mini 812, where a 17 Pro is 874 and a Pro Max 956.
///
/// Rather than let a screen overflow — which put the Begin button under the tab bar on an SE —
/// every element gives a little instead of one element giving everything:
///
/// - The ring shrinks most. It is the largest thing on the screen and has the most to spare.
/// - The display title steps down one size, and no further.
/// - The subtitle steps down too, but stays. It says what the gongs will do, which is the one
///   thing a first-time user cannot work out by looking.
/// - The spacing between them tightens.
///
/// Nothing is removed. A small phone shows the same screen, drawn closer.
private struct CompactHeightKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isCompactHeight: Bool {
        get { self[CompactHeightKey.self] }
        set { self[CompactHeightKey.self] = newValue }
    }
}

enum VTLayout {
    /// Compared against the height a screen actually gets, not the height of the device: the
    /// measurement comes from inside the safe area, so a 874-point phone reports about 781 and
    /// a 667-point SE about 647. A mini lands near 728 and needs the compact layout; the 17 Pro
    /// does not. Hence a line between them.
    static let compactHeightThreshold: CGFloat = 750

    /// The ring is 208 where there is room, and gives up to about a quarter of that where there
    /// is not — enough to bring the Sit screen back inside a 667-point phone.
    static func ringSize(compact: Bool) -> CGFloat { compact ? 156 : 208 }

    static func displayTitleStyle(compact: Bool) -> Font.TextStyle { compact ? .title : .largeTitle }

    static func subtitleStyle(compact: Bool) -> Font.TextStyle { compact ? .subheadline : .body }
}
