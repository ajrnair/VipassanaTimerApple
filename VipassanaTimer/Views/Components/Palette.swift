import SwiftUI

/// Which field the practice sits in.
///
/// Night and Dawn are not two designs; they are one language at two times of day.
/// Every structural rule — hairlines instead of borders, no cards, no fills, the
/// aperture as the only light — is identical in both. Only the field inverts, and
/// the ink follows it.
///
/// That is why the whole skin lives in `Shared/BrandColors.xcassets` rather than
/// in Swift: each semantic token already carries a light and a dark value, so
/// Dawn *is* the light appearance and Night *is* the dark one. Following the
/// system needs no code at all, and an explicit choice is one
/// `.preferredColorScheme` at the root.
enum VTAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case dawn
    case night

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Automatic"
        case .dawn: "Dawn"
        case .night: "Night"
        }
    }

    var caption: String {
        switch self {
        case .system: "Follows the system between light and dark."
        case .dawn: "Daylight. The field is pale and the ink is dark."
        case .night: "Dusk. The field is deep and the light comes from the aperture."
        }
    }

    /// `nil` hands the decision back to the system, which is the default.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .dawn: .light
        case .night: .dark
        }
    }
}

enum VTPalette {
    static let background = Color("VTBackground")
    static let surface = Color("VTSurface")
    static let text = Color("VTText")
    static let muted = Color("VTMuted")
    static let border = Color("VTBorder")
    static let accent = Color("AccentColor")
    static let patina = Color("VTPatina")
    static let navigation = Color("VTNavigation")
    static let selected = Color("VTSelected")
}

extension Font {
    /// Ganzfeld sets its serif light. Weight is part of the language, not decoration:
    /// a thin face floats in the field where a regular one sits on top of it.
    static func vtSerif(_ style: Font.TextStyle) -> Font {
        .system(style, design: .serif, weight: .light)
    }
}

/// The primary action is an outline, not a fill. Nothing in this language is
/// filled except the aperture itself.
struct VTPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(VTPalette.text.opacity(configuration.isPressed ? 0.7 : 1))
            .padding(.horizontal, 40)
            .frame(minHeight: 52)
            .overlay(Capsule().stroke(VTPalette.border, lineWidth: 1))
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

struct VTSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundStyle(VTPalette.muted.opacity(configuration.isPressed ? 0.65 : 1))
            .padding(.horizontal, 26)
            .frame(minHeight: 48)
            .overlay(Capsule().stroke(VTPalette.border.opacity(0.7), lineWidth: 1))
            .contentShape(Capsule())
    }
}

/// A choice made by underlining it, rather than by filling a pill.
/// The board's switch: a hairline capsule with a warm knob, so the one control
/// that would otherwise arrive as a filled iOS surface stays in the language.
struct VTSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                configuration.label
                    .font(.body)
                    .foregroundStyle(VTPalette.text)
                Spacer(minLength: 12)
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule().stroke(VTPalette.border, lineWidth: 1)
                    Circle()
                        .fill(configuration.isOn ? VTPalette.accent : VTPalette.patina.opacity(0.4))
                        .frame(width: 23, height: 23)
                        .padding(.horizontal, 3)
                }
                .frame(width: 51, height: 31)
                .animation(.easeInOut(duration: 0.18), value: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(configuration.isOn ? [.isButton, .isSelected] : .isButton)
    }
}

struct VTUnderlinedChoice: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .frame(minWidth: 44, minHeight: 44)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isSelected ? VTPalette.text : .clear)
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? VTPalette.text : VTPalette.patina)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Ending is the one destructive act during a sitting, so it takes a hold, not a tap.
/// The fill sweeps as it holds, so progress toward ending is always visible.
struct HoldToEndButton: View {
    let title: String
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var isPressing = false

    private let holdDuration: Double = 0.7

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.body)
                .foregroundStyle(VTPalette.text.opacity(0.9))
                .padding(.horizontal, 34)
                .frame(minHeight: 52)
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(VTPalette.accent.opacity(0.22))
                            .frame(width: proxy.size.width * progress)
                    }
                }
                .overlay(Capsule().stroke(VTPalette.border, lineWidth: 1))
                .clipShape(Capsule())
                .contentShape(Capsule())
                .scaleEffect(isPressing ? 0.985 : 1)
                .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
                    action()
                } onPressingChanged: { pressing in
                    isPressing = pressing
                    withAnimation(pressing ? .linear(duration: holdDuration) : .easeOut(duration: 0.2)) {
                        progress = pressing ? 1 : 0
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(title)
                .accessibilityHint("Press and hold to end")
                .accessibilityAction(named: "End now", action)

            Text("Press and hold to end")
                .font(.caption)
                .foregroundStyle(VTPalette.patina)
        }
    }
}

struct GongMark: View {
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle().stroke(VTPalette.border, lineWidth: 1)
            Circle().stroke(VTPalette.accent, lineWidth: 1)
                .frame(width: size * 0.38, height: size * 0.38)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
