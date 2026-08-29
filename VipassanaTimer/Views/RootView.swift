import SwiftUI

struct RootView: View {
    @ObservedObject var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var showsAbout = false
    /// One quiet gate at first launch, never again. The same screen stays
    /// reachable from About as "How this works".
    @AppStorage("hasSeenHowThisWorks") private var hasSeenHowThisWorks = false
    @State private var showsHowThisWorks = false
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
        // Measured once here rather than in each screen: an SE reports the same size class as a
        // Pro Max, so only the actual height tells them apart.
        GeometryReader { proxy in
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
            .environment(\.isCompactHeight, proxy.size.height < VTLayout.compactHeightThreshold)
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
        .onAppear {
            // Never over a running practice: a deep link can start a session on
            // a fresh install, and a relaunch mid-session lands here too.
            if !hasSeenHowThisWorks, !model.hasRunningPractice, model.completion == nil {
                showsHowThisWorks = true
            }
        }
        .onChange(of: model.hasRunningPractice) { _, running in
            if running { showsHowThisWorks = false }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showsHowThisWorks) {
            // A cover is its own hierarchy: it inherits neither the root's
            // height measurement nor its appearance override, so both are
            // established again here.
            GeometryReader { proxy in
                HowThisWorksView {
                    hasSeenHowThisWorks = true
                    showsHowThisWorks = false
                }
                .environment(\.isCompactHeight, proxy.size.height < VTLayout.compactHeightThreshold)
            }
            .preferredColorScheme(appearance.colorScheme)
        }
        #else
        .sheet(isPresented: $showsHowThisWorks) {
            HowThisWorksView {
                hasSeenHowThisWorks = true
                showsHowThisWorks = false
            }
            .frame(minWidth: 540, minHeight: 600)
        }
        #endif
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
                    sections: model.monthSections,
                    practicedDays: model.practicedDays,
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
                        Task {
                            if let interval {
                                await model.startAwareness(hours: hours, intervalMinutes: interval)
                            } else {
                                await model.startAwarenessRandom(hours: hours)
                            }
                        }
                    },
                    onAbout: { showsAbout = true }
                )
            }
        }
    }
}
