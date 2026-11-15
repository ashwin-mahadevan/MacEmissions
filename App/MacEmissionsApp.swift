import SwiftUI

/// Keeps the app running, and recording, after its window is closed. It carries on in the menu
/// bar; with the menu bar item turned off, clicking the Dock icon brings the window back.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

@main
struct MacEmissionsApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var grid: GridModel
    @State private var sampler: PowerSampler
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("menuBarMetric") private var menuBarMetric = MenuBarMetric.emissionsToday

    init() {
        let grid = GridModel()
        _grid = State(initialValue: grid)
        _sampler = State(initialValue: PowerSampler(grid: grid))
    }

    var body: some Scene {
        Window("MacEmissions", id: "dashboard") {
            MainView()
                .environment(sampler)
        }
        .defaultSize(width: 760, height: 920)
        .commands {
            CommandGroup(replacing: .help) {
                Link("MacEmissions Support", destination: URL(string: "https://ashwinm.com/MacEmissions")!)
                Link("Privacy Policy", destination: URL(string: "https://ashwinm.com/MacEmissions/privacy")!)
            }
        }

        Settings {
            SettingsView()
                .environment(grid)
        }

        MenuBarExtra(isInserted: $showInMenuBar) {
            MenuBarPanel()
                .environment(sampler)
        } label: {
            Label(menuBarMetric.text(for: sampler.snapshot),
                  systemImage: menuBarMetric.symbol(for: sampler.snapshot))
                .labelStyle(.titleAndIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
