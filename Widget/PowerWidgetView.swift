import WidgetKit
import SwiftUI

/// The widget's layouts. System text styles, SF Symbols and hierarchical colours only,
/// so it restyles correctly when macOS dims or tints desktop widgets.
struct PowerWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: PowerEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemSmall: Summary(snapshot: snapshot)
            case .systemMedium: medium(snapshot)
            default: large(snapshot)
            }
        } else {
            Label("No power data", systemImage: "bolt.slash")
                .foregroundStyle(.secondary)
        }
    }

    private func medium(_ snapshot: PowerSnapshot) -> some View {
        HStack(spacing: 16) {
            Summary(snapshot: snapshot)
            if snapshot.history.count > 1 {
                HistoryChart(points: snapshot.history)
                    .chartXAxis(.hidden)
            } else {
                Details(snapshot: snapshot)
            }
        }
    }

    private func large(_ snapshot: PowerSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Summary(snapshot: snapshot)
                .frame(maxHeight: 110)
            if snapshot.history.count > 1 {
                HistoryChart(points: snapshot.history)
                    .chartXAxis(.hidden)
            }
            Divider()
            Details(snapshot: snapshot)
        }
    }
}

/// The headline: watts in use, the source, and when it was measured.
private struct Summary: View {
    var snapshot: PowerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Power", systemImage: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(snapshot.systemWatts.wattsText)
                .font(.title)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .widgetAccentable()
            Label(snapshot.sourceTitle, systemImage: snapshot.sourceSymbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let grams = snapshot.gramsPerHour {
                Label("\(grams.co2Text)/h", systemImage: "leaf")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Text("Updated \(snapshot.measuredAt ?? snapshot.date, style: .time)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Label-and-value rows for the larger sizes.
private struct Details: View {
    var snapshot: PowerSnapshot

    var body: some View {
        VStack(spacing: 6) {
            if let grams = snapshot.emissionsGrams, snapshot.energyWh > 0 {
                LabeledContent("Emissions Today", value: grams.co2Text)
            }
            if let cost = snapshot.costText, snapshot.energyWh > 0 {
                LabeledContent("Cost Today", value: cost)
            }
            if snapshot.onCharger {
                LabeledContent("From Adapter",
                               value: (snapshot.chargerInputWatts ?? snapshot.fromChargerWatts).wattsText)
            }
            if let percent = snapshot.batteryPercent {
                LabeledContent("Battery") { Text(Double(percent) / 100, format: .percent) }
            }
            if snapshot.intoBatteryWatts > 0.05 {
                LabeledContent("Charging At", value: snapshot.intoBatteryWatts.wattsText)
            } else if snapshot.fromBatteryWatts > 0.05 {
                LabeledContent("From Battery", value: snapshot.fromBatteryWatts.wattsText)
            }
            if let load = snapshot.cpuLoadPercent {
                LabeledContent("CPU Load") { Text(load / 100, format: .percent.precision(.fractionLength(0))) }
            }
            LabeledContent("Thermal State", value: snapshot.thermalState.label)
        }
        .font(.caption)
    }
}
