import Foundation

/// One reading of how much power this Mac is using and where it comes from.
/// Written by the app, read by the widget.
struct PowerSnapshot: Codable, Equatable {
    var date: Date

    var systemWatts: Double          // total draw of the whole computer

    // Where the power comes from
    var onCharger: Bool
    var chargerInputWatts: Double?   // what the power adapter is delivering
    var batteryWatts: Double?        // + charging, − discharging
    var batteryPercent: Int?
    var isCharging: Bool
    var chargerName: String?
    var chargerRatedWatts: Int?
    var minutesRemaining: Int?       // to full when charging, to empty otherwise

    var history: [HistoryPoint] = [] // total watts over the last ~30 minutes
    var energyWh: Double = 0         // energy used today, while the app was running
    var energySince: Date = .now     // the start of that day
    var rates: GridRates?            // carbon intensity and price of the local electricity

    var cpuLoadPercent: Double?      // whole-system CPU busy %, all cores
    var thermalState: ThermalState
    var lowPowerMode: Bool
    var measuredAt: Date?            // when macOS last refreshed the battery's power figures

    /// Power flowing from the battery into the computer.
    var fromBatteryWatts: Double { max(0, -(batteryWatts ?? 0)) }
    /// Power flowing from the power adapter into the computer (not into the battery).
    var fromChargerWatts: Double { onCharger ? max(0, systemWatts - fromBatteryWatts) : 0 }
    /// Power flowing from the power adapter into the battery.
    var intoBatteryWatts: Double { max(0, batteryWatts ?? 0) }

    /// A reading taken right now from public, sandbox-safe sources.
    /// Returns nil on Macs without a battery, or before macOS has a power figure.
    static func measure(cpuLoadPercent: Double? = nil) -> PowerSnapshot? {
        guard let b = BatteryReading.read() else { return nil }
        // Total draw: battery telemetry, or the battery's own discharge rate when unplugged.
        var total = b.systemLoadWatts
        if total ?? 0 <= 0, !b.onCharger, let w = b.batteryWatts, w < 0 { total = -w }
        guard let total, total > 0 else { return nil }

        let info = ProcessInfo.processInfo
        return PowerSnapshot(
            date: .now, systemWatts: total,
            onCharger: b.onCharger, chargerInputWatts: b.chargerInputWatts,
            batteryWatts: b.batteryWatts, batteryPercent: b.percent, isCharging: b.isCharging,
            chargerName: b.chargerName, chargerRatedWatts: b.chargerRatedWatts,
            minutesRemaining: b.minutesRemaining,
            cpuLoadPercent: cpuLoadPercent,
            thermalState: ThermalState(info.thermalState),
            lowPowerMode: info.isLowPowerModeEnabled,
            measuredAt: b.updatedAt)
    }
}

enum ThermalState: String, Codable {
    case nominal, fair, serious, critical

    init(_ s: ProcessInfo.ThermalState) {
        switch s {
        case .fair: self = .fair
        case .serious: self = .serious
        case .critical: self = .critical
        default: self = .nominal
        }
    }

    var label: String {
        switch self {
        case .nominal: "Normal"
        case .fair: "Warm"
        case .serious: "Hot"
        case .critical: "Very Hot"
        }
    }
}

struct HistoryPoint: Codable, Equatable, Identifiable {
    var date: Date
    var watts: Double
    var id: Date { date }
}

/// The file the app and widget share through their app group container.
enum SharedStore {
    static let appGroup = "CNKCL6ZB39.com.ashwinm.macemissions"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("snapshot.json")
    }

    static func save(_ snapshot: PowerSnapshot) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }

    static func load() -> PowerSnapshot? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PowerSnapshot.self, from: data)
    }
}

// MARK: - Formatting (system formatters, so units and digits follow the user's locale)

extension Double {
    /// "12.3 W"
    var wattsText: String {
        Measurement(value: self, unit: UnitPower.watts).formatted(
            .measurement(width: .abbreviated, usage: .asProvided,
                         numberFormatStyle: .number.precision(.fractionLength(self < 10 ? 2 : 1))))
    }
}

extension PowerSnapshot {
    var sourceTitle: String { onCharger ? "Power Adapter" : "Battery" }
    var sourceSymbol: String { onCharger ? "powerplug.fill" : "battery.75percent" }

    var adapterText: String? {
        guard onCharger else { return nil }
        return chargerName ?? chargerRatedWatts.map { "\($0) W" }
    }

    var timeRemainingText: String? {
        minutesRemaining.map {
            Duration.seconds($0 * 60).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        }
    }
}
