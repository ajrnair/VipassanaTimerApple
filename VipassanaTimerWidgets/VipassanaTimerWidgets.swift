import SwiftUI
import WidgetKit

private struct PracticeEntry: TimelineEntry {
    let date: Date
}

private struct PracticeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PracticeEntry { PracticeEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (PracticeEntry) -> Void) {
        completion(PracticeEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PracticeEntry>) -> Void) {
        completion(Timeline(entries: [PracticeEntry(date: Date())], policy: .never))
    }
}

private struct PracticeWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if family == .systemMedium {
                HStack(spacing: 10) {
                    practiceLink("60 minute sit", subtitle: "One gong. Then silence.", icon: "timer", url: "vipassanatimer://sit?minutes=60")
                    practiceLink("30 minute sit", subtitle: "A shorter sitting.", icon: "timer", url: "vipassanatimer://sit?minutes=30")
                }
            } else {
                Link(destination: URL(string: "vipassanatimer://sit?minutes=60")!) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "circle.circle")
                            .font(.title2)
                            .foregroundStyle(Color("VTWidgetAccent"))
                        Spacer()
                        Text("A place\nto sit.")
                            .font(.system(.headline, design: .serif))
                        Text("60 minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                }
            }
        }
        .containerBackground(Color("VTWidgetBackground"), for: .widget)
        .foregroundStyle(Color("VTWidgetText"))
    }

    private func practiceLink(_ title: String, subtitle: String, icon: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(Color("VTWidgetAccent"))
                Spacer()
                Text(title).font(.system(.headline, design: .serif))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(4)
        }
    }
}

@main
struct PracticeQuickStartWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PracticeQuickStart", provider: PracticeProvider()) { _ in
            PracticeWidgetView()
        }
        .configurationDisplayName("Practice Quick Start")
        .description("Begin a sitting.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
