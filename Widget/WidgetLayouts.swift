import SwiftUI
import WidgetKit

// The widget's three layouts. System text styles, SF Symbols and hierarchical colours,
// so they restyle correctly when macOS dims or tints desktop widgets.

/// Small: today's emissions, with the current draw and source underneath.
struct SmallWidget: View {
    var snapshot: PowerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            WidgetHeadline(snapshot: snapshot)
            Spacer(minLength: 0)
            WidgetStatus(snapshot: snapshot)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Medium: the small layout beside the last half hour of power use.
struct MediumWidget: View {
    var snapshot: PowerSnapshot

    var body: some View {
        HStack(spacing: 14) {
            SmallWidget(snapshot: snapshot)
                .frame(width: 128)
            VStack(alignment: .leading, spacing: 8) {
                if snapshot.history.count > 1 {
                    HistoryChart(points: snapshot.history, showsAxes: false)
                }
                HStack(spacing: 12) {
                    WidgetStat(title: "Energy Today", value: snapshot.energyText)
                    if let grams = snapshot.gramsPerHour {
                        WidgetStat(title: "Emitting Now", value: grams.co2.perHour.text)
                    }
                }
                if snapshot.history.count <= 1 { Spacer(minLength: 0) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

/// Large: headline, chart, and a grid of the day's figures.
struct LargeWidget: View {
    var snapshot: PowerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                WidgetHeadline(snapshot: snapshot)
                Spacer()
                WidgetStatus(snapshot: snapshot, alignment: .trailing)
            }
            if snapshot.history.count > 1 {
                HistoryChart(points: snapshot.history, showsAxes: false)
            } else {
                Spacer(minLength: 0)
            }
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    WidgetStat(title: "Emitting Now", value: snapshot.gramsPerHour?.co2.perHour.text ?? "–")
                    WidgetStat(title: "Energy Today", value: snapshot.energyText)
                }
                GridRow {
                    WidgetStat(title: "Power Now", value: snapshot.systemWatts.wattsText)
                    WidgetStat(title: "Source", value: snapshot.sourceTitle)
                }
            }
            if let footer {
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var footer: String? {
        guard let rates = snapshot.rates, let intensity = snapshot.intensityText else { return nil }
        let place = rates.gridName.map { "\($0) grid" } ?? rates.placeName
        return [place, intensity].compactMap { $0 }.joined(separator: " · ")
    }
}

// MARK: - Pieces

/// Today's emissions, or the power draw when there's nothing to add up yet.
struct WidgetHeadline: View {
    var snapshot: PowerSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let grams = snapshot.emissionsGrams, snapshot.energyWh > 0 {
                title("Today", symbol: "leaf.fill", color: .green)
                figure(grams.co2)
            } else {
                title("Power", symbol: "bolt.fill", color: .orange)
                figure(snapshot.systemWatts.watts)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func title(_ text: String, symbol: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(text).foregroundStyle(.secondary)
        }
        .font(.caption.weight(.semibold))
    }

    @ViewBuilder private func figure(_ quantity: Quantity) -> some View {
        Text(quantity.value)
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .widgetAccentable()
        Text(quantity.unit)
            .font(.system(.caption, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
    }
}

/// The current draw, where it comes from, and when it was measured.
struct WidgetStatus: View {
    var snapshot: PowerSnapshot
    var alignment = HorizontalAlignment.leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            if showsWatts {
                row("\(snapshot.systemWatts.wattsText) now", symbol: "bolt.fill")
            } else if let grams = snapshot.gramsPerHour {
                row(grams.co2.perHour.text, symbol: "leaf.fill")
            }
            row(source, symbol: snapshot.isEstimate ? "desktopcomputer"
                : snapshot.onCharger ? "powerplug.fill" : snapshot.batterySymbol)
            Text("Updated \(snapshot.measuredAt ?? snapshot.date, style: .time)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// Watts are left out when the headline above is already showing them.
    private var showsWatts: Bool { snapshot.emissionsGrams != nil && snapshot.energyWh > 0 }

    private func row(_ text: String, symbol: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .frame(width: 18)
                .accessibilityHidden(true)
            Text(text)
        }
    }

    private var source: String {
        if snapshot.isEstimate { return "Estimated" }
        guard let percent = snapshot.batteryPercent else { return snapshot.sourceTitle }
        let level = (Double(percent) / 100).formatted(.percent)
        return snapshot.onCharger ? "Adapter · \(level)" : "Battery · \(level)"
    }
}

/// A small titled figure.
struct WidgetStat: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
