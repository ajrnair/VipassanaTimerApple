import AVFoundation
import Foundation

/// Plays a sitting's gongs as ordinary app audio, so they follow the active output route
/// (headphones when connected, otherwise the speaker) and arrive whether the screen is locked
/// or dark, unaffected by the Silent switch or a Focus. The app schedules no notifications.
///
/// Every gong for the whole sitting is scheduled onto one audio player the moment the session
/// starts, at a sample-accurate offset. Nothing is played to keep the app awake and no silent
/// asset exists: the session holds a single running player whose content is the gongs the user
/// asked for, and the quiet between them is simply the gaps in that content. Timing does not
/// depend on the app receiving a callback, which is the same guarantee the timer core makes.
@MainActor
final class PracticeGongPlayer {
    private var session: ActiveSession?
    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?
    private var observers: [NSObjectProtocol] = []
    private var teardown: Task<Void, Never>?

    init() {
        #if os(iOS)
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) {
                [weak self] notification in
                Task { @MainActor in self?.handleInterruption(notification) }
            }
        )
        observers.append(
            center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) {
                [weak self] _ in
                Task { @MainActor in self?.restartForCurrentRoute() }
            }
        )
        #endif
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    var isActive: Bool { session != nil }

    func start(session: ActiveSession) throws {
        stop()
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)
        #endif
        self.session = session
        try schedule(for: session)
    }

    func stop() {
        teardown?.cancel()
        teardown = nil
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        session = nil
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    // MARK: - Scheduling

    /// Lays the whole remaining sitting onto one player. A session recovered mid-flight skips
    /// the boundaries that already passed, so relaunching never replays a gong.
    ///
    /// One constraint this design carries: a player node renders its scheduled buffers as a
    /// queue, so two gongs closer together than the length of a gong would play back to back
    /// rather than at their own offsets. Every boundary the engine produces is minutes apart —
    /// the closest possible is a one-minute awareness interval against a four-second gong — so
    /// this never binds in practice, but a shorter cue spacing would need overlapping players.
    private func schedule(for session: ActiveSession) throws {
        guard let start = Self.buffer(named: "gong_start"),
              let completion = Self.buffer(named: "gong_end_triple") else {
            throw GongError.assetsUnavailable
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let format = start.format
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
        try engine.start()

        let rate = format.sampleRate
        let elapsed = TimerEngine.elapsed(for: session, at: .live)
        var lastOffset: TimeInterval = 0

        for event in TimerEngine.timelineEvents(for: session) {
            let delay = event.timelineOffset - elapsed
            guard delay >= 0 else { continue }
            let buffer = event.event == .completed ? completion : start
            let at = AVAudioTime(sampleTime: AVAudioFramePosition(delay * rate), atRate: rate)
            player.scheduleBuffer(buffer, at: at, options: [], completionCallbackType: .dataPlayedBack) { _ in }
            lastOffset = max(lastOffset, delay + Double(buffer.frameLength) / rate)
        }

        player.play()
        self.engine = engine
        self.player = player

        // The session is released once the last gong has finished sounding, rather than left
        // open for a timeline that has nothing further to play.
        teardown = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(max(1, lastOffset) + 1))
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    private static func buffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(
                  pcmFormat: file.processingFormat,
                  frameCapacity: AVAudioFrameCount(file.length)
              ),
              (try? file.read(into: buffer)) != nil else { return nil }
        return buffer
    }

    private enum GongError: LocalizedError {
        case assetsUnavailable
        var errorDescription: String? { "The gong recordings could not be loaded." }
    }

    // MARK: - Staying correct through interruptions and route changes

    /// A phone call or a switch to CarPlay tears the graph down. Rebuilding from the session's
    /// absolute timeline re-scheduling only what is still ahead keeps the remaining gongs on
    /// time; boundaries that fell inside the interruption are skipped, because a late gong
    /// helps no one.
    private func rebuild() {
        guard let session else { return }
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        try? schedule(for: session)
    }

    #if os(iOS)
    private func handleInterruption(_ notification: Notification) {
        guard session != nil,
              let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .ended else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        rebuild()
    }

    private func restartForCurrentRoute() {
        guard session != nil, engine?.isRunning != true else { return }
        rebuild()
    }
    #endif
}
