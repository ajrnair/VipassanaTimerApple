import Foundation

/// The random gong schedule for Awareness.
///
/// The user chooses only the hours; the app decides the moments. Each gap is
/// drawn uniformly from a range derived from the session length, so a short
/// practice is visited often and a day-long one is not nagged — and because
/// the bell cannot be anticipated, the mind does not count down to it.
///
/// The whole schedule is drawn **once, at start**, and persisted with the
/// session (`ActiveSession.gongOffsets`). Everything downstream —
/// `TimerEngine.timelineEvents`, the audio player's rebuild after an
/// interruption, a relaunch restoring from disk — replays the identical
/// offsets. Determinism lives in the persisted state, not in a seed, so no
/// change of algorithm or platform can silently reshuffle a running session.
public enum AwarenessScheduler {
    /// The floor also respects the gong player's constraint: buffers queue on
    /// one player node, so cues must be spaced further apart than a gong is
    /// long. Five minutes is far above that line.
    public static let minimumGap: TimeInterval = 5 * 60
    public static let maximumGap: TimeInterval = 40 * 60

    /// The gap range for a session of this length: 1/24th to 1/12th of the
    /// session, clamped so gaps never fall under 5 minutes or stretch past 40.
    /// 1 h → 5–10 min, 4 h → 10–20, 8 h → 20–40, 24 h → 20–40.
    public static func randomBounds(
        totalSeconds: TimeInterval
    ) -> (minimum: TimeInterval, maximum: TimeInterval) {
        let minimum = min(max(totalSeconds / 24, minimumGap), maximumGap / 2)
        let maximum = min(max(totalSeconds / 12, minimumGap * 2), maximumGap)
        return (minimum, max(minimum, maximum))
    }

    /// The materialized schedule: cumulative offsets from the timeline start,
    /// strictly increasing, all before `totalSeconds` — the completion gongs
    /// own the end, exactly as they do on the fixed grid.
    public static func gongOffsets(
        totalSeconds: TimeInterval,
        using rng: inout some RandomNumberGenerator
    ) -> [TimeInterval] {
        guard totalSeconds > 0 else { return [] }
        let bounds = randomBounds(totalSeconds: totalSeconds)
        var offsets: [TimeInterval] = []
        var offset: TimeInterval = 0
        while true {
            let gap = TimeInterval(Int.random(
                in: Int(bounds.minimum)...Int(bounds.maximum),
                using: &rng
            ))
            offset += gap
            guard offset < totalSeconds else { break }
            offsets.append(offset)
        }
        return offsets
    }
}
