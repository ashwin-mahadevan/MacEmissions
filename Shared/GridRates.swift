import Foundation

/// The carbon intensity and price of electricity where this Mac is plugged in.
/// Turns energy into emissions and cost. Saved with each snapshot so the widget can use it.
struct GridRates: Codable, Equatable {
    var regionCode: String?     // ISO 3166 two-letter country code
    var stateCode: String?      // US state, when the figures are for one
    var placeName: String?      // "California" or "France", for display
    var gridName: String?       // US grid subregion the carbon figure is for, e.g. "WECC California"
    var gramsPerKWh: Double?    // grams of CO₂-equivalent per kWh; nil when unknown
    var pricePerKWh: Double?    // in `currencyCode`; nil when unknown
    var currencyCode: String
}

extension PowerSnapshot {
    /// Emissions at the current draw, in grams of CO₂e per hour.
    var gramsPerHour: Double? { rates?.gramsPerKWh.map { systemWatts / 1000 * $0 } }
    /// Cost at the current draw, per hour.
    var costPerHour: Double? { rates?.pricePerKWh.map { systemWatts / 1000 * $0 } }
    /// Emissions of the energy used today, in grams of CO₂e.
    var emissionsGrams: Double? { rates?.gramsPerKWh.map { energyWh / 1000 * $0 } }
    /// Cost of the energy used today.
    var cost: Double? { rates?.pricePerKWh.map { energyWh / 1000 * $0 } }

    var costPerHourText: String? {
        guard let rates, let costPerHour else { return nil }
        return costPerHour.costText(rates.currencyCode)
    }

    var costText: String? {
        guard let rates, let cost else { return nil }
        return cost.costText(rates.currencyCode)
    }

    /// "6.40 Wh" or "1.25 kWh"
    var energyText: String {
        if energyWh < 1000 {
            return "\(energyWh.formatted(.number.precision(.fractionLength(2)))) Wh"
        }
        return Measurement(value: energyWh / 1000, unit: UnitEnergy.kilowattHours).formatted(
            .measurement(width: .abbreviated, usage: .asProvided,
                         numberFormatStyle: .number.precision(.fractionLength(2))))
    }
}

extension Double {
    /// Grams of CO₂e as "3.7 g CO₂e" or "1.25 kg CO₂e".
    var co2Text: String {
        let inKilograms = self >= 1000
        let value = inKilograms ? self / 1000 : self
        let digits = value < 10 ? (inKilograms ? 2 : 1) : (value < 100 ? 1 : 0)
        let mass = Measurement(value: value, unit: inKilograms ? UnitMass.kilograms : UnitMass.grams)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided,
                                    numberFormatStyle: .number.precision(.fractionLength(digits))))
        return "\(mass) CO₂e"
    }

    /// Money in the given currency. Amounts under 1 show up to four decimals ("$0.0017").
    func costText(_ currencyCode: String) -> String {
        let style = FloatingPointFormatStyle<Double>.Currency.currency(code: currencyCode)
        return self < 1 ? formatted(style.precision(.fractionLength(2...4))) : formatted(style)
    }
}
