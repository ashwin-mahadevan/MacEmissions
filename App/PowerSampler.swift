import Foundation
import Darwin
import Observation
import WidgetKit

/// Takes a power reading every 2 seconds and publishes it to the UI and the widget.
///
/// Uses only public APIs that work inside the App Sandbox:
/// - Total draw and sources: the battery's entry in the I/O Registry (`BatteryReading`).
///   macOS refreshes those figures about once a minute, so readings move in steps.
/// - CPU load: `host_statistics`.
/// - Thermal state and Low Power Mode: `ProcessInfo`.
@MainActor @Observable
final class PowerSampler {
    private(set) var snapshot: PowerSnapshot?
    /// False once we've looked and found no battery (desktop Macs don't report power to apps).
    private(set) var hasBattery = true
    /// Energy for each of the last 30 days, today included.
    private(set) var days: [DayRecord] = DayStore.load()

    @ObservationIgnored private let cpuLoad = CPULoad()
    @ObservationIgnored private let grid: GridModel
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var lastTick: Date?
    /// Energy is added up per calendar day and kept between launches.
    @ObservationIgnored private var day = Calendar.current.startOfDay(for: .now)
    @ObservationIgnored private var energyWh = 0.0
    @ObservationIgnored private var history: [HistoryPoint] = []
    @ObservationIgnored private var historyBucket: [Double] = []
    @ObservationIgnored private var lastWidgetSave = Date.distantPast
    @ObservationIgnored private var lastWidgetReload = Date.distantPast

    private static let interval = 2.0

    init(grid: GridModel) {
        self.grid = grid
        #if DEBUG
        // `-demo` shows sample figures and records nothing. Used for App Store screenshots.
        if ProcessInfo.processInfo.arguments.contains("-demo") {
            snapshot = .preview
            days = DayRecord.preview
            return
        }
        #endif
        if defaults.object(forKey: "energyDay") as? Date == day {
            energyWh = defaults.double(forKey: "energyTodayWh")
        }
        // Pick the chart up where the last run left off, if that was within the half hour.
        let cutoff = Date().addingTimeInterval(-30 * 60)
        history = SharedStore.load()?.history.filter { $0.date > cutoff } ?? []
        Task { [weak self] in
            while let self {
                self.tick()
                try? await Task.sleep(for: .seconds(Self.interval))
            }
        }
    }

    private func tick() {
        let now = Date()
        let dt = lastTick.map { now.timeIntervalSince($0) } ?? 0
        lastTick = now

        let load = cpuLoad.sample()
        guard var snap = PowerSnapshot.measure(cpuLoadPercent: load) else {
            hasBattery = BatteryReading.read() != nil
            return
        }
        hasBattery = true

        // Start a new total at midnight.
        let today = Calendar.current.startOfDay(for: now)
        if today != day {
            day = today
            energyWh = 0
        }
        // Ignore long gaps (sleep) when adding up energy.
        if dt > 0, dt < 10 { energyWh += snap.systemWatts * dt / 3600 }

        // One history point every 30 s, keeping the last 30 minutes.
        historyBucket.append(snap.systemWatts)
        if Double(historyBucket.count) * Self.interval >= 30 {
            history.append(HistoryPoint(date: now, watts: historyBucket.reduce(0, +) / Double(historyBucket.count)))
            historyBucket.removeAll()
            if history.count > 60 { history.removeFirst(history.count - 60) }
        }

        snap.history = history
        snap.energyWh = energyWh
        snap.energySince = day
        snap.rates = grid.rates
        snapshot = snap

        // Widget: save every 10 s, ask WidgetKit to refresh every minute.
        if now.timeIntervalSince(lastWidgetSave) >= 10 {
            SharedStore.save(snap)
            defaults.set(day, forKey: "energyDay")
            defaults.set(energyWh, forKey: "energyTodayWh")
            let rates = snap.rates
            days = DayStore.updating(days, with: DayRecord(
                day: day, energyWh: energyWh, gramsPerKWh: rates?.gramsPerKWh))
            DayStore.save(days)
            lastWidgetSave = now
        }
        if now.timeIntervalSince(lastWidgetReload) >= 60 {
            WidgetCenter.shared.reloadAllTimelines()
            lastWidgetReload = now
        }
    }
}

/// Percentage of time all CPU cores were busy since the last sample.
final class CPULoad {
    private var previous: host_cpu_load_info?

    func sample() -> Double? {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        defer { previous = info }
        guard let old = previous else { return nil }

        func delta(_ i: Int32) -> Double {
            let new = withUnsafeBytes(of: info.cpu_ticks) { $0.load(fromByteOffset: Int(i) * 4, as: UInt32.self) }
            let was = withUnsafeBytes(of: old.cpu_ticks) { $0.load(fromByteOffset: Int(i) * 4, as: UInt32.self) }
            return Double(new &- was)
        }
        let busy = delta(CPU_STATE_USER) + delta(CPU_STATE_SYSTEM) + delta(CPU_STATE_NICE)
        let all = busy + delta(CPU_STATE_IDLE)
        return all > 0 ? busy / all * 100 : nil
    }
}
