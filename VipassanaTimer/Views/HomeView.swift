import SwiftUI

struct HomeView: View {
    let onStart: (Int) -> Void
    @Binding var guidanceMode: GuidanceMode
    let onAbout: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("lastSitMinutes") private var selectedMinutes = 45

    private let presets = [15, 30, 45, 60, 120]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(eyebrow: "VIPASSANA TIMER", title: "A place\nto sit.") {
                    AboutButton(action: onAbout)
                }

                Text(
                    guidanceMode == .silent
                        ? "One gong to begin. Three to finish."
                        : "Gongs and minimal voice guidance."
                )
                .font(.body)
                .foregroundStyle(VTPalette.muted)
                .frame(maxWidth: 440, alignment: .leading)
                .padding(.top, 12)

                HStack(spacing: 26) {
                    ForEach(GuidanceMode.allCases) { option in
                        VTUnderlinedChoice(title: option.title, isSelected: guidanceMode == option) {
                            guidanceMode = option
                            if option == .guided, !GuidedProgramCatalog.supports(minutes: selectedMinutes) {
                                selectedMinutes = 45
                            }
                        }
                    }
                }
                .padding(.top, 20)
                .accessibilityHint("Guided practice includes spoken instructions and gongs")

                MeditationRing(progress: 0, timeText: "\(selectedMinutes)", stateText: "minutes")
                    .frame(maxWidth: 208, maxHeight: 208)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 26)
                    .animation(.easeInOut(duration: 0.2), value: selectedMinutes)

                durationChoices
                    .padding(.top, 18)
                    .animation(.easeInOut(duration: 0.2), value: guidanceMode)

                Button("Begin") { onStart(selectedMinutes) }
                    .buttonStyle(VTPrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .accessibilityLabel("Begin a \(selectedMinutes) minute meditation")
                    .accessibilityHint("Begins an eight-second preparation countdown")
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity)
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
