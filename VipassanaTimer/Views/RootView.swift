import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsAbout = false
    // Dawn is the light appearance and Night is the dark one, so following the
    // system needs no code beyond handing back nil.
    @AppStorage("appearance") private var appearanceRaw = VTAppearance.system.rawValue

    private var appearance: VTAppearance {
        VTAppearance(rawValue: appearanceRaw) ?? .system
    }

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    var body: some View {
        Group {
            #if os(macOS)
            desktopShell
            #else
            if horizontalSizeClass == .regular {
                desktopShell
            } else {
                mobileShell
            }
            #endif
        }
        .preferredColorScheme(appearance.colorScheme)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                model.reconcile()
            }
        }
        .onOpenURL(perform: model.handlePracticeURL)
        .alert(item: $model.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showsAbout) {
            AboutView()
        }
    }

    private var desktopShell: some View {
        HStack(spacing: 0) {
            AppSidebar(route: $model.route)
            activeContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ganzfeldField(.idle)
    }

    // During any session state the bar is inert, so it hides: nothing competes for attention.
    private var practiceIsActive: Bool {
        model.isTransitioning || model.completion != nil || model.activeSession != nil
    }

    private var mobileShell: some View {
        activeContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !practiceIsActive {
                    MobileBottomBar(route: $model.route)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: practiceIsActive)
    }

    @ViewBuilder
    private var activeContent: some View {
        if model.isTransitioning {
            VStack(spacing: 14) {
                ProgressView()
                    .tint(VTPalette.accent)
                Text("Preparing the gongs…")
                    .font(.vtSerif(.headline))
                    .foregroundStyle(VTPalette.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ganzfeldField(.preparing)
        } else if let completion = model.completion {
            CompletionView(completion: completion, onDone: model.clearCompletion)
        } else if let session = model.activeSession, let snapshot = model.snapshot {
            switch snapshot.phase {
            case .preparing:
                PreparationView(snapshot: snapshot, onEnd: model.endActivePractice)
            case .meditating:
                MeditationTimerView(
                    session: session,
                    snapshot: snapshot,
                    onEnd: model.endActivePractice
                )
            case .awareness:
                AwarenessRunningView(
                    session: session,
                    snapshot: snapshot,
                    onEnd: model.endActivePractice
                )
            case .completed:
                ProgressView()
                    .tint(VTPalette.accent)
            }
        } else {
            switch model.route {
            case .home:
                HomeView(
                    onStart: { minutes in
                        Task { await model.startStandard(minutes: minutes) }
                    },
                    guidanceMode: $model.guidanceMode,
                    onAbout: { showsAbout = true }
                )
            case .log:
                MeditationLogView(
                    records: model.records,
                    warnsAboutUnreadableEntries: model.historyHadUnreadableEntries,
                    onSave: model.saveLogRecord,
                    onAdd: model.addLogRecord,
                    onDelete: model.deleteLogRecord,
                    healthKitAvailable: model.isHealthKitAvailable,
                    healthKitEnabled: model.healthKitEnabled,
                    onHealthKitChanged: { enabled in
                        Task { await model.setHealthKitEnabled(enabled) }
                    },
                    onAbout: { showsAbout = true }
                )
            case .awareness:
                AwarenessSetupView(
                    onStart: { hours, interval in
                        Task { await model.startAwareness(hours: hours, intervalMinutes: interval) }
                    },
                    onAbout: { showsAbout = true }
                )
            }
        }
    }
}
