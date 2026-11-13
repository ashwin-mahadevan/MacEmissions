import Foundation
import IOKit

/// Reads the battery and charger from the AppleSmartBattery entry in the I/O Registry.
/// Works without admin rights and inside the widget's sandbox.
struct BatteryReading {
    var batteryWatts: Double?        // + charging, − discharging
    var percent: Int?
    var onCharger: Bool
    var isCharging: Bool
    var chargerName: String?
    var chargerRatedWatts: Int?
    var minutesRemaining: Int?
    // Whole-system telemetry (refreshed by macOS about once a minute)
    var systemLoadWatts: Double?
    var chargerInputWatts: Double?
    var updatedAt: Date?             // when macOS last refreshed these figures

    static func read() -> BatteryReading? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }   // desktop Mac: no battery
        defer { IOObjectRelease(service) }

        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return nil }

        func int(_ key: String, in d: [String: Any] = dict) -> Int? { (d[key] as? NSNumber)?.intValue }

        var r = BatteryReading(onCharger: (dict["ExternalConnected"] as? Bool) ?? false,
                               isCharging: (dict["IsCharging"] as? Bool) ?? false)

        if let mV = int("Voltage"), let mA = int("InstantAmperage") ?? int("Amperage") {
            // The amperage is a signed 64-bit value; negative means discharging.
            r.batteryWatts = Double(mV) * Double(Int64(truncatingIfNeeded: mA)) / 1_000_000
        }
        if let cur = int("CurrentCapacity"), let max = int("MaxCapacity"), max > 0 {
            // On Apple silicon these are already percentages; on Intel they're mAh.
            r.percent = max == 100 ? cur : Int((Double(cur) / Double(max) * 100).rounded())
        }
        if let adapter = dict["AdapterDetails"] as? [String: Any] {
            r.chargerName = adapter["Name"] as? String ?? adapter["Description"] as? String
            r.chargerRatedWatts = int("Watts", in: adapter)
        }
        let minutesKey = r.isCharging ? "AvgTimeToFull" : "AvgTimeToEmpty"
        if let m = int(minutesKey), m > 0, m < 65535, r.isCharging || !r.onCharger {
            r.minutesRemaining = m
        }
        if let t = dict["PowerTelemetryData"] as? [String: Any] {
            r.systemLoadWatts = int("SystemLoad", in: t).map { Double($0) / 1000 }
            r.chargerInputWatts = int("SystemPowerIn", in: t).map { Double($0) / 1000 }
        }
        if let t = int("UpdateTime"), t > 0 { r.updatedAt = Date(timeIntervalSince1970: TimeInterval(t)) }
        return r
    }
}
