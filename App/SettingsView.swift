import SwiftUI
import ServiceManagement

/// The standard Settings window (MacEmissions › Settings…, ⌘,), in two tabs.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            ElectricitySettings()
                .tabItem { Label("Electricity", systemImage: "bolt.fill") }
        }
        .frame(width: 480)
    }
}

/// The menu bar item and opening at login.
private struct GeneralSettings: View {
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("menuBarMetric") private var menuBarMetric = MenuBarMetric.emissionsToday
    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                Picker("Menu Bar Shows", selection: $menuBarMetric) {
                    ForEach(MenuBarMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .disabled(!showInMenuBar)
            } footer: {
                Text("Emissions fall back to power when your region's carbon figure isn't set.")
            }

            Section {
                Toggle("Open at Login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, wanted in
                        do {
                            if wanted { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        } catch {}
                        // Show what the system actually did (the user may have declined).
                        let actual = SMAppService.mainApp.status == .enabled
                        if actual != opensAtLogin { opensAtLogin = actual }
                    }
            } footer: {
                Text("Today's totals count only while MacEmissions is running.")
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Where the Mac is, and the carbon intensity of its electricity.
private struct ElectricitySettings: View {
    @Environment(GridModel.self) private var grid

    var body: some View {
        @Bindable var grid = grid

        Form {
            Section {
                Picker("Region", selection: $grid.regionOverride) {
                    Text(automaticTitle).tag("")
                    Divider()
                    ForEach(GridData.regions, id: \.code) { region in
                        Text(region.name).tag(region.code)
                    }
                }
                if let country = grid.regionCode, GridData.states[country] != nil {
                    Picker(GridData.stateLabel(for: country), selection: $grid.stateOverride) {
                        Text(automaticStateTitle).tag("")
                        Text("National Average").tag(GridModel.nationalAverage)
                        Divider()
                        ForEach(GridData.stateList(for: country), id: \.code) { state in
                            Text(state.name).tag(state.code)
                        }
                    }
                    if country == "US", grid.stateOverride != GridModel.nationalAverage {
                        TextField("ZIP Code", text: $grid.zipOverride,
                                  prompt: Text(grid.locationAccess == .allowed ? "From your location" : "Optional"))
                        LabeledContent("Grid Region", value: grid.gridName ?? "State average")
                    }
                }
                if grid.regionOverride.isEmpty { locationRow }
            } header: {
                Text("Location")
            } footer: {
                Text("Your location is used only to find your country, your state or province and, in the US, your grid region. Your coordinates, and the ZIP code found from them, aren't kept.")
            }

            Section {
                TextField("Your Own Figure (g CO₂e/kWh)", value: $grid.customIntensity, format: .number,
                          prompt: Text(grid.defaultIntensity?.formatted(.number.precision(.fractionLength(0))) ?? "Not set"))
            } header: {
                Text("Carbon Intensity")
            } footer: {
                Text("""
                    Leave this empty to use the average carbon intensity of your grid's electricity. Enter \
                    your own if your supplier publishes one.

                    Data: Ember (2026), with major processing by Our World in Data (countries); EPA eGRID (US); \
                    Environment and Climate Change Canada; Australian Government DCCEEW.
                    """)
            }
        }
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var automaticTitle: String {
        guard let code = grid.detectedRegion,
              let name = Locale.current.localizedString(forRegionCode: code) else { return "Automatic" }
        return "Automatic (\(name))"
    }

    private var automaticStateTitle: String {
        guard let name = grid.detectedState.flatMap({ state in grid.regionCode.flatMap { GridData.states[$0]?[state]?.name } }) else {
            return "Automatic (needs your location)"
        }
        return "Automatic (\(name))"
    }

    /// How the automatic region was found, and a way to turn location on.
    @ViewBuilder private var locationRow: some View {
        switch grid.locationAccess {
        case .notAsked:
            LabeledContent("Using this Mac's region setting") {
                Button("Use My Location…") { grid.requestLocationAccess() }
            }
        case .denied:
            LabeledContent("Location access is off") {
                Button("Open Location Settings…") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        case .allowed:
            LabeledContent("Found From", value: grid.detectedFromLocation ? "Your Location" : "This Mac's Region Setting")
        }
    }
}
