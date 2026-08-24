import SwiftUI
import WatchKit

/// Ring and mark sizes are a share of the physical display.
///
/// `containerRelativeFrame(.horizontal)` resolves against the nearest container,
/// which inside these stacks is narrower than the screen — a ring asked for 56%
/// of the width came out closer to a third of it, and squeezed its caption down
/// to "REMAI…" on the 40 mm. Measuring the display directly removes the
/// ambiguity, and is exact on every watch.
enum WatchMetrics {
    static var displayWidth: CGFloat {
        WKInterfaceDevice.current().screenBounds.width
    }

    static func ring(_ fraction: CGFloat) -> CGFloat {
        displayWidth * fraction
    }
}

enum WatchPalette {
    static let background = Color("VTBackground")
    static let surface = Color("VTSurface")
    static let selected = Color("VTSelected")
    static let text = Color("VTText")
    static let muted = Color("VTMuted")
    static let border = Color("VTBorder")
    static let accent = Color("AccentColor")
    static let patina = Color("VTPatina")
    static let buttonText = Color("VTButtonText")
}

extension Font {
    /// Ganzfeld sets its serif light on every platform. Weight is part of the
    /// language, not decoration.
    static func vtWatchSerif(_ size: CGFloat, weight: Weight = .light) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// How brightly the aperture burns, as on iPhone — the aperture is the clock,
/// growing from the preparation seconds to full bloom at completion.
///
/// The values run lower than the phone's because the ground here is true black
/// rather than a violet field, so the same light reads considerably stronger;
/// and because this burns on an always-on display, where a dimmer field is the
/// kinder choice for both the eye and the battery.
enum WatchAperture {
    case idle
    case preparing
    case sitting
    case complete
    case log

    var peak: Double {
        switch self {
        case .idle: 0.16
        case .preparing: 0.06
        case .sitting: 0.13
        case .complete: 0.20
        case .log: 0.10
        }
    }

    /// Diameter as a multiple of the screen's shorter edge.
    var scale: CGFloat {
        switch self {
        case .idle: 1.25
        case .preparing: 1.05
        case .sitting: 1.45
        case .complete: 1.75
        case .log: 1.30
        }
    }

    var center: UnitPoint {
        switch self {
        case .idle: UnitPoint(x: 0.5, y: 0.46)
        case .preparing: UnitPoint(x: 0.5, y: 0.47)
        case .sitting: UnitPoint(x: 0.5, y: 0.47)
        case .complete: UnitPoint(x: 0.5, y: 0.42)
        case .log: UnitPoint(x: 0.5, y: 0.88)
        }
    }
}

/// The field, adapted for the Watch: black ground, and the aperture is the only
/// light in it.
///
/// The phone paints a five-stop violet gradient, a vignette and a grain tile.
/// None of those belong here. An Apple Watch screen sits behind a black bezel,
/// and anything short of true black at the edges reads as a lit rectangle
/// floating inside it; a vignette has nothing left to darken once the ground is
/// black; and grain is invisible at this size while costing pixels on a display
/// that never fully sleeps. What remains is the violet — carried in the
/// aperture's outer halo, where it belongs to the light rather than the
/// background.
struct WatchGanzfeldField: View {
    var aperture: WatchAperture = .idle

    var body: some View {
        GeometryReader { proxy in
            let edge = min(proxy.size.width, proxy.size.height)

            ZStack {
                WatchPalette.background

                RadialGradient(
                    stops: [
                        .init(color: Color("VTAperture").opacity(aperture.peak), location: 0.0),
                        .init(color: Color("VTApertureMid").opacity(aperture.peak * 0.53), location: 0.32),
                        .init(color: Color("VTApertureOuter").opacity(aperture.peak * 0.2), location: 0.56),
                        .init(color: .clear, location: 0.72)
                    ],
                    center: aperture.center,
                    startRadius: 0,
                    endRadius: edge * aperture.scale / 2
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Small tracked capitals, in the quiet ink rather than the accent: on this
/// language the accent is reserved for light, not for labels.
struct WatchEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .regular))
            .tracking(2)
            .foregroundStyle(WatchPalette.patina)
    }
}

/// Ganzfeld forbids filled surfaces on the phone, and on the watch that rule is
/// what made the app read as a shrunken web page: hairline rules and thin ink
/// are a reading idiom, and a watch is not read, it is glanced at and hit with a
/// thumb. So the watch keeps Ganzfeld's field, aperture, palette and serif
/// numerals, and takes its *structure* from watchOS — full-bleed rounded rows
/// with a real fill, and one filled action per screen.
struct WatchRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(WatchPalette.text)
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(WatchPalette.surface.opacity(configuration.isPressed ? 0.55 : 0.92))
            )
            .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

/// The action a screen exists for. Filled, because on a watch the primary
/// control should be unmistakable at arm's length and under a thumb.
struct WatchProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(WatchPalette.buttonText)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(
                Capsule().fill(WatchPalette.accent.opacity(configuration.isPressed ? 0.72 : 1))
            )
            .contentShape(Capsule())
    }
}

/// A secondary action: still a shape, not a hairline.
/// A hairline at rest, so it reads as the quieter of two actions next to a
/// filled primary button; it fills in on press, so the tap itself is what
/// confirms the control caught it — the same feedback a filled button gives,
/// arriving only when it is needed rather than sitting there permanently.
struct WatchOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(WatchPalette.text)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                Capsule().fill(WatchPalette.surface.opacity(configuration.isPressed ? 1 : 0))
            )
            .overlay(
                Capsule().stroke(WatchPalette.border, lineWidth: 1)
            )
            .contentShape(Capsule())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// The aperture as a component: a hairline circle with the numeral inside, and
/// the warm arc carrying progress when there is progress to carry.
struct WatchApertureRing: View {
    var progress: Double = 0
    let timeText: String
    var caption: String?
    /// A share of the ring's diameter rather than a point size, for the same
    /// reason the ring is a share of the display: a numeral fixed against one
    /// watch is cramped on the smallest and lost on the largest. Longer readouts
    /// take a smaller share - "07:59:12" needs far less of the circle per glyph
    /// than "6" does.
    var numeralFraction: CGFloat = 0.30

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let bounded = min(1, max(0, progress))

            ZStack {
                Circle().stroke(WatchPalette.border, lineWidth: 1)

                if bounded > 0 {
                    Circle()
                        .trim(from: 0, to: bounded)
                        .stroke(
                            WatchPalette.accent,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                VStack(spacing: 4) {
                    Text(timeText)
                        .font(.vtWatchSerif(side * numeralFraction))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(WatchPalette.text)
                        .contentTransition(.numericText())
                    if let caption {
                        Text(caption.uppercased())
                            .font(.system(size: 8))
                            .tracking(1.6)
                            .foregroundStyle(WatchPalette.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .padding(.horizontal, 8)
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption ?? "")
        .accessibilityValue(timeText)
    }
}
