import SwiftUI

struct PreparationView: View {
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    private var secondsRemaining: Int { max(1, Int(ceil(snapshot.remaining))) }

    var body: some View {
        VStack(spacing: 0) {
            Text("PREPARE TO SIT")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(VTPalette.accent)

            MeditationRing(
                progress: 0,
                timeText: "\(secondsRemaining)",
                stateText: "seconds",
                numeralSize: 72
            )
            .frame(maxWidth: 214, maxHeight: 214)
            .padding(.vertical, 34)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Starting in")
            .accessibilityValue("\(secondsRemaining) seconds")

            Text("Let the body settle.")
                .font(.vtSerif(.title))
                .foregroundStyle(VTPalette.text)

            Text("The first gong will begin the meditation.")
                .font(.body)
                .foregroundStyle(VTPalette.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            HoldToEndButton(title: "End Session", action: onEnd)
                .padding(.top, 30)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ganzfeldField(.preparing)
    }
}

struct MeditationTimerView: View {
    let session: ActiveSession
    let snapshot: TimerSnapshot
    let onEnd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("IN SILENCE")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(VTPalette.accent)

            MeditationRing(
                progress: snapshot.progressRemaining,
                timeText: DurationFormatter.meditationCountdown(snapshot.remaining),
                stateText: "remaining",
                numeralSize: 62
            )
            .frame(maxWidth: 300, maxHeight: 300)
            .padding(.top, 36)

            VStack(spacing: 6) {
                Text(DurationFormatter.concise(session.plannedDuration))
                    .font(.vtSerif(.title3))
                    .foregroundStyle(VTPalette.text)
                Text("SESSION")
                    .font(.caption2)
                    .tracking(2.4)
                    .foregroundStyle(VTPalette.muted)
            }
            .accessibilityElement(children: .combine)
            .padding(.top, 28)

            HoldToEndButton(title: "End Session", action: onEnd)
                .padding(.top, 32)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ganzfeldField(.sitting)
    }
}
