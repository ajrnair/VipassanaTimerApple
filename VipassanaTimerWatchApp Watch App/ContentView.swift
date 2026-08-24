import SwiftUI

struct ContentView: View {
    @ObservedObject var model: WatchAppModel
    @Environment(\.scenePhase) private var scenePhase
    // Root content is model-driven — it switches to the running view the
    // instant a session starts — but a NavigationStack's pushed screens don't
    // know that happened. Tapping Begin on Awareness genuinely started the
    // session (the ticker and audio were already running underneath), while
    // the setup screen stayed on top of the stack looking untouched, as if
    // nothing had happened. Clearing the path whenever a session starts or a
    // completion appears pops any pushed screen back to the root that just
    // changed beneath it.
    @State private var path = NavigationPath()

    var body: some View {
        // Everything lives inside one navigation stack. On watchOS the navigation
        // container is what reserves room for the system clock and keeps content
        // clear of the rounded corners, so the session screens — which sat
        // outside it — had no safe area at all: the eyebrow ran under the clock
        // and the end button was cut off by the bottom curve.
        NavigationStack(path: $path) {
            content
        }
        .onChange(of: model.activeSession?.id) { _, newValue in
            if newValue != nil { path = NavigationPath() }
        }
        .onChange(of: model.completion?.sessionID) { _, newValue in
            if newValue != nil { path = NavigationPath() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.resumeFromBackground()
            }
        }
        .onOpenURL(perform: model.handlePracticeURL)
        .alert(item: $model.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if model.isTransitioning {
                ProgressView()
                    .tint(WatchPalette.accent)
            } else if let completion = model.completion {
                WatchCompletionView(completion: completion, onDone: model.clearCompletion)
            } else if let session = model.activeSession, let snapshot = model.snapshot {
                switch snapshot.phase {
                case .preparing:
                    WatchPreparationView(snapshot: snapshot, onEnd: model.endActivePractice)
                case .meditating:
                    WatchMeditationView(
                        session: session,
                        snapshot: snapshot,
                        onEnd: model.endActivePractice
                    )
                case .awareness:
                    WatchAwarenessRunningView(
                        session: session,
                        snapshot: snapshot,
                        onEnd: model.endActivePractice
                    )
                case .completed:
                    ProgressView()
                        .tint(WatchPalette.accent)
                }
            } else {
                WatchHomeView(model: model)
            }
        }
    }
}
