import SwiftUI
import ServiceManagement

/// The standard Settings window (MacEmissions › Settings…, ⌘,).
struct SettingsView: View {
    @Environment(GridModel.self) private var grid
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @State private var opensAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        @Bindable var grid = grid

        Form {
            Section {
                Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                Toggle("Open at Login", isOn: $opensAtLogin)
                    .onChange(of: opensAtLogin) { _, wanted in
                        do {
                            if wanted { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                        } catch {}
                        // Show what the system actually did (the user may have declined).
                        let actual = SMAppService.mainApp.status == .enabled
                        if actual != opensAtLogin { opensAtLogin = actual }
                    }
            }

            Section {
                Picker("Region", selection: $grid.regionOverride) {
                    Text(automaticTitle).tag("")
                    Divider()
                    ForEach(GridData.regions, id: \.code) { region in
                        Text(region.name).tag(region.code)
                    }
                }
                if grid.regionCode == "US" {
                    Picker("State", selection: $grid.stateOverride) {
                        Text(automaticStateTitle).tag("")
                        Text("National Average").tag(GridModel.nationalAverage)
                        Divider()
                        ForEach(GridData.usStateList, id: \.code) { state in
                            Text(state.name).tag(state.code)
                        }
                    }
                    if grid.stateOverride != GridModel.nationalAverage {
                        TextField("ZIP Code", text: $grid.zipOverride,
                                  prompt: Text(grid.locationAccess == .allowed ? "From your location" : "Optional"))
                        LabeledContent("Grid Region", value: grid.gridName ?? "State average")
                    }
                }
                if grid.regionOverride.isEmpty { locationRow }

                TextField("Price per kWh (\(grid.currencyCode))", value: $grid.customPrice, format: .number,
                          prompt: Text(grid.defaultPrice?.formatted() ?? "Not set"))
                TextField("Carbon Intensity (g CO₂e per kWh)", value: $grid.customIntensity, format: .number,
                          prompt: Text(grid.defaultIntensity?.formatted(.number.precision(.fractionLength(0))) ?? "Not set"))
            } header: {
                Text("Electricity")
            } footer: {
                Text("""
                    Leave a field empty to use the figure for your region: the average carbon intensity of its \
                    electricity and a typical household price. Enter your own if you know your tariff. \
                    Data: Ember and Energy Institute via Our World in Data (countries); EPA eGRID, EIA and \
                    National Laboratory of the Rockies (US).
                    """)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var automaticTitle: String {
        guard let code = grid.detectedRegion,
              let name = Locale.current.localizedString(forRegionCode: code) else { return "Automatic" }
        return "Automatic (\(name))"
    }

    private var automaticStateTitle: String {
        guard let name = grid.detectedState.flatMap({ GridData.usStates[$0]?.name }) else {
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
