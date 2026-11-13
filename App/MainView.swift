import SwiftUI

/// The app's main window.
struct MainView: View {
    @Environment(PowerSampler.self) private var sampler

    var body: some View {
        Group {
            if let snapshot = sampler.snapshot {
                Form {
                    NowSection(snapshot: snapshot, chartHeight: 160)
                    EmissionsSection(snapshot: snapshot)
                    SourceSection(snapshot: snapshot)
                    SystemSection(snapshot: snapshot)
                }
                .formStyle(.grouped)
            } else {
                NoDataView(hasBattery: sampler.hasBattery)
            }
        }
        .frame(minWidth: 380, idealWidth: 420, minHeight: 440, idealHeight: 640)
    }
}
