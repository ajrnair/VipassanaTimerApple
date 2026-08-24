import AVFoundation
import Foundation

/// Plays every session gong — sittings and awareness alike — as ordinary app audio from a
/// live playback session, so gongs follow the active output route (AirPods when connected,
/// otherwise the speaker) and are unaffected by the Silent switch, Focus, or notification
/// settings — locked or unlocked. A zero-volume loop keeps the session, and therefore the
/// timeline, running between gongs; the audible content is the gongs the user asked for.
/// The app schedules no notifications.
@MainActor
final class PracticeGongPlayer {
    private var session: ActiveSession?
    private var silencePlayer: AVAudioPlayer?
    private var cuePlayer: AVAudioPlayer?
    private var ticker: Timer?
    private var lastElapsed: TimeInterval = 0
    private var observers: [NSObjectProtocol] = []

    init() {
        #if os(iOS)
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in self?.handleInterruption(notification) }
            }
        )
        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.resumeSilenceIfNeeded() }
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
        lastElapsed = TimerEngine.elapsed(for: session, at: .live)
        startSilenceLoop()

        let ticker = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        ticker.tolerance = 0.2
        RunLoop.main.add(ticker, forMode: .common)
        self.ticker = ticker
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        silencePlayer?.stop()
        silencePlayer = nil
        cuePlayer?.stop()
        cuePlayer = nil
        session = nil
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        #endif
    }

    private func tick() {
        guard let session else { return }
        let elapsed = TimerEngine.elapsed(for: session, at: .live)
        let events = TimerEngine.eventsCrossed(for: session, from: lastElapsed, through: elapsed)
        lastElapsed = elapsed

        // Several boundaries crossed at once (after an interruption) sound one gong, not a burst.
        if events.contains(.completed) {
            playCue(named: "gong_end_triple")
            finishAfterCompletionCue()
        } else if events.contains(where: { event in
            switch event {
            case .meditationStarted, .warning, .awarenessInterval:
                return true
            case .completed:
                return false
            }
        }) {
            playCue(named: "gong_start")
        } else if elapsed > session.totalTimelineDuration + 15 {
            // Completion passed while audio was interrupted; nothing left to sound.
            stop()
        }
    }

    private func playCue(named name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else { return }
        cuePlayer = try? AVAudioPlayer(contentsOf: url)
        cuePlayer?.play()
    }

    private func finishAfterCompletionCue() {
        ticker?.invalidate()
        ticker = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(13))
            self?.stop()
        }
    }

    private func startSilenceLoop() {
        silencePlayer = try? AVAudioPlayer(data: Self.silenceWAV)
        silencePlayer?.numberOfLoops = -1
        silencePlayer?.volume = 0
        silencePlayer?.play()
    }

    private func resumeSilenceIfNeeded() {
        guard session != nil else { return }
        guard silencePlayer?.isPlaying != true else { return }
        if silencePlayer?.play() != true {
            startSilenceLoop()
        }
    }

    #if os(iOS)
    private func handleInterruption(_ notification: Notification) {
        guard session != nil,
              let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: rawType) == .ended else { return }
        // Boundaries that fell inside the interruption are skipped; a late gong helps no one.
        if let session {
            lastElapsed = TimerEngine.elapsed(for: session, at: .live)
        }
        try? AVAudioSession.sharedInstance().setActive(true)
        resumeSilenceIfNeeded()
    }
    #endif

    /// Ten seconds of 8 kHz mono 16-bit silence as an in-memory WAV, so the keep-alive loop
    /// needs no bundled asset.
    private static let silenceWAV: Data = {
        let sampleRate: UInt32 = 8_000
        let seconds: UInt32 = 10
        let dataSize = sampleRate * seconds * 2

        var data = Data("RIFF".utf8)
        func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
            var encoded = value.littleEndian
            withUnsafeBytes(of: &encoded) { data.append(contentsOf: $0) }
        }
        appendLittleEndian(UInt32(36 + dataSize))
        data.append(contentsOf: Data("WAVEfmt ".utf8))
        appendLittleEndian(UInt32(16))
        appendLittleEndian(UInt16(1)) // PCM
        appendLittleEndian(UInt16(1)) // mono
        appendLittleEndian(sampleRate)
        appendLittleEndian(sampleRate * 2)
        appendLittleEndian(UInt16(2))
        appendLittleEndian(UInt16(16))
        data.append(contentsOf: Data("data".utf8))
        appendLittleEndian(dataSize)
        data.append(Data(count: Int(dataSize)))
        return data
    }()
}
