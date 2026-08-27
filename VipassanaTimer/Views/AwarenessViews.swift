import SwiftUI

/// The board turns Awareness into the same language as Sit: one ring carrying the
/// number, and a row of underlined choices beneath it. The two typed fields and
/// their steppers are gone — hours come from turning the ring, and the interval
/// from a chip. Arbitrary intervals remain reachable through Shortcuts and the
/// `vipassanatimer://aware` URL, exactly as custom sitting lengths are.
///
/// Random is the last chip in the same row, not a mode: you either answer
/// "how often?" with a number, or you hand the answer to the app. The word
/// "Fixed" never appears — there was nothing it explained.
private enum AwarenessGongMode: String {
    case fixed
    case random
}

struct AwarenessSetupView: View {
    /// `intervalMinutes` is `nil` for a random start: the app decides.
    let onStart: (_ hours: Int, _ intervalMinutes: Int?) -> Void
    let onAbout: () -> Void

    @AppStorage("lastAwarenessHours") private var hours = AwarenessPolicy.defaultHours
    @AppStorage("lastAwarenessInterval") private var intervalMinutes = AwarenessPolicy.defaultIntervalMinutes
    @AppStorage("lastAwarenessGongMode") private var gongModeRaw = AwarenessGongMode.fixed.rawValue
    @AppStorage("appearance") private var appearanceRaw = VTAppearance.system.rawValue
    @State private var showsHowThisWorks = false

    private var appearance: VTAppearance {
        VTAppearance(rawValue: appearanceRaw) ?? .system
    }

    private var gongMode: AwarenessGongMode {
        AwarenessGongMode(rawValue: gongModeRaw) ?? .fixed
    }

    @Environment(\.isCompactHeight) private var isCompactHeight

    private let intervalChoices = [1, 2, 5, 10, 15, 30, 60]
    /// Smaller than the Sit ring in both classes: this screen carries two more
    /// rows (the gong mode and its detail), and the whole point is that Begin
    /// is on screen without scrolling on every supported phone.
    private var ringSide: CGFloat { isCompactHeight ? 132 : 190 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(title: "Always be\naware.")

                Text("One gong at custom intervals to remind.")
                    .font(.system(VTLayout.subtitleStyle(compact: isCompactHeight)))
                    .foregroundStyle(VTPalette.muted)
                    .frame(maxWidth: 430, alignment: .leading)
                    .padding(.top, isCompactHeight ? 8 : 10)

                MeditationRing(
                    progress: Double(hours) / Double(AwarenessPolicy.maximumHours),
                    timeText: "\(hours)",
                    stateText: "hours",
                    numeralSize: 78,
                    showsHandle: true
                )
                .frame(width: ringSide, height: ringSide)
                .animation(.easeOut(duration: 0.12), value: hours)
                .contentShape(Circle())
                .gesture(turnGesture)
                .frame(maxWidth: .infinity)
                .padding(.top, isCompactHeight ? 14 : 24)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Total duration")
                .accessibilityValue("\(hours) hours")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: setHours(hours + 1)
                    case .decrement: setHours(hours - 1)
                    @unknown default: break
                    }
                }

                Text("Turn the ring · 1 to 24 hours")
                    .font(.footnote)
                    .foregroundStyle(VTPalette.patina)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, isCompactHeight ? 6 : 8)
                    .accessibilityHidden(true)

                Text("GONG INTERVAL · MINUTES")
                    .font(.caption2)
                    .tracking(2.4)
                    .foregroundStyle(VTPalette.patina)
                    .padding(.top, isCompactHeight ? 14 : 22)

                // Eight answers in one row is more than the underlined-choice
                // component was drawn for, so this row sets its own, slightly
                // smaller type: the numerals share the width evenly and the
                // word keeps its own.
                HStack(spacing: 0) {
                    ForEach(intervalChoices, id: \.self) { minutes in
                        intervalChip(minutes)
                            .frame(maxWidth: .infinity)
                    }
                    // Random is one more answer to "how often?" — underlined in
                    // the accent, the quiet mark that the app places the gongs.
                    randomChip
                        .fixedSize()
                }
                .padding(.top, 4)

                // The caption's space is reserved in both states so Begin
                // holds still: a chosen number needs no sentence, and Random
                // gets exactly one.
                Text(gongMode == .random ? randomCaption : " ")
                    .font(.footnote)
                    .foregroundStyle(VTPalette.patina)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(minHeight: 22)
                    .padding(.top, isCompactHeight ? 6 : 10)
                    .accessibilityHidden(gongMode != .random)

                Button("Begin Awareness") {
                    onStart(hours, gongMode == .fixed ? intervalMinutes : nil)
                }
                .buttonStyle(VTPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .padding(.top, isCompactHeight ? 10 : 16)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, isCompactHeight ? 8 : 12)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            MobileTopBar(eyebrow: "AWARENESS MODE") {
                HStack(spacing: 4) {
                    VTCircleButton(
                        systemImage: "questionmark",
                        label: "How this works",
                        hint: "Shows the one-screen guide to the app"
                    ) {
                        showsHowThisWorks = true
                    }
                    AboutButton(action: onAbout)
                }
            }
        }
        .sheet(isPresented: $showsHowThisWorks) {
            HowThisWorksView { showsHowThisWorks = false }
                .preferredColorScheme(appearance.colorScheme)
        }
        .ganzfeldField(.idle)
        .navigationTitle("Awareness")
    }

    /// A turn of the ring is an angle, not a distance: the hour follows wherever
    /// the finger sits around the circle, so a drag can be picked up anywhere.
    private var turnGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let centre = ringSide / 2
                let dx = value.location.x - centre
                let dy = value.location.y - centre
                guard dx != 0 || dy != 0 else { return }

                var angle = atan2(dx, -dy)
                if angle < 0 { angle += 2 * .pi }
                let step = Int((angle / (2 * .pi) * 24).rounded())
                setHours(step == 0 ? 24 : step)
            }
    }

    private func setHours(_ value: Int) {
        let bounded = min(AwarenessPolicy.maximumHours, max(AwarenessPolicy.minimumHours, value))
        guard bounded != hours else { return }
        hours = bounded
    }

    private func intervalChip(_ minutes: Int) -> some View {
        let isSelected = gongMode == .fixed && intervalMinutes == minutes
        return Button {
            intervalMinutes = minutes
            gongModeRaw = AwarenessGongMode.fixed.rawValue
        } label: {
            Text("\(minutes)")
                .font(.subheadline)
                .frame(minWidth: 28, minHeight: 44)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(isSelected ? VTPalette.text : .clear)
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? VTPalette.text : VTPalette.patina)
        .accessibilityLabel("\(minutes) minute interval")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var randomChip: some View {
        Button {
            gongModeRaw = AwarenessGongMode.random.rawValue
        } label: {
            Text("Random")
                .font(.subheadline)
                .frame(minWidth: 44, minHeight: 44)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(gongMode == .random ? VTPalette.accent : .clear)
                        .frame(height: 1)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(gongMode == .random ? VTPalette.accent : VTPalette.patina)
        .accessibilityLabel("Random intervals")
        .accessibilityHint("The app places the gongs at moments you can't predict")
        .accessibilityAddTraits(gongMode == .random ? .isSelected : [])
    }

    /// "5 to 10 minutes apart, at random." — follows the ring as it turns.
    private var randomCaption: String {
        let bounds = AwarenessScheduler.randomBounds(totalSeconds: TimeInterval(hours * 3_600))
        let minMinutes = Int(bounds.minimum / 60)
        let maxMinutes = Int(bounds.maximum / 60)
        return "\(minMinutes) to \(maxMinutes) minutes apart, at random."
    }
}

struct AwarenessRunningView: View {
    let session: ActiveSession
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("AWARENESS MODE")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(VTPalette.accent)

            Text("Always be aware.")
                .font(.vtSerif(.title))
                .foregroundStyle(VTPalette.text)
                .padding(.top, 12)

            AwarenessOrbit(
                timeText: DurationFormatter.awarenessCountdown(snapshot.remaining),
                caption: "remaining"
            )
            .frame(maxWidth: 280, maxHeight: 280)
            .padding(.top, 32)

            // No NEXT GONG countdown, in either mode: the screen is not for
            // watching, and an unanticipatable bell should stay that way.
            metadata(
                session.gongOffsets == nil
                    ? DurationFormatter.concise(session.interval ?? 0)
                    : "At random",
                label: session.gongOffsets == nil ? "INTERVAL" : "GONGS"
            )
            .padding(.top, 28)

            Text("Awareness time stays separate from the meditation log.")
                .font(.caption)
                .foregroundStyle(VTPalette.patina)
                .multilineTextAlignment(.center)
                .padding(.top, 22)

            HoldToEndButton(title: "End Awareness", action: onEnd)
                .padding(.top, 28)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ganzfeldField(.sitting)
    }

    private func metadata(_ value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.vtSerif(.title3))
                .monospacedDigit()
                .foregroundStyle(VTPalette.text)
            Text(label)
                .font(.caption2)
                .tracking(2.4)
                .foregroundStyle(VTPalette.muted)
        }
        .accessibilityElement(children: .combine)
    }
}
