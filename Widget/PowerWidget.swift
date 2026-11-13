import WidgetKit
import SwiftUI

struct PowerEntry: TimelineEntry {
    var date: Date
    var snapshot: PowerSnapshot?
}

struct PowerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PowerEntry {
        PowerEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (PowerEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PowerEntry>) -> Void) {
        // The app asks for a reload every minute while it runs; this is the fallback.
        completion(Timeline(entries: [currentEntry()], policy: .after(.now.addingTimeInterval(5 * 60))))
    }

    /// The app's latest reading if it's fresh; otherwise the widget measures by itself
    /// (same numbers, but no history or CPU load).
    private func currentEntry() -> PowerEntry {
        let saved = SharedStore.load()
        if let saved, Date().timeIntervalSince(saved.date) < 5 * 60 {
            return PowerEntry(date: .now, snapshot: saved)
        }
        // Keep the app's last known electricity figures, and today's total so far, so
        // emissions still show.
        var own = PowerSnapshot.measure()
        own?.rates = saved?.rates
        if let saved, Calendar.current.isDateInToday(saved.energySince) {
            own?.energyWh = saved.energyWh
            own?.energySince = saved.energySince
        }
        return PowerEntry(date: .now, snapshot: own)
    }
}

/// Picks the layout for the widget's size.
struct PowerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PowerEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemSmall: SmallWidget(snapshot: snapshot)
            case .systemMedium: MediumWidget(snapshot: snapshot)
            default: LargeWidget(snapshot: snapshot)
            }
        } else {
            Label("No power data", systemImage: "bolt.slash")
                .foregroundStyle(.secondary)
        }
    }
}

@main
struct MacEmissionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MacEmissionsWidget", provider: PowerProvider()) { entry in
            PowerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Emissions and Power")
        .description("The carbon emissions of the electricity your Mac has used today, and how many watts it is using now.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) { MacEmissionsWidget() } timeline: { PowerEntry(date: .now, snapshot: .preview) }
#Preview(as: .systemMedium) { MacEmissionsWidget() } timeline: { PowerEntry(date: .now, snapshot: .preview) }
#Preview(as: .systemLarge) { MacEmissionsWidget() } timeline: { PowerEntry(date: .now, snapshot: .preview) }
