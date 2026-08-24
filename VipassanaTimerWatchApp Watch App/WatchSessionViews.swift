import SwiftUI

struct WatchPreparationView: View {
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    private var secondsRemaining: Int { max(1, Int(ceil(snapshot.remaining))) }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    WatchEyebrow(text: "Prepare to sit")
                        .padding(.top, 6)

                    WatchApertureRing(
                        timeText: "\(secondsRemaining)",
                        caption: "seconds",
                        numeralFraction: 0.37
                    )
                    .frame(width: WatchMetrics.ring(0.44), height: WatchMetrics.ring(0.44))
                    .padding(.top, 4)
                    .accessibilityLabel("Starting in")
                    .accessibilityValue("\(secondsRemaining) seconds")

                    Text("Let the body settle.")
                        .font(.vtWatchSerif(15))
                        .foregroundStyle(WatchPalette.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 4)

                    WatchEndButton(title: "End", confirmationTitle: "End this sitting?", onEnd: onEnd)
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
                // A floor, not a cap: short content is stretched to fill the
                // display so the button's bottom padding is real, visible margin
                // rather than trailing space parked below the fold. Content that
                // outgrows this height — the largest accessibility sizes — simply
                // grows past it and scrolls, same as before.
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 10)
            }
        }
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .preparing) }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct WatchMeditationView: View {
    let session: ActiveSession
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    WatchEyebrow(text: "In silence")
                        .padding(.top, 6)

                    WatchApertureRing(
                        progress: snapshot.progressRemaining,
                        timeText: DurationFormatter.meditationCountdown(snapshot.remaining),
                        caption: "remaining",
                        numeralFraction: 0.21
                    )
                    .frame(width: WatchMetrics.ring(0.46), height: WatchMetrics.ring(0.46))
                    .padding(.top, 4)

                    Text(DurationFormatter.concise(session.plannedDuration))
                        .font(.vtWatchSerif(14))
                        .foregroundStyle(WatchPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 4)

                    WatchEndButton(title: "End sitting", confirmationTitle: "End this sitting?", onEnd: onEnd)
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 10)
            }
        }
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .sitting) }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct WatchAwarenessRunningView: View {
    let session: ActiveSession
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    WatchEyebrow(text: "Awareness")
                        .padding(.top, 6)

                    WatchApertureRing(
                        progress: snapshot.progressRemaining,
                        timeText: DurationFormatter.awarenessCountdown(snapshot.remaining),
                        caption: "remaining",
                        numeralFraction: 0.16
                    )
                    .frame(width: WatchMetrics.ring(0.44), height: WatchMetrics.ring(0.44))
                    .padding(.top, 4)

                    Text("every \(DurationFormatter.concise(session.interval ?? 0))")
                        .font(.vtWatchSerif(14))
                        .foregroundStyle(WatchPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 4)

                    WatchEndButton(title: "End awareness", confirmationTitle: "End awareness?", onEnd: onEnd)
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 10)
            }
        }
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .sitting) }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct WatchCompletionView: View {
    let completion: CompletionPresentation
    let onDone: () -> Void

    var body: some View {
        // A ScrollView, so a long phrase or a large accessibility size can move
        // rather than be squeezed: the compressed text was what truncated
        // "Time observed." to "Time…" on the 40 mm.
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // The mark, at the centre of the bloom: concentric hairlines
                    // around a single warm point, as on the phone.
                    Spacer(minLength: 6)
                    ZStack {
                        Circle().stroke(WatchPalette.border, lineWidth: 1)
                        Circle().stroke(WatchPalette.border.opacity(0.45), lineWidth: 1)
                            .padding(11)
                        Circle()
                            .fill(WatchPalette.accent)
                            .frame(width: 7, height: 7)
                    }
                    .frame(width: WatchMetrics.ring(0.17), height: WatchMetrics.ring(0.17))
                    .accessibilityHidden(true)

                    Text(completion.mode == .awareness ? "Awareness\ncomplete." : "Time\nobserved.")
                        .font(.vtWatchSerif(19))
                        .foregroundStyle(WatchPalette.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 4)

                    Text(DurationFormatter.concise(completion.duration))
                        .font(.vtWatchSerif(15))
                        .foregroundStyle(WatchPalette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.top, 4)

                    Button("Done", action: onDone)
                        .font(.system(size: 16, weight: .medium))
                        .buttonStyle(WatchProminentButtonStyle())
                        .padding(.top, 6)
                        .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.horizontal, 10)
                .padding(.top, 2)
            }
        }
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .complete) }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct WatchEndButton: View {
    let title: String
    let confirmationTitle: String
    let onEnd: () -> Void

    @State private var confirmsEnd = false

    var body: some View {
        Button(title) {
            confirmsEnd = true
        }
        .font(.system(size: 14))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .buttonStyle(WatchOutlineButtonStyle())
        .confirmationDialog(confirmationTitle, isPresented: $confirmsEnd) {
            Button("End now", role: .destructive, action: onEnd)
            Button("Keep going", role: .cancel) {}
        }
    }
}
