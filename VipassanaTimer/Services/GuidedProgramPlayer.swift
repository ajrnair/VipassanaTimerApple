import AVFoundation
import Foundation

#if os(iOS)
import MediaPlayer
#endif

@MainActor
final class GuidedProgramPlayer {
    enum PlaybackError: LocalizedError {
        case missingProgram(Int)

        var errorDescription: String? {
            switch self {
            case let .missingProgram(minutes):
                "The \(minutes)-minute guided audio is missing from this build."
            }
        }
    }

    private var player: AVPlayer?
    private var session: ActiveSession?
    private var observers: [NSObjectProtocol] = []

    #if os(iOS)
    private var playCommandTarget: Any?
    private var pauseCommandTarget: Any?
    #endif

    init() {
        observeAudioLifecycle()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func start(session: ActiveSession, minutes: Int) async throws {
        stop()
        guard let resourceName = GuidedProgramCatalog.fileName(minutes: minutes),
              let url = Bundle.main.url(forResource: resourceName, withExtension: "m4a") else {
            throw PlaybackError.missingProgram(minutes)
        }

        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [])
        try audioSession.setActive(true)
        #endif

        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        self.session = session
        configureRemoteCommands()
        updateNowPlaying(minutes: minutes, elapsed: 0)

        let elapsed = max(0, Date().timeIntervalSince(session.createdAt))
        await seek(player, to: elapsed)
        updateNowPlaying(minutes: minutes, elapsed: elapsed)
        player.playImmediately(atRate: 1)
    }

    func stop() {
        player?.pause()
        player = nil
        session = nil
        clearRemoteCommands()
        #if os(iOS)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
        #endif
    }

    func isPlaying(sessionID: UUID) -> Bool {
        session?.id == sessionID && player?.rate != 0
    }

    private func observeAudioLifecycle() {
        let center = NotificationCenter.default
        #if os(iOS)
        observers.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    await self?.handleInterruption(notification)
                }
            }
        )
        observers.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    await self?.handleRouteChange(notification)
                }
            }
        )
        #endif
        observers.append(
            center.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                Task { @MainActor in
                    guard notification.object as? AVPlayerItem === self?.player?.currentItem else {
                        return
                    }
                    self?.stop()
                }
            }
        )
    }

    #if os(iOS)
    private func handleInterruption(_ notification: Notification) async {
        guard let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }

        switch type {
        case .began:
            await pauseAndCoverGongs()
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if options.contains(.shouldResume) {
                await resumeAtLiveOffset()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) async {
        guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable else {
            return
        }
        await pauseAndCoverGongs()
    }
    #endif

    private func pauseAndCoverGongs() async {
        guard session != nil else { return }
        player?.pause()
        updatePlaybackRate(0)
    }

    private func resumeAtLiveOffset() async {
        guard let session, let player else { return }
        // The timer measures elapsed time against monotonic uptime, so a wall
        // clock change mid-sitting must not move the voice either.
        let elapsed = max(0, TimerEngine.elapsed(for: session, at: .live))
        await seek(player, to: elapsed)
        player.playImmediately(atRate: 1)
        updatePlaybackRate(1, elapsed: elapsed)
    }

    private func seek(_ player: AVPlayer, to seconds: TimeInterval) async {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        await withCheckedContinuation { continuation in
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                continuation.resume()
            }
        }
    }

    private func configureRemoteCommands() {
        #if os(iOS)
        let commands = MPRemoteCommandCenter.shared()
        commands.nextTrackCommand.isEnabled = false
        commands.previousTrackCommand.isEnabled = false
        commands.skipForwardCommand.isEnabled = false
        commands.skipBackwardCommand.isEnabled = false
        commands.changePlaybackPositionCommand.isEnabled = false
        commands.playCommand.isEnabled = true
        commands.pauseCommand.isEnabled = true
        playCommandTarget = commands.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in await self?.resumeAtLiveOffset() }
            return .success
        }
        pauseCommandTarget = commands.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in await self?.pauseAndCoverGongs() }
            return .success
        }
        #endif
    }

    private func clearRemoteCommands() {
        #if os(iOS)
        let commands = MPRemoteCommandCenter.shared()
        if let playCommandTarget {
            commands.playCommand.removeTarget(playCommandTarget)
        }
        if let pauseCommandTarget {
            commands.pauseCommand.removeTarget(pauseCommandTarget)
        }
        playCommandTarget = nil
        pauseCommandTarget = nil
        #endif
    }

    private func updateNowPlaying(minutes: Int, elapsed: TimeInterval) {
        #if os(iOS)
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Guided meditation",
            MPMediaItemPropertyAlbumTitle: "Vipassana Timer",
            MPMediaItemPropertyPlaybackDuration: TimeInterval(minutes * 60 + 90),
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: 1
        ]
        if let artwork = Self.lockScreenArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        #endif
    }

    #if os(iOS)
    /// Without this the Lock Screen leaves an empty square where the artwork belongs. Built once:
    /// `MPMediaItemArtwork` asks for the image again at several sizes, and decoding the icon each
    /// time during a sitting would be work for nothing.
    private static let lockScreenArtwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "NowPlayingArtwork") else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }()
    #endif

    private func updatePlaybackRate(_ rate: Float, elapsed: TimeInterval? = nil) {
        #if os(iOS)
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        if let elapsed {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        #endif
    }
}
