import SwiftUI

/// The panel that opens from the menu bar: the same sections as the main window, plus shortcuts.
struct DashboardView: View {
    @Environment(PowerSampler.self) private var sampler
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            if let snapshot = sampler.snapshot {
                Form {
                    NowSection(snapshot: snapshot)
                    EmissionsSection(snapshot: snapshot)
                    SourceSection(snapshot: snapshot)
                    SystemSection(snapshot: snapshot)
                }
                .formStyle(.grouped)
            } else {
                NoDataView(hasBattery: sampler.hasBattery)
            }
            Divider()
            HStack {
                Button("Open MacEmissions") {
                    openWindow(id: "main")
                    NSApp.activate()
                }
                SettingsLink { Text("Settings…") }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .padding(12)
        }
        .frame(width: 340, height: 560)
    }
}
