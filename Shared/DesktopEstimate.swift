import Foundation
import IOKit

/// What this Mac is: its marketing name, chip and model identifier.
struct MacModel {
    var name: String?        // "Mac mini (2024)"; Apple silicon only
    var chip: String?        // "Apple M4 Pro", or the Intel processor's name
    var identifier: String?  // "Mac16,11", "iMac20,1"

    static let current: MacModel = {
        #if DEBUG
        // `-demoDesktop "Mac mini (2024)|Apple M4"` pretends to be that Mac, to try the estimate
        // on a laptop.
        if let parts = UserDefaults.standard.string(forKey: "demoDesktop")?.split(separator: "|"), parts.count == 2 {
            return MacModel(name: String(parts[0]), chip: String(parts[1]), identifier: nil)
        }
        #endif
        return MacModel(name: productName(), chip: sysctl("machdep.cpu.brand_string"), identifier: sysctl("hw.model"))
    }()

    private static func sysctl(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    /// The name macOS shows in About This Mac, from the device tree.
    private static func productName() -> String? {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product")
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }
        guard let data = IORegistryEntryCreateCFProperty(entry, "product-name" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? Data else { return nil }
        let name = String(decoding: data.prefix { $0 != 0 }, as: UTF8.self)
        return name.isEmpty ? nil : name
    }
}

/// An estimate of a desktop Mac's power draw.
///
/// macOS reports power use to apps only on Macs with a battery. For the others, Apple publishes
/// each model's draw when idle and at full load, measured at the wall. The estimate is a
/// straight line between the two, placed by how busy the processor is. It knows nothing about
/// graphics load, display brightness or anything plugged in, so it is rough.
///
/// Figures, in watts, are from Apple Support, fetched 2026-11-14:
/// - Mac mini: https://support.apple.com/en-us/103253
/// - Mac Studio: https://support.apple.com/en-us/102027
/// - Mac Pro: https://support.apple.com/en-us/102839
/// - iMac: https://support.apple.com/en-us/109513
/// Where Apple lists two configurations of one model that can't be told apart here (the two-
/// and four-port iMacs, the two Mac Pro (2023) configurations), the figures are their average.
/// The Intel models listed are the ones that can run this app's minimum macOS.
enum DesktopEstimate {
    struct Figures: Equatable {
        var idle: Double
        var max: Double
    }

    /// Apple silicon desktops by family and chip. Longer chip names come first, so that
    /// "M2 Pro" isn't taken for "M2".
    private static let appleSilicon: [(family: String, chip: String, figures: Figures)] = [
        ("Mac mini", "M6", Figures(idle: 4, max: 70)),
        ("Mac mini", "M5 Pro", Figures(idle: 6, max: 145)),
        ("Mac mini", "M4 Pro", Figures(idle: 5, max: 140)),
        ("Mac mini", "M4", Figures(idle: 4, max: 65)),
        ("Mac mini", "M2 Pro", Figures(idle: 7, max: 100)),
        ("Mac mini", "M2", Figures(idle: 7, max: 50)),
        ("Mac mini", "M1", Figures(idle: 6.8, max: 39)),
        ("Mac Studio", "M5 Ultra", Figures(idle: 9, max: 385)),
        ("Mac Studio", "M5 Max", Figures(idle: 7, max: 200)),
        ("Mac Studio", "M4 Max", Figures(idle: 6, max: 145)),
        ("Mac Studio", "M3 Ultra", Figures(idle: 9, max: 270)),
        ("Mac Studio", "M2 Ultra", Figures(idle: 10, max: 295)),
        ("Mac Studio", "M2 Max", Figures(idle: 9, max: 145)),
        ("Mac Studio", "M1 Ultra", Figures(idle: 13, max: 215)),
        ("Mac Studio", "M1 Max", Figures(idle: 11, max: 115)),
        ("Mac Pro", "M2 Ultra", Figures(idle: 48, max: 315)),
        ("iMac", "M6", Figures(idle: 42, max: 77.5)),
        ("iMac", "M4", Figures(idle: 44.5, max: 102.5)),
        ("iMac", "M3", Figures(idle: 41.5, max: 77.5)),
        ("iMac", "M1", Figures(idle: 43, max: 82)),
    ]

    /// Intel desktops by model identifier.
    private static let intel: [String: Figures] = [
        "Macmini8,1": Figures(idle: 19.9, max: 122),   // Mac mini (2018)
        "iMac19,1": Figures(idle: 71, max: 262),       // iMac (Retina 5K, 27-inch, 2019)
        "iMac19,2": Figures(idle: 47, max: 166),       // iMac (Retina 4K, 21.5-inch, 2019)
        "iMac20,1": Figures(idle: 74, max: 295),       // iMac (Retina 5K, 27-inch, 2020)
        "iMac20,2": Figures(idle: 74, max: 295),
        "MacPro7,1": Figures(idle: 101, max: 430),     // Mac Pro (2019), 8-core configuration
    ]

    /// Apple's idle and maximum figures for a model, or nil if it isn't a desktop Mac listed here.
    static func figures(for model: MacModel) -> Figures? {
        if let identifier = model.identifier, let figures = intel[identifier] { return figures }
        guard let name = model.name, let chip = model.chip?.replacingOccurrences(of: "Apple ", with: "") else {
            return nil
        }
        return appleSilicon.first { name.hasPrefix($0.family) && chip == $0.chip }?.figures
    }

    /// Watts at a CPU load between 0 and 100 percent. With no load figure yet, the idle draw.
    static func watts(_ figures: Figures, cpuLoadPercent: Double?) -> Double {
        let load = min(max((cpuLoadPercent ?? 0) / 100, 0), 1)
        return figures.idle + (figures.max - figures.idle) * load
    }
}
