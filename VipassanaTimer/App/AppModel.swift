import Combine
import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum AppRoute: String, CaseIterable, Identifiable {
    case home
    case log
    case awareness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Meditation"
        case .log: "Meditation Log"
        case .awareness: "Awareness"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .log: "calendar"
        case .awareness: "bell"
        }
    }
}

struct AppAlert: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var message: String
}

@MainActor
final class AppModel: ObservableObject {
    @Published var route: AppRoute = .home
    @Published private(set) var lifecycle = PracticeLifecycle()
    @Published private(set) var clock = SessionClock.live
    @Published private(set) var records: [MeditationRecord] = []
    /// Month grouping and per-day membership, computed once per history change
    /// rather than on every render — a daily practice accumulates hundreds of
    /// rows, and the log screen re-evaluates its body far more often than the
    /// history actually changes.
    @Published private(set) var monthSections: [MonthSection] = []
    @Published private(set) var practicedDays: [DailyTotal] = []
    @Published private(set) var historyHadUnreadableEntries = false
    @Published private(set) var healthKitEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
    @Published var guidanceMode = GuidanceMode(
        rawValue: UserDefaults.standard.string(forKey: "guidanceMode") ?? ""
    ) ?? .silent {
        didSet { UserDefaults.standard.set(guidanceMode.rawValue, forKey: "guidanceMode") }
    }
    @Published var alert: AppAlert?

    private let historyStore: HistoryStore
    private let sessionStore: SessionStore
    private let healthKitWriter = HealthKitWriter()
    private lazy var historySync = HistorySyncService(store: historyStore) { [weak self] in
        self?.historyDidSync()
    }
    private let sleepAssertion = SleepAssertionController()
    private let gongPlayer = PracticeGongPlayer()
    private let guidedPlayer = GuidedProgramPlayer()
    private var ticker: AnyCancellable?
    private var intentCancellables = Set<AnyCancellable>()
    private var healthExportsInFlight = Set<UUID>()

    init(
        historyStore: HistoryStore = HistoryStore(),
        sessionStore: SessionStore = SessionStore()
    ) {
        self.historyStore = historyStore
        self.sessionStore = sessionStore
        LegacyNotificationCleanup.removeAll()
        restore()
        #if DEBUG
        applyDebugRouteArgument()
        #endif
        if activeSession != nil {
            startTicker()
        }
        observeAppIntents()
        historySync.activate()
        if let activeSession {
            try? gongPlayer.start(session: activeSession)
        }
        Task {
            restoreHealthKitExport()
        }
    }

    var snapshot: TimerSnapshot? {
        guard let activeSession else { return nil }
        return TimerEngine.snapshot(for: activeSession, at: clock)
    }

    var activeSession: ActiveSession? { lifecycle.state.activeSession }

    var completion: CompletionPresentation? { lifecycle.state.completion }

    var isTransitioning: Bool { lifecycle.state.isTransitioning }

    var dailyTotals: [DailyTotal] {
        HistoryStore.dailyTotals(from: records)
    }

    var isHealthKitAvailable: Bool { healthKitWriter.isAvailable }

    var hasRunningPractice: Bool {
        lifecycle.state.blocksStarting
    }

    func startStandard(minutes: Int) async {
        guard (1...240).contains(minutes) else {
            alert = AppAlert(
                title: "Check the duration",
                message: "Choose a whole-number meditation from 1 through 240 minutes."
            )
            return
        }
        if guidanceMode == .guided, !GuidedProgramCatalog.supports(minutes: minutes) {
            alert = AppAlert(
                title: "Choose a guided sitting",
                message: "Guided practice is ready for 15, 30, 45, or 60 minutes. Switch to Silent for other durations."
            )
            return
        }

        guard let token = lifecycle.requestStart() else { return }
        let session = TimerEngine.startStandard(minutes: minutes, clock: .live)
        await begin(session, token: token, guidedMinutes: guidanceMode == .guided ? minutes : nil)
    }

    func startAwareness(hours: Int, intervalMinutes: Int) async {
        guard let token = lifecycle.requestStart() else { return }
        // No ceiling here: gongs come from the live audio session, not notifications.
        let validation = AwarenessPolicy.validate(
            hours: hours,
            intervalMinutes: intervalMinutes,
            maximumActions: nil
        )
        guard case let .success(configuration) = validation else {
            lifecycle.startFailed(token: token)
            if case let .failure(error) = validation {
                alert = AppAlert(
                    title: "Check the awareness schedule",
                    message: error.message
                )
            }
            return
        }
        let session = TimerEngine.startAwareness(configuration: configuration, clock: .live)
        await begin(session, token: token)
    }

    func endActivePractice() {
        guard let session = lifecycle.requestCancellation() else { return }
        let now = SessionClock.live

        if session.mode == .standard {
            let credited = TimerEngine.creditedDuration(for: session, at: now)
            // Sittings under one minute are noise, not practice; they are not logged.
            if credited >= 60 {
                addHistoryRecord(
                    MeditationRecord(
                        id: session.id,
                        plannedDuration: session.plannedDuration,
                        creditedDuration: credited,
                        meditationStartedAt: session.createdAt.addingTimeInterval(session.preparationDuration),
                        endedAt: now.wallDate,
                        completedAutomatically: false
                    )
                )
            }
        }

        persistState()
        sleepAssertion.end()
        guidedPlayer.stop()
        gongPlayer.stop()
        stopTicker()
        // Deferred so the cancelling state is observed before it resolves.
        Task {
            guard lifecycle.cancellationFinished(sessionID: session.id) else { return }
            persistState()
        }
    }

    func clearCompletion() {
        _ = lifecycle.clearCompletion()
        guidedPlayer.stop()
        gongPlayer.stop()
        route = .home
        persistState()
    }

    func saveLogRecord(_ record: MeditationRecord) {
        do {
            var edited = record
            // The editor sheet holds a snapshot; a Health export or Watch sync may have
            // marked the record saved since it opened, and that must not be undone.
            if let current = records.first(where: { $0.id == record.id }) {
                edited.healthKitSavedAt = current.healthKitSavedAt
            }
            edited.modifiedAt = Date()
            try historyStore.update(edited)
            reloadHistory()
            historySync.push()
            exportToHealthIfNeeded(edited)
        } catch {
            alert = AppAlert(
                title: "Meditation log unavailable",
                message: "The edit could not be saved: \(error.localizedDescription)"
            )
        }
    }

    func addLogRecord(endedAt: Date, durationMinutes: Int) {
        guard (1...1_440).contains(durationMinutes) else { return }
        let duration = TimeInterval(durationMinutes * 60)
        saveLogRecord(
            MeditationRecord(
                id: UUID(),
                plannedDuration: duration,
                creditedDuration: duration,
                meditationStartedAt: endedAt.addingTimeInterval(-duration),
                endedAt: endedAt,
                completedAutomatically: false
            )
        )
    }

    func deleteLogRecord(id: UUID) {
        do {
            try historyStore.delete(id: id)
            reloadHistory()
            historySync.push()
        } catch {
            alert = AppAlert(
                title: "Meditation log unavailable",
                message: "The session could not be deleted: \(error.localizedDescription)"
            )
        }
    }

    func setHealthKitEnabled(_ enabled: Bool) async {
        if enabled {
            do {
                try await healthKitWriter.requestWriteAuthorization()
                healthKitEnabled = true
                UserDefaults.standard.set(true, forKey: "healthKitEnabled")
                exportUnsavedRecordsToHealth()
            } catch {
                healthKitEnabled = false
                UserDefaults.standard.set(false, forKey: "healthKitEnabled")
                alert = AppAlert(
                    title: "Health access unavailable",
                    message: error.localizedDescription
                )
            }
        } else {
            healthKitEnabled = false
            UserDefaults.standard.set(false, forKey: "healthKitEnabled")
        }
    }

    func reconcile() {
        guard let session = activeSession else { return }
        clock = .live
        let currentSnapshot = TimerEngine.snapshot(for: session, at: clock)
        if currentSnapshot.phase == .completed {
            finish(session, at: clock.wallDate)
        }
    }

    func handlePracticeURL(_ url: URL) {
        switch PracticeURLParser.parse(url) {
        case let .sit(minutes):
            route = .home
            Task { await startStandard(minutes: minutes) }
        case let .awareness(hours, intervalMinutes):
            route = .awareness
            Task { await startAwareness(hours: hours, intervalMinutes: intervalMinutes) }
        case nil:
            break
        }
    }

    private func begin(_ session: ActiveSession, token: UUID, guidedMinutes: Int? = nil) async {
        do {
            if let guidedMinutes {
                try await guidedPlayer.start(session: session, minutes: guidedMinutes)
            } else {
                try gongPlayer.start(session: session)
            }
            guard lifecycle.startSucceeded(token: token, session: session) else {
                guidedPlayer.stop()
                gongPlayer.stop()
                return
            }
            route = session.mode == .awareness ? .awareness : .home
            startTicker()
            clock = .live
            persistState()
            sleepAssertion.begin()
        } catch {
            guidedPlayer.stop()
            gongPlayer.stop()
            guard lifecycle.startFailed(token: token) else { return }
            alert = AppAlert(
                title: guidedMinutes == nil ? "Unable to start the gongs" : "Guided audio unavailable",
                message: error.localizedDescription
            )
        }
    }

    private func startTicker() {
        guard ticker == nil else { return }
        ticker = Timer.publish(every: 1, tolerance: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.reconcile()
            }
    }

    private func stopTicker() {
        ticker = nil
    }

    private func observeAppIntents() {
        NotificationCenter.default.publisher(for: .startMeditationIntent)
            .sink { [weak self] notification in
                let minutes = notification.userInfo?["minutes"] as? Int ?? 60
                Task { @MainActor in
                    self?.route = .home
                    await self?.startStandard(minutes: minutes)
                }
            }
            .store(in: &intentCancellables)
    }

    private func finish(_ session: ActiveSession, at _: Date) {
        guard lifecycle.complete(session: session) != nil else { return }
        if session.mode == .standard {
            addHistoryRecord(
                MeditationRecord(
                    id: session.id,
                    plannedDuration: session.plannedDuration,
                    creditedDuration: session.plannedDuration,
                    meditationStartedAt: session.createdAt.addingTimeInterval(session.preparationDuration),
                    endedAt: session.expectedEndDate,
                    completedAutomatically: true
                )
            )
        }
        persistState()
        sleepAssertion.end()
        stopTicker()
    }

    private func addHistoryRecord(_ record: MeditationRecord) {
        do {
            _ = try historyStore.add(record)
            reloadHistory()
            historySync.push()
            exportToHealthIfNeeded(record)
        } catch {
            alert = AppAlert(
                title: "Meditation log unavailable",
                message: "The session finished, but its local record could not be saved: \(error.localizedDescription)"
            )
        }
    }

    private func restore() {
        reloadHistory()
        do {
            let state = try sessionStore.load()
            lifecycle.restore(activeSession: state.activeSession, completion: state.completion)
            if activeSession != nil {
                sleepAssertion.begin()
            }
            reconcile()
        } catch {
            alert = AppAlert(
                title: "Timer state could not be restored",
                message: "The saved active timer was unreadable and has not been resumed."
            )
        }
    }

    private func reloadHistory() {
        let result = historyStore.load()
        records = result.records
        historyHadUnreadableEntries = result.hadUnreadableEntries
        monthSections = LogPresentation.monthSections(from: result.records)
        practicedDays = HistoryStore.dailyTotals(from: result.records)
    }

    private func historyDidSync() {
        reloadHistory()
        exportUnsavedRecordsToHealth()
    }

    private func restoreHealthKitExport() {
        guard healthKitEnabled else { return }
        guard healthKitWriter.hasWriteAuthorization else {
            healthKitEnabled = false
            UserDefaults.standard.set(false, forKey: "healthKitEnabled")
            return
        }
        exportUnsavedRecordsToHealth()
    }

    private func exportUnsavedRecordsToHealth() {
        guard healthKitEnabled else { return }
        records.filter { $0.healthKitSavedAt == nil }.forEach(exportToHealthIfNeeded)
    }

    private func exportToHealthIfNeeded(_ record: MeditationRecord) {
        guard healthKitEnabled,
              record.healthKitSavedAt == nil,
              healthExportsInFlight.insert(record.id).inserted else { return }
        Task { [weak self] in
            guard let self else { return }
            defer { healthExportsInFlight.remove(record.id) }
            do {
                try await healthKitWriter.saveMindfulSession(record)
            } catch {
                alert = AppAlert(
                    title: "Health export unavailable",
                    message: "The session remains safely in your local log. \(error.localizedDescription)"
                )
                return
            }

            do {
                if try historyStore.markHealthKitSaved(id: record.id, at: Date()) {
                    reloadHistory()
                    historySync.push()
                }
            } catch {
                alert = AppAlert(
                    title: "Health export status not saved",
                    message: "The Mindful Minutes entry was added to Health, but the local confirmation could not be stored. \(error.localizedDescription)"
                )
            }
        }
    }

    private func persistState() {
        do {
            try sessionStore.save(
                PersistedSessionState(activeSession: activeSession, completion: completion)
            )
        } catch {
            alert = AppAlert(
                title: "Timer state could not be saved",
                message: "Keep the app open for this session. Recovery after relaunch is not currently available."
            )
        }
    }

    #if DEBUG
    private func applyDebugRouteArgument() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let keyIndex = arguments.firstIndex(of: "-VTPreviewRoute"),
              arguments.indices.contains(keyIndex + 1),
              let previewRoute = AppRoute(rawValue: arguments[keyIndex + 1]) else {
            return
        }
        lifecycle = PracticeLifecycle()
        route = previewRoute
    }
    #endif
}
