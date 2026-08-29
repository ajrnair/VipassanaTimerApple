#if DEBUG && os(iOS)
import Foundation
import MetricKit
import UIKit

/// The overnight battery test, automated down to "start a session and sleep".
///
/// Awareness is awake all night by design — its audio session keeps the app
/// running — so the app can sample its own battery while the measurement runs.
/// Every ten minutes, and at session start, end, and interruption, one line is
/// appended to a local JSON journal: timestamp, battery percentage, charging
/// state, thermal state. In the morning the whole drain curve is on disk, and
/// About (debug builds only) shows the last session's summary.
///
/// MetricKit's daily payloads — cumulative CPU time and friends, the *why*
/// behind a bad number — are saved beside it. Nothing here ever leaves the
/// device, and the whole file is compiled out of Release: the store build
/// contains none of this, which keeps both the privacy story and the review
/// story exactly as simple as they were.
///
/// Procedure and thresholds: `docs/awareness-battery-measurement.md`.
@MainActor
final class BatteryJournal: NSObject {
    static let shared = BatteryJournal()

    struct Entry: Codable {
        let at: Date
        let event: String
        let batteryPercent: Int
        let charging: Bool
        let thermal: String
        let session: String?
    }

    private static let sampleInterval: TimeInterval = 10 * 60
    private var timer: Timer?
    private var sessionDescription: String?

    /// Called once at launch: turns battery monitoring on and subscribes to
    /// MetricKit's daily payloads.
    func activate() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        MXMetricManager.shared.add(self)
    }

    func sessionBegan(_ description: String) {
        sessionDescription = description
        append(event: "begin")
        timer = Timer.scheduledTimer(withTimeInterval: Self.sampleInterval, repeats: true) { _ in
            Task { @MainActor in BatteryJournal.shared.append(event: "sample") }
        }
    }

    func sessionEnded(_ reason: String) {
        guard sessionDescription != nil else { return }
        append(event: reason)
        timer?.invalidate()
        timer = nil
        sessionDescription = nil
    }

    // MARK: - Journal

    private func append(event: String) {
        let device = UIDevice.current
        let thermal: String
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = "nominal"
        case .fair: thermal = "fair"
        case .serious: thermal = "serious"
        case .critical: thermal = "critical"
        @unknown default: thermal = "unknown"
        }
        let entry = Entry(
            at: Date(),
            event: event,
            batteryPercent: Int((device.batteryLevel * 100).rounded()),
            charging: device.batteryState == .charging || device.batteryState == .full,
            thermal: thermal,
            session: sessionDescription
        )
        var entries = load()
        entries.append(entry)
        // A season of nightly runs, not an unbounded file.
        if entries.count > 5_000 { entries.removeFirst(entries.count - 5_000) }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(entries) {
            try? data.write(to: Self.journalURL, options: .atomic)
        }
    }

    func load() -> [Entry] {
        guard let data = try? Data(contentsOf: Self.journalURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Entry].self, from: data)) ?? []
    }

    /// "8h random · 100% → 89% · 1.4%/h · thermals nominal" — the number the
    /// measurement doc asks for, computed from the last begin…end span.
    func lastSessionSummary() -> String? {
        let entries = load()
        guard let beginIndex = entries.lastIndex(where: { $0.event == "begin" }) else { return nil }
        let span = Array(entries[beginIndex...])
        guard let first = span.first, let last = span.last, span.count >= 2 else { return nil }

        let hours = last.at.timeIntervalSince(first.at) / 3_600
        guard hours > 0.01 else { return nil }
        let drop = first.batteryPercent - last.batteryPercent
        let perHour = Double(drop) / hours
        let charged = span.contains { $0.charging }
        let worstThermal = span.contains { $0.thermal != "nominal" } ? "thermals ran warm" : "thermals nominal"

        var parts = [
            first.session ?? "session",
            String(format: "%.1f h", hours),
            "\(first.batteryPercent)% → \(last.batteryPercent)%",
            String(format: "%.1f%%/h", perHour),
            worstThermal
        ]
        if charged { parts.append("⚠️ was on power — run void") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Files

    private static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VipassanaTimer", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    private static var journalURL: URL {
        directoryURL.appendingPathComponent("battery-journal.json")
    }
}

extension BatteryJournal: MXMetricManagerSubscriber {
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VipassanaTimer/metrickit", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: Date())
        for (index, payload) in payloads.enumerated() {
            let url = directory.appendingPathComponent("payload-\(stamp)-\(index).json")
            try? payload.jsonRepresentation().write(to: url, options: .atomic)
        }
    }
}
#endif
