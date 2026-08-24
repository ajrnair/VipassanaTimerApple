import SwiftUI

/// Paired with the log's add button in the same headers, so both are the same
/// hairline circle at the same size rather than a bordered circle beside a glyph
/// that carries its own, much smaller one.
struct AboutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info")
                .font(.system(size: 16, weight: .light))
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(VTPalette.border, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(VTPalette.text)
        .accessibilityLabel("About and privacy")
        .accessibilityHint("Opens appearance, privacy, source, license, and app information")
    }
}

/// The screen headers all share one shape: eyebrow, title, and the info button
/// held to the trailing edge. It is the only affordance that appears on every
/// screen, and it is where the appearance choice lives.
struct ScreenHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(eyebrow)
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(VTPalette.patina)

                Text(title)
                    .font(.vtSerif(.largeTitle))
                    .foregroundStyle(VTPalette.text)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
            trailing
        }
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
