import SwiftUI

/// A number and its unit, kept apart so the unit can be set smaller than the number.
struct Quantity: Equatable {
    var value: String
    var unit: String = ""

    /// "14.2 W"
    var text: String { unit.isEmpty ? value : "\(value) \(unit)" }

    /// The same amount as a rate: "2.8 g CO₂e/h".
    var perHour: Quantity { Quantity(value: value, unit: unit.isEmpty ? "per hour" : "\(unit)/h") }
}

extension Double {
    /// Watts: "9.42 W", "14.2 W".
    var watts: Quantity {
        Quantity(value: formatted(.number.precision(.fractionLength(self < 10 ? 2 : 1))), unit: "W")
    }

    /// Grams of CO₂e: "3.7 g CO₂e", "1.25 kg CO₂e".
    var co2: Quantity {
        let inKilograms = self >= 1000
        let value = inKilograms ? self / 1000 : self
        let digits = value < 10 ? (inKilograms ? 2 : 1) : (value < 100 ? 1 : 0)
        return Quantity(value: value.formatted(.number.precision(.fractionLength(digits))),
                        unit: inKilograms ? "kg CO₂e" : "g CO₂e")
    }

    /// Watt-hours: "6.40 Wh", "96.0 Wh", "1.25 kWh".
    var wattHours: Quantity {
        if self >= 1000 {
            return Quantity(value: (self / 1000).formatted(.number.precision(.fractionLength(2))), unit: "kWh")
        }
        let digits = self < 10 ? 2 : (self < 100 ? 1 : 0)
        return Quantity(value: formatted(.number.precision(.fractionLength(digits))), unit: "Wh")
    }

    var wattsText: String { watts.text }
    var co2Text: String { co2.text }
}

/// A quantity with a large number and a smaller, quieter unit.
struct QuantityText: View {
    enum Size { case hero, large, tile, small }

    var quantity: Quantity
    var size = Size.tile

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size == .hero ? 6 : 3) {
            Text(quantity.value)
                .font(valueFont)
                .monospacedDigit()
                .contentTransition(.numericText())
            if !quantity.unit.isEmpty {
                Text(quantity.unit)
                    .font(unitFont)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .accessibilityElement(children: .combine)
    }

    private var valueFont: Font {
        switch size {
        case .hero: .system(size: 48, weight: .bold, design: .rounded)
        case .large: .system(size: 34, weight: .bold, design: .rounded)
        case .tile: .system(.title2, design: .rounded, weight: .semibold)
        case .small: .system(.headline, design: .rounded, weight: .semibold)
        }
    }

    private var unitFont: Font {
        switch size {
        case .hero: .system(.title2, design: .rounded, weight: .medium)
        case .large: .system(.title3, design: .rounded, weight: .medium)
        case .tile: .system(.callout, design: .rounded, weight: .medium)
        case .small: .system(.caption, design: .rounded, weight: .medium)
        }
    }
}
