import SwiftUI

struct CompletionView: View {
    let completion: CompletionPresentation
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CompletionMark()
                .padding(.bottom, 34)

            Text(completion.mode == .awareness ? "AWARENESS COMPLETE" : "SESSION COMPLETE")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(VTPalette.accent)

            Text("Time observed.")
                .font(.vtSerif(.largeTitle))
                .foregroundStyle(VTPalette.text)
                .padding(.top, 12)

            Text(DurationFormatter.concise(completion.duration))
                .font(.vtSerif(.title))
                .foregroundStyle(VTPalette.text)
                .padding(.top, 10)

            Text(
                completion.mode == .awareness
                    ? "Awareness practice is complete and has not been added to the meditation log."
                    : "This session has been recorded in your meditation log."
            )
            .font(.body)
            .foregroundStyle(VTPalette.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: 330)
            .padding(.top, 12)

            Button("Done", action: onDone)
                .buttonStyle(VTPrimaryButtonStyle())
                .padding(.top, 30)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ganzfeldField(.complete)
    }
}
