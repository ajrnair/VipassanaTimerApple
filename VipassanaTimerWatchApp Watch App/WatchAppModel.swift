import Combine
import AVFoundation
import Foundation
import WatchKit

struct WatchAlert: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var message: String
}

@MainActor
final class WatchAppModel: ObservableObject {
    @Published private(set) var lifecycle = PracticeLifecycle()
    // Not @Published: the ticker below updates this 4x/second so cue timing
    // stays precise, but a full-object republish at that rate forced every
    // running screen to relayout its gradient field and aperture ring 4x/sec,
    // which read as laggy on real Watch hardware — the displayed clock only
    // changes once a second anyway. reconcile() below sends the redraw
    // manually, throttled to once per whole second.
    private(set) var clock = SessionClock.live
    @Published private(set) var records: [MeditationRecord] = []
    @Published private(set) var historyHadUnreadableEntries = false
    @Published var alert: WatchAlert?

    private let historyStore: HistoryStore
    private let sessionStore: SessionStore
    private lazy var historySync = HistorySyncService(store: historyStore) { [weak self] in
        self?.reloadHistory()
    }
    private let cuePlayer = WatchCuePlayer()
    private var ticker: AnyCancellable?
    private var lastElapsed: TimeInterval?
    private var lastPublishedSecond: Int?

    init(
        historyStore: HistoryStore? = nil,
        sessionStore: SessionStore? = nil
    ) {
        self.historyStore = historyStore ?? HistoryStore()
        self.sessionStore = sessionStore ?? SessionStore()
        restore()
        #if DEBUG
        let isPreviewSession = applyDebugSessionArgument()
        #else
        let isPreviewSession = false
        #endif
        if activeSession != nil {
            startTicker()
        }
        historySync.activate()
        if activeSession != nil, !isPreviewSession {
            try? cuePlayer.startSession()
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

    func startStandard(minutes: Int) async {
        guard (1...240).contains(minutes), let token = lifecycle.requestStart() else { return }
        await begin(TimerEngine.startStandard(minutes: minutes, clock: .live), token: token)
    }

    func startAwareness(hours: Int, intervalMinutes: Int) async {
        guard let token = lifecycle.requestStart() else { return }
        let validation = AwarenessPolicy.validate(hours: hours, intervalMinutes: intervalMinutes)
        guard case let .success(configuration) = validation else {
            lifecycle.startFailed(token: token)
            if case let .failure(error) = validation {
                alert = WatchAlert(title: "Check the schedule", message: error.message)
            }
            return
        }
        await begin(
            TimerEngine.startAwareness(configuration: configuration, clock: .live),
            token: token
        )
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

        lastElapsed = nil
        persistState()
        stopTicker()
        cuePlayer.stopSession()
        guard lifecycle.cancellationFinished(sessionID: session.id) else { return }
        persistState()
    }

    func clearCompletion() {
        _ = lifecycle.clearCompletion()
        cuePlayer.stopSession()
        persistState()
    }

    func reconcile() {
        guard let session = activeSession else { return }
        clock = .live

        let elapsed = TimerEngine.elapsed(for: session, at: clock)
        if let lastElapsed {
            let events = TimerEngine.eventsCrossed(
                for: session,
                from: lastElapsed,
                through: elapsed
            )
            events.forEach(playCue)
        }
        lastElapsed = elapsed

        if TimerEngine.snapshot(for: session, at: clock).phase == .completed {
            finish(session, at: clock.wallDate)
            return
        }

        publishTickIfNeeded(elapsed: elapsed)
    }

    /// The ticker drives `reconcile()` 4x/second so gong cues land close to
    /// their exact boundary, but every visible readout (countdown, ring
    /// progress) only changes once a second — so the redraw is throttled to
    /// match what's actually on screen.
    private func publishTickIfNeeded(elapsed: TimeInterval) {
        let wholeSecond = Int(elapsed)
        guard wholeSecond != lastPublishedSecond else { return }
        lastPublishedSecond = wholeSecond
        objectWillChange.send()
    }

    func resumeFromBackground() {
        clock = .live
        guard let session = activeSession else { return }
        let elapsed = TimerEngine.elapsed(for: session, at: clock)
        lastElapsed = elapsed
        lastPublishedSecond = Int(elapsed)
        objectWillChange.send()
        if TimerEngine.snapshot(for: session, at: clock).phase == .completed {
            finish(session, at: session.expectedEndDate)
        }
    }

    func handlePracticeURL(_ url: URL) {
        switch PracticeURLParser.parse(url) {
        case let .sit(minutes):
            Task { await startStandard(minutes: minutes) }
        case let .awareness(hours, intervalMinutes):
            Task { await startAwareness(hours: hours, intervalMinutes: intervalMinutes) }
        case .awarenessRandom:
            // The Watch does not offer random Awareness yet: its inactive-state
            // gong path schedules notifications against the 64-action cap, and
            // that budget has not been worked out for a drawn schedule.
            break
        case nil:
            break
        }
    }

    private func begin(_ session: ActiveSession, token: UUID) async {
        do {
            try cuePlayer.startSession()
            guard lifecycle.startSucceeded(token: token, session: session) else {
                cuePlayer.stopSession()
                return
            }
            clock = .live
            lastElapsed = 0
            lastPublishedSecond = 0
            startTicker()
            persistState()
        } catch {
            cuePlayer.stopSession()
            guard lifecycle.startFailed(token: token) else { return }
            alert = WatchAlert(
                title: "Unable to start the gongs",
                message: error.localizedDescription
            )
        }
    }

    private func startTicker() {
        guard ticker == nil else { return }
        // 0.25 s while active: this ticker also drives the in-app gong cues.
        ticker = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.reconcile()
            }
    }

    private func stopTicker() {
        ticker = nil
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

        lastElapsed = nil
        persistState()
        stopTicker()
        // The completion gong is still sounding, so the session is released only
        // once it has finished rather than cut off mid-strike.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(13))
            guard self?.activeSession == nil else { return }
            self?.cuePlayer.stopSession()
        }
    }

    private func playCue(_ event: TimerEvent) {
        switch event {
        case .meditationStarted:
            WKInterfaceDevice.current().play(.start)
            cuePlayer.play(filename: "gong_start", extension: "caf")
        case .awarenessInterval:
            WKInterfaceDevice.current().play(.notification)
            cuePlayer.play(filename: "gong_start", extension: "caf")
        case .completed:
            WKInterfaceDevice.current().play(.success)
            cuePlayer.play(filename: "gong_end_triple", extension: "caf")
        }
    }

    private func addHistoryRecord(_ record: MeditationRecord) {
        do {
            _ = try historyStore.add(record)
            reloadHistory()
            historySync.push()
        } catch {
            alert = WatchAlert(
                title: "Log unavailable",
                message: "The sitting ended, but its local record could not be saved."
            )
        }
    }

    private func restore() {
        reloadHistory()
        do {
            let state = try sessionStore.load()
            lifecycle.restore(activeSession: state.activeSession, completion: state.completion)
            if let activeSession {
                clock = .live
                lastElapsed = TimerEngine.elapsed(for: activeSession, at: clock)
            }
            reconcile()
        } catch {
            alert = WatchAlert(
                title: "Timer not restored",
                message: "The saved timer was unreadable and has not been resumed."
            )
        }
    }

    private func reloadHistory() {
        let result = historyStore.load()
        records = result.records
        historyHadUnreadableEntries = result.hadUnreadableEntries
    }

    private func persistState() {
        do {
            try sessionStore.save(
                PersistedSessionState(activeSession: activeSession, completion: completion)
            )
        } catch {
            alert = WatchAlert(
                title: "Timer not saved",
                message: "Keep the app open for this session; recovery after relaunch is unavailable."
            )
        }
    }

    #if DEBUG
    @discardableResult
    private func applyDebugSessionArgument() -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard let keyIndex = arguments.firstIndex(of: "-VTPreviewSession"),
              arguments.indices.contains(keyIndex + 1) else {
            return false
        }

        lifecycle = PracticeLifecycle()
        clock = .live
        switch arguments[keyIndex + 1] {
        case "preparing":
            lifecycle = PracticeLifecycle(state: .active(TimerEngine.startStandard(minutes: 30, clock: clock)))
        case "standard":
            var session = TimerEngine.startStandard(minutes: 30, clock: clock)
            let elapsed = session.preparationDuration + 60
            session.anchorUptime -= elapsed
            session.createdAt = session.createdAt.addingTimeInterval(-elapsed)
            lifecycle = PracticeLifecycle(state: .active(session))
        case "awareness":
            let configuration = AwarenessConfiguration(hours: 8, intervalMinutes: 10)
            var session = TimerEngine.startAwareness(configuration: configuration, clock: clock)
            session.anchorUptime -= 60
            session.createdAt = session.createdAt.addingTimeInterval(-60)
            lifecycle = PracticeLifecycle(state: .active(session))
        case "completion":
            lifecycle = PracticeLifecycle(state: .completed(CompletionPresentation(
                sessionID: UUID(),
                mode: .standard,
                duration: 30 * 60,
                completedAt: clock.wallDate
            )))
        default:
            return false
        }

        if let activeSession {
            lastElapsed = TimerEngine.elapsed(for: activeSession, at: clock)
        }
        return true
    }
    #endif
}

@MainActor
/// Gongs are app audio on the watch too, for the reason they are on the phone:
/// a notification is silenced by the Silent switch and by a Focus, which is
/// exactly when someone is sitting. A live playback session also keeps the app
/// running once the wrist drops, so the ticker that sounds each cue keeps
/// firing — the watch's own reason for needing this, since it suspends far more
/// eagerly than a phone.
private final class WatchCuePlayer {
    private var player: AVAudioPlayer?
    private var silence: AVAudioPlayer?

    func startSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        silence = try? AVAudioPlayer(data: Self.silenceWAV)
        silence?.numberOfLoops = -1
        silence?.volume = 0
        silence?.play()
    }

    func stopSession() {
        silence?.stop()
        silence = nil
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }

    func play(filename: String, extension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            player = nil
        }
    }

    /// Ten seconds of 8 kHz mono silence, built in memory so the keep-alive
    /// needs no bundled asset.
    private static let silenceWAV: Data = {
        let sampleRate: UInt32 = 8_000
        let dataSize = sampleRate * 10 * 2
        var data = Data("RIFF".utf8)
        func append<T: FixedWidthInteger>(_ value: T) {
            var encoded = value.littleEndian
            withUnsafeBytes(of: &encoded) { data.append(contentsOf: $0) }
        }
        append(UInt32(36 + dataSize))
        data.append(contentsOf: Data("WAVEfmt ".utf8))
        append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(sampleRate); append(sampleRate * 2); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Data("data".utf8))
        append(dataSize)
        data.append(Data(count: Int(dataSize)))
        return data
    }()
}
