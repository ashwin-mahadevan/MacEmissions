import SwiftUI

/// The app's main window.
struct MainView: View {
    @Environment(PowerSampler.self) private var sampler

    var body: some View {
        Group {
            if let snapshot = sampler.snapshot {
                Dashboard(snapshot: snapshot, days: sampler.days)
            } else {
                NoDataView(hasBattery: sampler.hasBattery)
            }
        }
        .frame(minWidth: 440, idealWidth: 760, minHeight: 400, idealHeight: 920)
    }
}

/// Everything the main window shows for one reading. Two columns when there's room, one when not.
struct Dashboard: View {
    var snapshot: PowerSnapshot
    var days: [DayRecord] = []

    private static let spacing: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 640
            let pair = wide ? AnyLayout(HStackLayout(alignment: .top, spacing: Self.spacing))
                            : AnyLayout(VStackLayout(spacing: Self.spacing))
            ScrollView {
                VStack(spacing: Self.spacing) {
                    pair {
                        HeroCard(snapshot: snapshot)
                        ElectricityCard(rates: snapshot.rates, priceText: snapshot.priceText)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    StatTiles(snapshot: snapshot, columns: wide ? 4 : 2)

                    ChartCard(snapshot: snapshot)

                    if !days.isEmpty { DailyCard(records: days) }

                    pair {
                        SourceCard(snapshot: snapshot)
                        MacCard(snapshot: snapshot)
                    }
                    .fixedSize(horizontal: false, vertical: true)

                    footnote
                }
                .padding(20)
                .frame(maxWidth: 920)
                .frame(maxWidth: .infinity)
            }
        }
        .animation(.default, value: snapshot.systemWatts)
    }

    private var footnote: some View {
        Group {
            if let measuredAt = snapshot.measuredAt {
                Text("Measured by macOS \(measuredAt, style: .relative) ago. Today's totals count only while MacEmissions is running.")
            } else {
                Text("Today's totals count only while MacEmissions is running.")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

#Preview("Dashboard") {
    Dashboard(snapshot: .preview, days: DayRecord.preview)
        .frame(width: 760, height: 900)
}
