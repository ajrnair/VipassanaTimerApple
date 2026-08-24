import SwiftUI

/// The board turns Awareness into the same language as Sit: one ring carrying the
/// number, and a row of underlined choices beneath it. The two typed fields and
/// their steppers are gone — hours come from turning the ring, and the interval
/// from a chip. Arbitrary intervals remain reachable through Shortcuts and the
/// `vipassanatimer://aware` URL, exactly as custom sitting lengths are.
struct AwarenessSetupView: View {
    let onStart: (Int, Int) -> Void
    let onAbout: () -> Void

    @AppStorage("lastAwarenessHours") private var hours = AwarenessPolicy.defaultHours
    @AppStorage("lastAwarenessInterval") private var intervalMinutes = AwarenessPolicy.defaultIntervalMinutes

    private let intervalChoices = [1, 2, 5, 10, 15, 30, 60]
    private let ringSide: CGFloat = 208

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenHeader(eyebrow: "AWARENESS MODE", title: "Always be\naware.") {
                    AboutButton(action: onAbout)
                }

                Text("One gong at custom intervals to remind.")
                    .font(.body)
                    .foregroundStyle(VTPalette.muted)
                    .frame(maxWidth: 430, alignment: .leading)
                    .padding(.top, 12)

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
                .padding(.top, 26)
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
                    .padding(.top, 12)
                    .accessibilityHidden(true)

                Text("GONG INTERVAL")
                    .font(.caption2)
                    .tracking(2.4)
                    .foregroundStyle(VTPalette.patina)
                    .padding(.top, 22)

                HStack(spacing: 0) {
                    ForEach(intervalChoices, id: \.self) { minutes in
                        VTUnderlinedChoice(
                            title: "\(minutes)",
                            isSelected: intervalMinutes == minutes
                        ) {
                            intervalMinutes = minutes
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel("\(minutes) minute interval")
                    }
                }
                .padding(.top, 8)

                Button("Begin Awareness") {
                    onStart(hours, intervalMinutes)
                }
                .buttonStyle(VTPrimaryButtonStyle())
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
            }
            .frame(maxWidth: 520, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.top, 30)
            .padding(.bottom, 108)
            .frame(maxWidth: .infinity)
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
}

struct AwarenessRunningView: View {
    let session: ActiveSession
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    private var nextGongIn: TimeInterval {
        guard let interval = session.interval, interval > 0 else { return snapshot.remaining }
        let elapsed = max(0, session.plannedDuration - snapshot.remaining)
        let untilBoundary = interval - elapsed.truncatingRemainder(dividingBy: interval)
        return min(untilBoundary, snapshot.remaining)
    }

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

            HStack(spacing: 42) {
                metadata(DurationFormatter.concise(session.interval ?? 0), label: "INTERVAL")
                metadata(DurationFormatter.awarenessCountdown(nextGongIn), label: "NEXT GONG")
            }
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
