import SwiftUI

/// What the menu bar item shows next to its symbol. Chosen in Settings.
enum MenuBarMetric: String, CaseIterable, Identifiable {
    case emissionsToday, emissionsRate, power

    var id: Self { self }

    var title: String {
        switch self {
        case .emissionsToday: "Emissions Today"
        case .emissionsRate: "Emissions per Hour"
        case .power: "Power Now"
        }
    }

    /// The text for the menu bar. Falls back to watts when a figure isn't available.
    func text(for snapshot: PowerSnapshot?) -> String {
        guard let snapshot else { return "– W" }
        switch self {
        case .power: break
        case .emissionsRate:
            if let grams = snapshot.gramsPerHour { return grams.co2.perHour.text }
        case .emissionsToday:
            if let grams = snapshot.emissionsGrams { return grams.co2.text }
        }
        return snapshot.systemWatts.wattsText
    }

    func symbol(for snapshot: PowerSnapshot?) -> String {
        switch self {
        case .emissionsRate where snapshot?.gramsPerHour != nil,
             .emissionsToday where snapshot?.emissionsGrams != nil:
            "leaf"
        default:
            snapshot?.onCharger == false ? "bolt.batteryblock" : "bolt"
        }
    }
}

/// The panel that opens from the menu bar: the headline figures at a glance, plus shortcuts.
struct MenuBarPanel: View {
    @Environment(PowerSampler.self) private var sampler
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            if let snapshot = sampler.snapshot {
                PanelContent(snapshot: snapshot)
            } else {
                NoDataView(hasBattery: sampler.hasBattery)
                    .frame(height: 240)
            }
            Divider()
            HStack {
                Button("Open MacEmissions") {
                    openWindow(id: "dashboard")
                    NSApp.activate()
                }
                SettingsLink { Text("Settings…") }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(12)
        }
        .frame(width: 320)
    }
}

/// The panel's figures for one reading.
struct PanelContent: View {
    var snapshot: PowerSnapshot

    var body: some View {
        VStack(spacing: 8) {
            HeroCard(snapshot: snapshot, compact: true)
            StatTiles(snapshot: snapshot, columns: 2, compact: true)
            if snapshot.history.count > 1 {
                Card(padding: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        CardTitle(title: "Power, Last 30 Minutes", symbol: "chart.xyaxis.line", color: .green)
                        HistoryChart(points: snapshot.history, showsAxes: false)
                            .frame(height: 56)
                    }
                }
            }
            Card(padding: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    if snapshot.isEstimate {
                        DetailRow(symbol: "desktopcomputer", title: snapshot.modelName ?? "This Mac",
                                  detail: "Estimated from CPU load", value: snapshot.systemWatts.wattsText)
                    } else if snapshot.onCharger {
                        DetailRow(symbol: "powerplug.fill", title: "Power Adapter", detail: snapshot.adapterText,
                                  value: (snapshot.chargerInputWatts ?? snapshot.fromChargerWatts).wattsText)
                    }
                    if let percent = snapshot.batteryPercent {
                        DetailRow(symbol: snapshot.batterySymbol, title: "Battery",
                                  detail: snapshot.batteryStatusText,
                                  value: (Double(percent) / 100).formatted(.percent))
                    }
                }
            }
            if let place = snapshot.rates?.placeName, let intensity = snapshot.intensityText {
                Text("\(snapshot.rates?.gridName.map { "\($0) grid" } ?? place) · \(intensity)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .animation(.default, value: snapshot.systemWatts)
    }
}

#Preview("Menu bar panel") {
    PanelContent(snapshot: .preview)
        .frame(width: 320)
}
