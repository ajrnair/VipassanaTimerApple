import SwiftUI

/// The aperture: a hairline circle standing in for the gong, with the countdown
/// inside it. When it carries progress the arc is the one warm mark on the screen.
struct MeditationRing: View {
    var progress: Double
    var timeText: String
    var stateText: String
    /// The boards size the numeral per screen — 78 on Sit and Awareness, 72 in
    /// preparation, 62 while sitting — and the ring is drawn to frame it. At one
    /// shared text style the numeral floats small inside a 208-point circle.
    var numeralSize: CGFloat = 78
    /// Set where the ring is the control rather than a readout: a knob rides the
    /// end of the arc so it is clear the ring can be turned, and where the finger
    /// currently sits.
    var showsHandle: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var typeScale: CGFloat = 1

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let boundedProgress = min(1, max(0, progress))

            ZStack {
                Circle()
                    .stroke(VTPalette.border, lineWidth: 1)

                Circle()
                    .trim(from: 0, to: boundedProgress)
                    .stroke(VTPalette.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                if showsHandle {
                    let angle = Angle.degrees(boundedProgress * 360 - 90)
                    Circle()
                        .fill(VTPalette.accent)
                        .frame(width: 13, height: 13)
                        .offset(
                            x: cos(angle.radians) * (side / 2 - 1),
                            y: sin(angle.radians) * (side / 2 - 1)
                        )
                }

                VStack(spacing: 10) {
                    Text(timeText)
                        .font(.system(size: numeralSize * typeScale, weight: .light, design: .serif))
                        .monospacedDigit()
                        .foregroundStyle(VTPalette.text)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text(stateText.uppercased())
                        .font(.caption2)
                        .tracking(2.4)
                        .foregroundStyle(VTPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: side * 0.78)
            }
            .frame(width: side, height: side)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stateText)
        .accessibilityValue(timeText)
    }
}

/// Awareness uses the same aperture, without progress: awareness has no end to
/// count down to in the way a sitting does.
struct AwarenessOrbit: View {
    var timeText: String
    var caption: String

    var body: some View {
        ZStack {
            Circle().stroke(VTPalette.border, lineWidth: 1)

            VStack(spacing: 10) {
                Text(timeText)
                    .font(.vtSerif(.title))
                    .monospacedDigit()
                    .foregroundStyle(VTPalette.text)
                    .contentTransition(.numericText())
                Text(caption.uppercased())
                    .font(.caption2)
                    .tracking(2.4)
                    .foregroundStyle(VTPalette.muted)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue(timeText)
    }
}

/// The completion mark: concentric hairlines around a single warm point, at the
/// centre of the bloom.
struct CompletionMark: View {
    var size: CGFloat = 210

    var body: some View {
        ZStack {
            Circle().stroke(VTPalette.border, lineWidth: 1)
            Circle().stroke(VTPalette.border.opacity(0.45), lineWidth: 1)
                .padding(40)
            Circle()
                .fill(VTPalette.accent)
                .frame(width: 13, height: 13)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// How brightly the aperture burns. The aperture is the clock: it grows across a
/// sitting so a glance reads progress without a numeral, and the session ends in
/// light — the same thing the three closing gongs do in sound.
///
/// The second rule is that the aperture is brightest where there is least content.
/// `log` is the dimmest and sits low, because a list needs an even field to read
/// against; the session screens carry almost no type, so they can bloom.
enum ApertureIntensity {
    case idle        // Sit and Awareness: something to choose, so a moderate field
    case preparing   // the eight quiet seconds; the light has not arrived
    case sitting     // mid-session
    case complete    // full bloom
    case log         // a dense list: recede

    /// Peak alpha of the aperture's innermost stop. Every value here was measured
    /// against the gradient's real falloff so that white/ink text, hairlines and
    /// the accent all clear WCAG AA at the brightest point of the field.
    var peak: Double {
        switch self {
        case .idle: 0.22
        case .preparing: 0.08
        case .sitting: 0.18
        case .complete: 0.28
        case .log: 0.14
        }
    }

    /// Diameter as a fraction of the view's *shorter* edge. The design boards
    /// specify absolute diameters — 420, 480, 560, 680 and 520 points on a
    /// 390-point-wide phone — so the short edge is what these reproduce. Taking
    /// the longer edge instead doubles every aperture, and a glow wider than the
    /// screen stops reading as an aperture at all.
    var scale: CGFloat {
        switch self {
        case .idle: 480.0 / 390.0
        case .preparing: 420.0 / 390.0
        case .sitting: 560.0 / 390.0
        case .complete: 680.0 / 390.0
        case .log: 520.0 / 390.0
        }
    }

    /// Vertical placement. The completion bloom sits on the mark rather than the
    /// copy, and the log's drops below its last row.
    var center: UnitPoint {
        switch self {
        case .idle: UnitPoint(x: 0.5, y: 0.45)
        case .preparing: UnitPoint(x: 0.5, y: 0.46)
        case .sitting: UnitPoint(x: 0.5, y: 0.47)
        case .complete: UnitPoint(x: 0.5, y: 0.33)
        case .log: UnitPoint(x: 0.5, y: 0.86)
        }
    }
}

/// The Ganzfeld field: graded light with a warm aperture, after James Turrell.
///
/// Four layers, in paint order. The gradient gives the tonal range; the aperture
/// is the light source; the vignette darkens only the surround, which makes the
/// aperture read as luminous *and* improves text contrast at the edges rather
/// than degrading it; the grain breaks up the banding a dark gradient shows on
/// OLED at low brightness. A phone is dimmer than a desk display, and without the
/// last two layers the field flattens into a single wash there.
struct GanzfeldField: View {
    var intensity: ApertureIntensity = .idle

    var body: some View {
        GeometryReader { proxy in
            let edge = min(proxy.size.width, proxy.size.height)
            let diameter = edge * intensity.scale

            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color("VTField1"), location: 0.0),
                        .init(color: Color("VTField2"), location: 0.30),
                        .init(color: Color("VTField3"), location: 0.52),
                        .init(color: Color("VTField4"), location: 0.74),
                        .init(color: Color("VTField5"), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    stops: [
                        .init(color: Color("VTAperture").opacity(intensity.peak), location: 0.0),
                        .init(color: Color("VTApertureMid").opacity(intensity.peak * 0.53), location: 0.32),
                        .init(color: Color("VTApertureOuter").opacity(intensity.peak * 0.2), location: 0.56),
                        .init(color: .clear, location: 0.72)
                    ],
                    center: intensity.center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )

                // Elliptical, not circular: the boards darken the left and right
                // edges as much as the corners, and a circle sized to the frame
                // reaches the sides so early that they stay untouched — which is
                // what flattens the field and costs the aperture its luminosity.
                EllipticalGradient(
                    stops: [
                        .init(color: .clear, location: 0.26),
                        .init(color: Color("VTVignetteMid"), location: 0.66),
                        .init(color: Color("VTVignetteEdge"), location: 1.0)
                    ],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.71
                )

                Image("VTGrain")
                    .resizable(resizingMode: .tile)
                    .blendMode(.overlay)
                    .opacity(0.11)
                    .allowsHitTesting(false)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the practice field behind a screen. Screens never paint their own
    /// opaque background; the field is continuous beneath every one of them.
    func ganzfeldField(_ intensity: ApertureIntensity) -> some View {
        background(GanzfeldField(intensity: intensity))
    }
}
