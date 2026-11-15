import SwiftUI

// The pieces the main window and the menu bar panel are built from.
// System fonts, SF Symbols and semantic colours throughout, so they follow light and dark
// appearance, increased contrast and the rest of the system's settings.

// MARK: - Building blocks

/// A rounded panel. Every group of figures sits in one.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.fill.quaternary, in: .rect(cornerRadius: 14, style: .continuous))
    }
}

/// A card's heading: a coloured symbol and a quiet title.
struct CardTitle: View {
    var title: String
    var symbol: String
    var color: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 20, height: 16)
                .accessibilityHidden(true)
            Text(title)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline.weight(.medium))
        .lineLimit(1)
    }
}

/// A thin horizontal bar filled to a fraction between 0 and 1.
struct MeterBar: View {
    var fraction: Double
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.fill.tertiary)
                Capsule().fill(color)
                    .frame(width: max(4, geometry.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

/// One figure with a title above it and a short note below.
struct StatTile: View {
    var title: String
    var symbol: String
    var color: Color
    var quantity: Quantity?
    var caption: String
    var compact = false

    var body: some View {
        Card(padding: compact ? 10 : 14) {
            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                CardTitle(title: title, symbol: symbol, color: color)
                QuantityText(quantity: quantity ?? Quantity(value: "–"), size: compact ? .small : .tile)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// A symbol, a title with a line of detail, and a value on the right.
struct DetailRow: View {
    var symbol: String
    var title: String
    var detail: String?
    var value: String
    var valueColor: Color?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            Spacer(minLength: 8)
            HStack(spacing: 5) {
                if let valueColor {
                    Circle().fill(valueColor).frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Text(value)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The four tiles

/// Power now, emissions now, energy today and the grid's carbon intensity.
struct StatTiles: View {
    var snapshot: PowerSnapshot
    var columns = 4
    var compact = false

    var body: some View {
        let spacing: CGFloat = compact ? 8 : 12
        VStack(spacing: spacing) {
            ForEach(Array(stride(from: 0, to: 4, by: columns)), id: \.self) { start in
                HStack(spacing: spacing) {
                    ForEach(start..<min(start + columns, 4), id: \.self) { tile($0) }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder private func tile(_ index: Int) -> some View {
        switch index {
        case 0:
            StatTile(title: "Power Now", symbol: "bolt.fill", color: .orange,
                     quantity: snapshot.systemWatts.watts,
                     caption: snapshot.isEstimate ? "Estimated from CPU load"
                         : snapshot.onCharger ? "From the power adapter" : "From the battery",
                     compact: compact)
        case 1:
            StatTile(title: "Emitting Now", symbol: "carbon.dioxide.cloud.fill", color: .green,
                     quantity: snapshot.gramsPerHour?.co2.perHour,
                     caption: snapshot.rates?.gramsPerKWh == nil ? "Region not set" : "At the current draw",
                     compact: compact)
        case 2:
            StatTile(title: "Energy Today", symbol: "bolt.badge.clock.fill", color: .blue,
                     quantity: snapshot.energyWh.wattHours,
                     caption: "Since midnight",
                     compact: compact)
        default:
            StatTile(title: "Grid Intensity", symbol: "leaf.fill", color: .mint,
                     quantity: snapshot.rates?.gramsPerKWh.map {
                         Quantity(value: $0.formatted(.number.precision(.fractionLength(0))), unit: "g/kWh")
                     },
                     caption: snapshot.rates?.gramsPerKWh == nil ? "Region not set" : "CO₂e per kWh of electricity",
                     compact: compact)
        }
    }
}

// MARK: - Headline

/// The headline figure: today's emissions, or the power draw when the grid isn't known yet.
struct HeroCard: View {
    var snapshot: PowerSnapshot
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 0 : 2) {
            if let grams = snapshot.emissionsGrams {
                CardTitle(title: "Emissions Today", symbol: "leaf.fill", color: .green)
                QuantityText(quantity: grams.co2, size: compact ? .large : .hero)
                Text(source)
                    .font(compact ? .caption : .callout)
                    .foregroundStyle(.secondary)
            } else {
                CardTitle(title: "Power Now", symbol: "bolt.fill", color: .orange)
                QuantityText(quantity: snapshot.systemWatts.watts, size: compact ? .large : .hero)
                Text("Set up your electricity to see emissions.")
                    .font(compact ? .caption : .callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(compact ? 12 : 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color.green.opacity(0.26), Color.green.opacity(0.10)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var source: String {
        let energy = snapshot.energyText
        if let place = snapshot.rates?.placeName { return "From \(energy) of electricity in \(place)" }
        return "From \(energy) of electricity"
    }
}

// MARK: - Electricity

/// Where a grid's carbon intensity falls between none and coal-heavy (800 g CO₂e per kWh and up).
struct IntensityScale: View {
    var gramsPerKWh: Double

    private static let top = 800.0
    private static let knob: CGFloat = 12

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let fraction = min(max(gramsPerKWh / Self.top, 0), 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .yellow, .orange, .red, .brown],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: 6)
                    Circle()
                        .fill(.white)
                        .overlay(Circle().strokeBorder(.black.opacity(0.2), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.25), radius: 1.5, y: 0.5)
                        .frame(width: Self.knob, height: Self.knob)
                        .offset(x: fraction * (geometry.size.width - Self.knob))
                }
                .frame(height: Self.knob)
            }
            .frame(height: Self.knob)
            HStack {
                Text("Low carbon")
                Spacer()
                Text("High carbon")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .accessibilityElement()
        .accessibilityLabel("Carbon intensity")
        .accessibilityValue("\(Int(gramsPerKWh)) grams of CO₂ equivalent per kilowatt-hour")
    }
}

/// The electricity the estimates are based on: place, grid, and carbon intensity.
struct ElectricityCard: View {
    var rates: GridRates?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    CardTitle(title: "Your Electricity", symbol: "bolt.horizontal.fill", color: .yellow)
                    Spacer()
                    SettingsLink { Text("Change…") }
                        .controlSize(.small)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(rates?.placeName ?? "Region Not Set")
                        .font(.title3.weight(.semibold))
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
                if let grams = rates?.gramsPerKWh {
                    IntensityScale(gramsPerKWh: grams)
                } else {
                    Text("There's no carbon figure for this region. Enter your electricity's own in Settings.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let grams = rates?.gramsPerKWh {
                    Text("\(grams.formatted(.number.precision(.fractionLength(0)))) g CO₂e per kWh")
                        .font(.callout)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
        }
    }

    private var subtitle: String {
        if let grid = rates?.gridName { return "\(grid) grid" }
        return rates?.stateCode == nil ? "National average" : "Regional average"
    }
}

// MARK: - Chart

/// The last half hour of power use, with its average and peak.
struct ChartCard: View {
    var snapshot: PowerSnapshot
    var chartHeight: CGFloat = 150

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    CardTitle(title: "Power", symbol: "chart.xyaxis.line", color: .green)
                    Text("Last 30 minutes")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    if let summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .lineLimit(1)
                if snapshot.history.count > 1 {
                    HistoryChart(points: snapshot.history, gramsPerKWh: snapshot.rates?.gramsPerKWh)
                        .frame(height: chartHeight)
                } else {
                    Text("The chart starts after a minute of readings.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 72)
                }
            }
        }
    }

    private var summary: String? {
        let watts = snapshot.history.map(\.watts)
        guard watts.count > 1, let peak = watts.max() else { return nil }
        let average = watts.reduce(0, +) / Double(watts.count)
        return "Average \(average.wattsText) · Peak \(peak.wattsText)"
    }
}

// MARK: - Power source and this Mac

/// The power adapter and the battery: what each is supplying or taking.
struct SourceCard: View {
    var snapshot: PowerSnapshot

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "Power Source", symbol: "powerplug.fill", color: .orange)
                if snapshot.isEstimate {
                    DetailRow(symbol: "powerplug.fill", title: "Mains Power",
                              detail: "Estimated", value: snapshot.systemWatts.wattsText)
                    Text("macOS doesn't report power use on desktop Macs. This is an estimate from Apple's idle and maximum figures for \(snapshot.modelName ?? "this Mac") and how busy its processor is. It leaves out graphics load, displays and accessories.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if snapshot.onCharger {
                    DetailRow(symbol: "powerplug.fill", title: "Power Adapter",
                              detail: snapshot.adapterText,
                              value: (snapshot.chargerInputWatts ?? snapshot.fromChargerWatts).wattsText)
                }
                if let percent = snapshot.batteryPercent {
                    VStack(spacing: 8) {
                        DetailRow(symbol: snapshot.batterySymbol, title: "Battery",
                                  detail: snapshot.batteryStatusText,
                                  value: (Double(percent) / 100).formatted(.percent))
                        MeterBar(fraction: Double(percent) / 100, color: percent <= 20 ? .red : .green)
                            .padding(.leading, 38)
                    }
                }
            }
        }
    }
}

/// How hard the Mac is working: CPU load, thermal state and Low Power Mode.
struct MacCard: View {
    var snapshot: PowerSnapshot

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                CardTitle(title: "This Mac", symbol: "laptopcomputer", color: .blue)
                if let load = snapshot.cpuLoadPercent {
                    VStack(spacing: 8) {
                        DetailRow(symbol: "cpu", title: "CPU Load", detail: nil,
                                  value: (load / 100).formatted(.percent.precision(.fractionLength(0))))
                        MeterBar(fraction: load / 100, color: .blue)
                            .padding(.leading, 38)
                    }
                }
                DetailRow(symbol: "thermometer.medium", title: "Thermal State", detail: nil,
                          value: snapshot.thermalState.label, valueColor: snapshot.thermalState.color)
                DetailRow(symbol: "minus.plus.batteryblock", title: "Low Power Mode", detail: nil,
                          value: snapshot.lowPowerMode ? "On" : "Off")
            }
        }
    }
}

extension ThermalState {
    var color: Color {
        switch self {
        case .nominal: .green
        case .fair: .yellow
        case .serious: .orange
        case .critical: .red
        }
    }
}

// MARK: - Empty state

/// Shown before the first reading, and on Macs that don't report power use.
struct NoDataView: View {
    var hasBattery: Bool

    var body: some View {
        if hasBattery {
            ContentUnavailableView("Waiting for a Reading", systemImage: "bolt",
                                   description: Text("macOS updates its power figures about once a minute."))
        } else {
            ContentUnavailableView("No Power Data", systemImage: "bolt.slash",
                                   description: Text("This Mac doesn't report its power use to apps, and there are no published figures for this model to estimate from."))
        }
    }
}
