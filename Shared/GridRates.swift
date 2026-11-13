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

    var energyText: String { energyWh.wattHours.text }

    /// "$0.3258 per kWh"
    var priceText: String? {
        guard let rates, let price = rates.pricePerKWh else { return nil }
        return "\(price.costText(rates.currencyCode)) per kWh"
    }

    /// "195 g CO₂e per kWh"
    var intensityText: String? {
        rates?.gramsPerKWh.map { "\($0.formatted(.number.precision(.fractionLength(0)))) g CO₂e per kWh" }
    }
}
