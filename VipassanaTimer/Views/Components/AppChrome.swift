import SwiftUI

/// The one control shape the chrome uses: a hairline circle.
///
/// The circle is drawn at 30pt inside a 40×44pt target: small enough that three
/// or four of them read as quiet marks rather than a toolbar, with the strokes
/// still clear of each other, and the target still tall enough for a thumb.
/// The hit shape is the full target, not the circle, so the smaller drawing
/// costs nothing to touch.
struct VTCircleButton: View {
    let systemImage: String
    let label: String
    var hint: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .light))
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(VTPalette.border, lineWidth: 1))
                .frame(width: 40, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(VTPalette.text)
        .accessibilityLabel(label)
        .accessibilityHint(hint ?? "")
    }
}

struct AboutButton: View {
    let action: () -> Void

    var body: some View {
        VTCircleButton(
            systemImage: "info",
            label: "About and privacy",
            hint: "Opens appearance, privacy, source, license, and app information",
            action: action
        )
    }
}

/// The counterpart to `MobileBottomBar`, and it behaves the same way: the line
/// that names the screen and the controls that belong to every screen stay put
/// while the screen scrolls beneath them. Content fades out into the top of the
/// field rather than sliding under a hard edge, so nothing in the language draws
/// a line across the field. The scrim uses `VTField1` because that is the colour
/// the field actually is at the top, exactly as the bottom bar uses `VTField5`.
struct MobileTopBar<Trailing: View>: View {
    let eyebrow: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(eyebrow)
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(VTPalette.patina)

            Spacer(minLength: 0)
            trailing
        }
        .padding(.leading, 30)
        .padding(.trailing, 18)
        .padding(.top, 4)
        .padding(.bottom, 28)
        .background {
            // Solid until past the label's baseline, then a long fade. A shorter
            // ramp lets a scrolled row ghost through the eyebrow and the buttons,
            // which reads as a rendering fault rather than as depth.
            LinearGradient(
                stops: [
                    .init(color: Color("VTField1"), location: 0),
                    .init(color: Color("VTField1"), location: 0.58),
                    .init(color: Color("VTField1").opacity(0.90), location: 0.74),
                    .init(color: Color("VTField1").opacity(0.45), location: 0.88),
                    .init(color: Color("VTField1").opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        }
        // Keep the persistent chrome compact while the scrollable screen content
        // remains fully responsive at every accessibility text size.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

/// What remains in the scroll: the title alone. The eyebrow and the controls
/// moved to `MobileTopBar`.
struct ScreenHeader: View {
    let title: String
    @Environment(\.isCompactHeight) private var isCompactHeight

    var body: some View {
        // The line break in a title is a composition, not a necessity. On a short screen the
        // second line costs more than the shape is worth, and the stepped-down type fits on one.
        Text(isCompactHeight ? title.replacingOccurrences(of: "\n", with: " ") : title)
            .font(.vtSerif(VTLayout.displayTitleStyle(compact: isCompactHeight)))
            .foregroundStyle(VTPalette.text)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppSidebar: View {
    @Binding var route: AppRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GongMark()
                .padding(.leading, 12)
                .padding(.bottom, 22)

            ForEach(AppRoute.allCases) { item in
                Button {
                    route = item
                } label: {
                    Label(item.title, systemImage: item.systemImage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 46)
                        .contentShape(Rectangle())
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(route == item ? VTPalette.accent : .clear)
                                .frame(width: 2)
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(route == item ? VTPalette.text : VTPalette.patina)
                .accessibilityAddTraits(route == item ? .isSelected : [])
            }

            Spacer()

            Text("No scores.\nNo streaks.")
                .font(.vtSerif(.subheadline))
                .italic()
                .foregroundStyle(VTPalette.patina)
                .padding(12)
        }
        .padding(18)
        .frame(width: 220)
        .overlay(alignment: .trailing) {
            Rectangle().fill(VTPalette.border.opacity(0.5)).frame(width: 1)
        }
    }
}

/// Navigation floats in the field rather than sitting on a bar. Nothing in this
/// language is a filled surface, so there is no edge and no hairline here: the
/// labels rest on a scrim that fades up from the foot of the field, which keeps
/// them legible over scrolled content without ever drawing a line across it.
struct MobileBottomBar: View {
    @Binding var route: AppRoute

    var body: some View {
        HStack(spacing: 0) {
            navigationButton(.home, shortTitle: "Sit")
            navigationButton(.log, shortTitle: "Log")
            if PracticeFeatures.awarenessEnabled {
                navigationButton(.awareness, shortTitle: "Aware")
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 52)
        .padding(.bottom, 18)
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color("VTField5").opacity(0), location: 0),
                    .init(color: Color("VTField5").opacity(0.62), location: 0.28),
                    .init(color: Color("VTField5").opacity(0.94), location: 0.55),
                    .init(color: Color("VTField5").opacity(0.99), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
        // Keep the persistent chrome compact while the scrollable screen content
        // remains fully responsive at every accessibility text size.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private func navigationButton(_ item: AppRoute, shortTitle: String) -> some View {
        Button {
            route = item
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(route == item ? VTPalette.text : .clear)
                    .frame(width: 3, height: 3)
                Text(shortTitle)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(route == item ? VTPalette.text : VTPalette.patina)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(route == item ? .isSelected : [])
    }
}
