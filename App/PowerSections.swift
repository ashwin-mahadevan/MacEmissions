import SwiftUI

// The content shared by the main window and the menu bar panel.
// Standard grouped-Form sections, so both follow the system look.

struct NowSection: View {
    var snapshot: PowerSnapshot
    var chartHeight: CGFloat = 80

    var body: some View {
        Section {
            VStack(alignment: .leading) {
                Text(snapshot.systemWatts.wattsText)
                    .font(.largeTitle)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text("This Mac is using now")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            if snapshot.history.count > 1 {
                HistoryChart(points: snapshot.history)
                    .frame(height: chartHeight)
            }
        } footer: {
            if let measuredAt = snapshot.measuredAt {
                Text("Measured by macOS \(measuredAt, style: .relative) ago")
            }
        }
    }
}

/// What today's electricity means in carbon and money, from the local grid's figures.
struct EmissionsSection: View {
    var snapshot: PowerSnapshot

    var body: some View {
        Section {
            if let grams = snapshot.gramsPerHour {
                LabeledContent("Emitting Now", value: "\(grams.co2Text) per hour")
            }
            if let grams = snapshot.emissionsGrams {
                LabeledContent("Emissions Today", value: grams.co2Text)
            }
            if let cost = snapshot.costPerHourText {
                LabeledContent("Cost Now", value: "\(cost) per hour")
            }
            if let cost = snapshot.costText {
                LabeledContent("Cost Today", value: cost)
            }
            LabeledContent("Energy Today", value: snapshot.energyText)
            if snapshot.rates?.gramsPerKWh == nil || snapshot.rates?.pricePerKWh == nil {
                SettingsLink { Text("Set Up Electricity…") }
            }
        } header: {
            Text("Carbon and Cost")
        } footer: {
            Text(footer)
        }
    }

    private var footer: String {
        var parts: [String] = []
        if let rates = snapshot.rates, let grams = rates.gramsPerKWh {
            let intensity = "\(grams.formatted(.number.precision(.fractionLength(0)))) g CO₂e per kWh"
            if let region = rates.placeName, let grid = rates.gridName {
                parts.append("Estimated for electricity in \(region), on the \(grid) grid (\(intensity)).")
            } else if let region = rates.placeName {
                parts.append("Estimated for electricity in \(region) (\(intensity)).")
            } else {
                parts.append("Estimated at \(intensity).")
            }
        } else {
            parts.append("Choose a region or enter your electricity's figures in Settings to see emissions.")
        }
        parts.append("Today's totals count only while MacEmissions is running.")
        return parts.joined(separator: " ")
    }
}

struct SourceSection: View {
    var snapshot: PowerSnapshot

    var body: some View {
        Section("Power Source") {
            LabeledContent("Running On") {
                Label(snapshot.sourceTitle, systemImage: snapshot.sourceSymbol)
            }
            if let adapter = snapshot.adapterText {
                LabeledContent("Adapter", value: adapter)
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
            if let time = snapshot.timeRemainingText {
                LabeledContent(snapshot.isCharging ? "Time Until Full" : "Time Remaining", value: time)
            }
        }
    }
}

struct SystemSection: View {
    var snapshot: PowerSnapshot

    var body: some View {
        Section("This Mac") {
            if let load = snapshot.cpuLoadPercent {
                LabeledContent("CPU Load") { Text(load / 100, format: .percent.precision(.fractionLength(0))) }
            }
            LabeledContent("Thermal State", value: snapshot.thermalState.label)
            LabeledContent("Low Power Mode", value: snapshot.lowPowerMode ? "On" : "Off")
        }
    }
}

/// Shown before the first reading, and on Macs that don't report power use.
struct NoDataView: View {
    var hasBattery: Bool

    var body: some View {
        if hasBattery {
            ContentUnavailableView("Waiting for a Reading", systemImage: "bolt",
                                   description: Text("macOS updates its power figures about once a minute."))
        } else {
            ContentUnavailableView("No Power Data", systemImage: "bolt.slash",
                                   description: Text("Macs without a battery don't report their power use to apps."))
        }
    }
}
