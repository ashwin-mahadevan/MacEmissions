import SwiftUI

@main
struct MacEmissionsApp: App {
    @State private var grid: GridModel
    @State private var sampler: PowerSampler
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("menuBarMetric") private var menuBarMetric = MenuBarMetric.power

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
