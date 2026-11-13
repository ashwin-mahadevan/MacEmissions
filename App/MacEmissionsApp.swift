import SwiftUI

@main
struct MacEmissionsApp: App {
    @State private var grid: GridModel
    @State private var sampler: PowerSampler
    @AppStorage("showInMenuBar") private var showInMenuBar = true

    init() {
        let grid = GridModel()
        _grid = State(initialValue: grid)
        _sampler = State(initialValue: PowerSampler(grid: grid))
    }

    var body: some Scene {
        Window("MacEmissions", id: "main") {
            MainView()
                .environment(sampler)
        }
        .defaultSize(width: 420, height: 640)

        Settings {
            SettingsView()
                .environment(grid)
        }

        MenuBarExtra(isInserted: $showInMenuBar) {
            DashboardView()
                .environment(sampler)
        } label: {
            Label(sampler.snapshot?.systemWatts.wattsText ?? "– W",
                  systemImage: sampler.snapshot?.onCharger == false ? "bolt.batteryblock" : "bolt")
                .labelStyle(.titleAndIcon)
        }
        .menuBarExtraStyle(.window)
    }
}
