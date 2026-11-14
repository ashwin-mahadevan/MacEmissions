import Foundation

/// The carbon intensity of electricity where this Mac is plugged in.
/// Turns energy into emissions. Saved with each snapshot so the widget can use it.
struct GridRates: Codable, Equatable {
    var regionCode: String?     // ISO 3166 two-letter country code
    var stateCode: String?      // state or province, when the figures are for one
    var placeName: String?      // "California" or "France", for display
    var gridName: String?       // grid the carbon figure is for, e.g. "WECC California"
    var gramsPerKWh: Double?    // grams of CO₂-equivalent per kWh; nil when unknown
}

extension PowerSnapshot {
    /// Emissions at the current draw, in grams of CO₂e per hour.
    var gramsPerHour: Double? { rates?.gramsPerKWh.map { systemWatts / 1000 * $0 } }
    /// Emissions of the energy used today, in grams of CO₂e.
    var emissionsGrams: Double? { rates?.gramsPerKWh.map { energyWh / 1000 * $0 } }

    var energyText: String { energyWh.wattHours.text }

    /// "195 g CO₂e per kWh"
    var intensityText: String? {
        rates?.gramsPerKWh.map { "\($0.formatted(.number.precision(.fractionLength(0)))) g CO₂e per kWh" }
    }
}
