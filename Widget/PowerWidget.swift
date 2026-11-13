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
        // Keep the app's last known electricity figures so emissions still show.
        var own = PowerSnapshot.measure()
        own?.rates = saved?.rates
        return PowerEntry(date: .now, snapshot: own)
    }
}

@main
struct MacEmissionsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MacEmissionsWidget", provider: PowerProvider()) { entry in
            PowerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Power Use")
        .description("How many watts your Mac is using, where they come from, and the carbon emissions of that electricity.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension PowerSnapshot {
    static let preview = PowerSnapshot(
        date: .now, systemWatts: 14.2,
        onCharger: true, chargerInputWatts: 26.5, batteryWatts: 12.3, batteryPercent: 82, isCharging: true,
        chargerName: "96W USB-C Power Adapter", chargerRatedWatts: 96, minutesRemaining: 35,
        history: (0..<30).map { i in
            HistoryPoint(date: .now.addingTimeInterval(Double(i - 30) * 30),
                         watts: 12 + 5 * sin(Double(i) / 4) + Double(i % 3))
        },
        energyWh: 96, energySince: Calendar.current.startOfDay(for: .now),
        rates: GridRates(regionCode: "US", stateCode: "CA", placeName: "California",
                         gridName: "WECC California", gramsPerKWh: 195.0, pricePerKWh: 0.3258, currencyCode: "USD"),
        cpuLoadPercent: 18, thermalState: .nominal, lowPowerMode: false, measuredAt: .now)
}

#Preview(as: .systemSmall) { MacEmissionsWidget() } timeline: { PowerEntry(date: .now, snapshot: .preview) }
#Preview(as: .systemMedium) { MacEmissionsWidget() } timeline: { PowerEntry(date: .now, snapshot: .preview) }
#Preview(as: .systemLarge) { MacEmissionsWidget() } timeline: { PowerEntry(date: .now, snapshot: .preview) }
