import SwiftUI
import Charts

/// Total watts over time, drawn with Swift Charts in the system tint colour.
struct HistoryChart: View {
    var points: [HistoryPoint]

    var body: some View {
        Chart(points) { point in
            AreaMark(x: .value("Time", point.date), y: .value("Watts", point.watts))
                .foregroundStyle(.tint.opacity(0.2))
            LineMark(x: .value("Time", point.date), y: .value("Watts", point.watts))
                .foregroundStyle(.tint)
        }
        .accessibilityLabel("Power use over the last 30 minutes")
    }
}
