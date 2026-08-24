import SwiftUI

/// The watch is not a small phone. What it owes a sitter is: start quickly,
/// show the time left at a glance, and end. So the first screen is the choice
/// itself rather than a title above a menu — the ring carries the duration, the
/// crown changes it, and the presets are one tap. Everything that needs reading
/// or configuring at length stays on the phone.
struct WatchHomeView: View {
    @ObservedObject var model: WatchAppModel

    @AppStorage("lastWatchSitMinutes") private var minutes = 30
    @State private var crown = 30.0

    private let presets = [15, 30, 45, 60]

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    WatchApertureRing(
                        timeText: "\(minutes)",
                        caption: "minutes",
                        numeralFraction: 0.34
                    )
                    .frame(width: WatchMetrics.ring(0.36), height: WatchMetrics.ring(0.36))
                    .focusable(true)
                .digitalCrownRotation(
                    $crown,
                    from: 1,
                    through: 240,
                    by: 1,
                    sensitivity: .low,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                    .onChange(of: crown) { _, value in
                        minutes = min(240, max(1, Int(value.rounded())))
                    }
                    .onAppear { crown = Double(minutes) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Sitting length")
                    .accessibilityValue("\(minutes) minutes")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: minutes = min(240, minutes + 5)
                        case .decrement: minutes = max(1, minutes - 5)
                        @unknown default: break
                        }
                        crown = Double(minutes)
                    }

                    HStack(spacing: 0) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                minutes = preset
                                crown = Double(preset)
                            } label: {
                                Text("\(preset)")
                                    .font(.system(size: 15, weight: minutes == preset ? .semibold : .regular))
                                    .frame(maxWidth: .infinity, minHeight: 34)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(minutes == preset ? WatchPalette.text : WatchPalette.patina)
                            .accessibilityLabel("\(preset) minutes")
                        }
                    }
                    .padding(.top, 2)

                    Button("Begin") {
                        Task { await model.startStandard(minutes: minutes) }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .buttonStyle(WatchProminentButtonStyle())
                    .padding(.top, 6)
                    .accessibilityHint("Begins an eight-second preparation")

                    if PracticeFeatures.awarenessEnabled {
                        NavigationLink {
                            WatchAwarenessSetupView { hours, interval in
                                Task { await model.startAwareness(hours: hours, intervalMinutes: interval) }
                            }
                        } label: {
                            WatchNavigationLabel(title: "Awareness")
                        }
                        .buttonStyle(WatchRowStyle())
                        .padding(.top, 10)
                    }

                    NavigationLink {
                        WatchMeditationLogView(
                            totals: model.dailyTotals,
                            warnsAboutUnreadableEntries: model.historyHadUnreadableEntries
                        )
                    } label: {
                        WatchNavigationLabel(title: "Log")
                    }
                    .buttonStyle(WatchRowStyle())
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.top, 6)
                .padding(.horizontal, 6)
                .padding(.bottom, 32)
            }
        }
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .idle) }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// A row: the title, and a chevron in the quiet ink. No icon, no fill, no
/// rounded rectangle — the hairline beneath it is the whole boundary.
private struct WatchNavigationLabel: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 16))
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(WatchPalette.patina)
        }
    }
}

/// The same shape as the sitting screen, for the same reason: hours on the ring
/// under the crown, the interval one tap away. It replaces four levels of
/// drill-down, each of which asked the wrist to hold still and read.
struct WatchAwarenessSetupView: View {
    let onStart: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastWatchAwarenessHours") private var hours = AwarenessPolicy.defaultHours
    @AppStorage("lastWatchAwarenessInterval") private var intervalMinutes = AwarenessPolicy.defaultIntervalMinutes
    @State private var crown = Double(AwarenessPolicy.defaultHours)

    private let intervals = [10, 15, 30, 60]

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // The system nav bar (back chevron + "Aware" title) is hidden,
                    // matching Home: on the 40 mm it cost as much vertical room as
                    // the ring itself, and there is no budget left over for a
                    // replacement label — the screen is reached by tapping
                    // "Awareness", which is identity enough, the same way Home
                    // carries no title of its own.
                    WatchApertureRing(
                        progress: Double(hours) / Double(AwarenessPolicy.maximumHours),
                        timeText: "\(hours)",
                        caption: "hours",
                        numeralFraction: 0.34
                    )
                    .frame(width: WatchMetrics.ring(0.32), height: WatchMetrics.ring(0.32))
                    .focusable(true)
                .digitalCrownRotation(
                    $crown,
                    from: Double(AwarenessPolicy.minimumHours),
                    through: Double(AwarenessPolicy.maximumHours),
                    by: 1,
                    sensitivity: .low,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                    .onChange(of: crown) { _, value in
                        hours = min(
                            AwarenessPolicy.maximumHours,
                            max(AwarenessPolicy.minimumHours, Int(value.rounded()))
                        )
                    }
                    .onAppear { crown = Double(hours) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Total duration")
                    .accessibilityValue("\(hours) hours")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: hours = min(AwarenessPolicy.maximumHours, hours + 1)
                        case .decrement: hours = max(AwarenessPolicy.minimumHours, hours - 1)
                        @unknown default: break
                        }
                        crown = Double(hours)
                    }

                    HStack(spacing: 0) {
                        ForEach(intervals, id: \.self) { interval in
                            Button {
                                intervalMinutes = interval
                            } label: {
                                Text("\(interval)")
                                    .font(.system(size: 15, weight: intervalMinutes == interval ? .semibold : .regular))
                                    .frame(maxWidth: .infinity, minHeight: 30)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(intervalMinutes == interval ? WatchPalette.text : WatchPalette.patina)
                            .accessibilityLabel("\(interval) minute interval")
                        }
                    }
                    .padding(.top, 6)

                    Text("GONG INTERVAL")
                        .font(.system(size: 9))
                        .tracking(1.4)
                        .foregroundStyle(WatchPalette.patina)
                        .accessibilityHidden(true)

                    Button("Begin") {
                        onStart(hours, intervalMinutes)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .buttonStyle(WatchProminentButtonStyle())
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: proxy.size.height, alignment: .top)
                .padding(.top, 6)
                .padding(.horizontal, 6)
                .padding(.bottom, 32)
            }
            // An overlay, not inline content: a real way back that costs no
            // vertical budget. The hidden system back button turned out not to
            // leave a swipe-to-go-back gesture behind it — without this, the
            // screen was a dead end.
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(WatchPalette.text)
                .accessibilityLabel("Back")
            }
        }
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .idle) }
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct WatchMeditationLogView: View {
    let totals: [DailyTotal]
    let warnsAboutUnreadableEntries: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                WatchEyebrow(text: "Meditation log")

                if warnsAboutUnreadableEntries {
                    Text("Some older entries could not be read.")
                        .font(.system(size: 11))
                        .foregroundStyle(WatchPalette.accent)
                        .padding(.top, 10)
                }

                if totals.isEmpty {
                    Text("The log is quiet.")
                        .font(.vtWatchSerif(22))
                        .foregroundStyle(WatchPalette.text)
                        .padding(.top, 16)
                } else {
                    // Rows, not cards. The date leads and the duration is the one
                    // warm mark, which is what makes the column scannable.
                    ForEach(totals.prefix(30)) { total in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(total.date, format: .dateTime.weekday(.abbreviated).day())
                                    .font(.system(size: 12))
                                    .foregroundStyle(WatchPalette.text)
                                Text(total.sessionCount == 1 ? "1 sitting" : "\(total.sessionCount) sittings")
                                    .font(.system(size: 10))
                                    .foregroundStyle(WatchPalette.patina)
                            }
                            Spacer(minLength: 4)
                            Text(DurationFormatter.concise(total.totalDuration))
                                .font(.vtWatchSerif(17))
                                .foregroundStyle(WatchPalette.accent)
                        }
                        .frame(minHeight: 46)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(WatchPalette.border.opacity(0.55))
                                .frame(height: 1)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 20)
        }
        .navigationTitle("Log")
        .containerBackground(for: .navigation) { WatchGanzfeldField(aperture: .log) }
    }
}
