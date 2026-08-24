import SwiftUI

@main
struct VipassanaTimerWatchApp: App {
    @StateObject private var model = WatchAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
    }
}
