import SwiftUI
import WidgetKit

private struct WatchPracticeEntry: TimelineEntry { let date: Date }

private struct WatchPracticeProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchPracticeEntry { WatchPracticeEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (WatchPracticeEntry) -> Void) {
        completion(WatchPracticeEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchPracticeEntry>) -> Void) {
        completion(Timeline(entries: [WatchPracticeEntry(date: Date())], policy: .never))
    }
}

private struct WatchPracticeView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("Begin a 60 min sit", systemImage: "timer")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("A place to sit.").font(.headline)
                Text("60 minutes · quiet gongs").font(.caption2)
            }
        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "circle.circle")
                    .font(.title3)
            }
        }
    }
}

@main
struct PracticeWatchComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PracticeWatchComplication", provider: WatchPracticeProvider()) { _ in
            WatchPracticeView()
                .widgetURL(URL(string: "vipassanatimer://sit?minutes=60"))
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Practice")
        .description("Open a quiet 60-minute sitting.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
