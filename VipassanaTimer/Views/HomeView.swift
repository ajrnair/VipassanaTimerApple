import SwiftUI

struct HomeView: View {
    let onStart: (Int) -> Void
    @Binding var guidanceMode: GuidanceMode
    let onAbout: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("lastSitMinutes") private var selectedMinutes = 45
    @Environment(\.isCompactHeight) private var isCompactHeight

    private let presets = [15, 30, 45, 60, 120]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "A place\nto sit.")

                Text(
                    guidanceMode == .silent
                        ? "One gong to begin. Three to finish."
                        : "Gongs and minimal voice guidance."
                )
                .font(.system(VTLayout.subtitleStyle(compact: isCompactHeight)))
                .foregroundStyle(VTPalette.muted)
                .frame(maxWidth: 440, alignment: .leading)
                .padding(.top, isCompactHeight ? 8 : 12)

                HStack(spacing: 26) {
                    ForEach(GuidanceMode.allCases) { option in
                        VTUnderlinedChoice(title: option.title, isSelected: guidanceMode == option) {
                            if guidanceMode != option { Haptics.selection() }
                            guidanceMode = option
                            if option == .guided, !GuidedProgramCatalog.supports(minutes: selectedMinutes) {
                                selectedMinutes = 45
                            }
                        }
                    }
                }
                .padding(.top, isCompactHeight ? 12 : 20)
                .accessibilityHint("Guided practice includes spoken instructions and gongs")

                MeditationRing(progress: 0, timeText: "\(selectedMinutes)", stateText: "minutes")
                    .frame(
                        maxWidth: VTLayout.ringSize(compact: isCompactHeight),
                        maxHeight: VTLayout.ringSize(compact: isCompactHeight)
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, isCompactHeight ? 14 : 26)
                    .animation(.easeInOut(duration: 0.2), value: selectedMinutes)

                durationChoices
                    .padding(.top, isCompactHeight ? 10 : 18)
                    .animation(.easeInOut(duration: 0.2), value: guidanceMode)

                Button("Begin") { onStart(selectedMinutes) }
                    .buttonStyle(VTPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, isCompactHeight ? 12 : 20)
                    .accessibilityLabel("Begin a \(selectedMinutes) minute meditation")
                    .accessibilityHint("Begins an eight-second preparation countdown")
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 12)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity)
        }
        // Haptics belong to choosing, not to sitting. The setup screen confirms a tap the way
        // the Watch already does; once a sitting starts the app says nothing until its gong.
        .safeAreaInset(edge: .top, spacing: 0) {
            MobileTopBar(eyebrow: "VIPASSANA TIMER") {
                AboutButton(action: onAbout)
            }
        }
        .ganzfeldField(.idle)
        .navigationTitle("Meditation")
    }

    /// Guided practice only exists at certain lengths, so unavailable durations
    /// leave the row rather than sitting there disabled.
    private var availableMinutes: [Int] {
        presets.filter { guidanceMode != .guided || GuidedProgramCatalog.supports(minutes: $0) }
    }

    @ViewBuilder
    private var durationChoices: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(availableMinutes, id: \.self) { choice($0) }
            }
        } else {
            HStack(spacing: 0) {
                ForEach(availableMinutes, id: \.self) { minutes in
                    choice(minutes).frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// The boards reserve the underline for the mode row and mark the selected
    /// duration by weight and full-strength ink alone, so one screen never shows
    /// two underlines competing to mean "selected".
    private func choice(_ minutes: Int) -> some View {
        Button {
            if selectedMinutes != minutes { Haptics.selection() }
            selectedMinutes = minutes
        } label: {
            Text("\(minutes)")
                .font(.body.weight(selectedMinutes == minutes ? .medium : .regular))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedMinutes == minutes ? VTPalette.text : VTPalette.patina)
        .accessibilityLabel("\(minutes) minutes")
        .accessibilityAddTraits(selectedMinutes == minutes ? .isSelected : [])
    }
}
