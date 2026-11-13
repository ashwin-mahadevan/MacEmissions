import SwiftUI
import Charts

/// Total watts over the last half hour.
///
/// With `showsAxes`, watts are labelled on the left and, when the grid's carbon intensity is
/// known, the same line is labelled in grams of CO₂e per hour on the right.
struct HistoryChart: View {
    var points: [HistoryPoint]
    var gramsPerKWh: Double? = nil
    var showsAxes = true

    var body: some View {
        Chart(points) { point in
            AreaMark(x: .value("Time", point.date), y: .value("Watts", point.watts))
                .interpolationMethod(.monotone)
                .foregroundStyle(LinearGradient(colors: [Color.green.opacity(0.35), Color.green.opacity(0.03)],
                                                startPoint: .top, endPoint: .bottom))
            LineMark(x: .value("Time", point.date), y: .value("Watts", point.watts))
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Color.green)
        }
        .chartYScale(domain: 0...top)
        .chartXScale(domain: window)
        .chartXAxis(showsAxes ? .visible : .hidden)
        .chartYAxis(showsAxes ? .visible : .hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .minute, count: 10)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let watts = value.as(Double.self) {
                        Text("\(watts.formatted(.number.precision(.fractionLength(0)))) W")
                    }
                }
            }
            if let gramsPerKWh {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let watts = value.as(Double.self) {
                            let grams = watts / 1000 * gramsPerKWh
                            Text("\(grams.formatted(.number.precision(.fractionLength(grams < 10 ? 1 : 0)))) g/h")
                        }
                    }
                }
            }
        }
        .accessibilityLabel("Power use over the last 30 minutes")
    }

    /// Always the half hour up to the latest point, so a new chart fills in from the right.
    private var window: ClosedRange<Date> {
        let end = points.last?.date ?? .now
        return end.addingTimeInterval(-30 * 60)...end
    }

    /// The top of the scale: a little above the highest point, so the line never touches the edge.
    private var top: Double {
        let peak = points.map(\.watts).max() ?? 0
        return max(5, peak * 1.2)
    }
}
