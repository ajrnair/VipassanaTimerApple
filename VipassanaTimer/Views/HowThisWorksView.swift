import SwiftUI

/// The whole app on one screen: three mode rows, the storage sentence, the
/// locked-phone fact, Begin. Shown once at first launch, and again any time
/// from About — which is also the app's whole answer to "help".
///
/// The copy explains what the app does, never the practice — the app is
/// independent and not a substitute for instruction, and that boundary is
/// stated in About, not re-argued here.
struct HowThisWorksView: View {
    let onBegin: () -> Void

    @Environment(\.isCompactHeight) private var isCompactHeight

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(isCompactHeight ? "How this works." : "How this\nworks.")
                    .font(.vtSerif(VTLayout.displayTitleStyle(compact: isCompactHeight)))
                    .foregroundStyle(VTPalette.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A privacy-first timer for Vipassana practice.")
                    .font(.system(VTLayout.subtitleStyle(compact: isCompactHeight)))
                    .foregroundStyle(VTPalette.muted)
                    .padding(.top, isCompactHeight ? 8 : 12)

                modeRow(
                    "SILENT",
                    "One gong to begin, three to end. Nothing in between."
                )
                .padding(.top, isCompactHeight ? 8 : 12)
                modeRow(
                    "GUIDED",
                    "The same sitting, with minimal spoken Vipassana guidance."
                )
                if PracticeFeatures.awarenessEnabled {
                    modeRow(
                        "AWARE",
                        "Gongs through your day, up to 24 hours — at your interval, or at moments you can't predict."
                    )
                }

                Text("Every sitting is saved on this phone; open one to leave a note. Apple Health is optional, and off until you turn it on.")
                    .font(.footnote)
                    .foregroundStyle(VTPalette.patina)
                    .padding(.top, isCompactHeight ? 10 : 14)

                Text("Gongs play with the phone locked, even on silent.")
                    .font(.footnote)
                    .foregroundStyle(VTPalette.patina)
                    .padding(.top, isCompactHeight ? 8 : 12)

                Button("Begin", action: onBegin)
                    .buttonStyle(VTPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, isCompactHeight ? 14 : 20)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, isCompactHeight ? 20 : 32)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        // The gate is one screen of fixed copy; it steps up with the reader's
        // text size to a point, then holds so Begin stays reachable without
        // scrolling. Past that the scroll view is the fallback.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .ganzfeldField(.idle)
    }

    private func modeRow(_ name: String, _ line: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(name)
                .font(.caption2)
                .tracking(2.4)
                .foregroundStyle(VTPalette.accent)
            Text(line)
                .font(isCompactHeight ? .footnote : .subheadline)
                .foregroundStyle(VTPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, isCompactHeight ? 8 : 11)
            Rectangle().fill(VTPalette.border.opacity(0.5)).frame(height: 1)
        }
        .padding(.top, isCompactHeight ? 8 : 11)
        .accessibilityElement(children: .combine)
    }
}
