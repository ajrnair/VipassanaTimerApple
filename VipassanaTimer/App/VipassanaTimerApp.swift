import SwiftUI

@main
struct VipassanaTimerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .frame(minWidth: minimumWidth, minHeight: minimumHeight)
        }
        #if os(macOS)
        .defaultSize(width: 980, height: 680)
        #endif
    }

    private var minimumWidth: CGFloat {
        #if os(macOS)
        760
        #else
        0
        #endif
    }

    private var minimumHeight: CGFloat {
        #if os(macOS)
        560
        #else
        0
        #endif
    }
}
