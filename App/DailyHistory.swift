import SwiftUI
import Charts

/// One calendar day's energy, with the electricity figures that applied when it was last counted.
struct DayRecord: Codable, Equatable, Identifiable {
    var day: Date               // start of the day
    var energyWh: Double
    var gramsPerKWh: Double?
    var pricePerKWh: Double?
    var currencyCode: String?

    var id: Date { day }
    var emissionsGrams: Double? { gramsPerKWh.map { energyWh / 1000 * $0 } }
    var cost: Double? { pricePerKWh.map { energyWh / 1000 * $0 } }
}

/// The last 30 days of records, kept in the app's preferences.
enum DayStore {
    private static let key = "dailyRecords"
    static let daysKept = 30

    static func load() -> [DayRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([DayRecord].self, from: data) else { return [] }
        return records
    }

    static func save(_ records: [DayRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Replaces or adds today's record and drops days older than `daysKept`.
    static func updating(_ records: [DayRecord], with today: DayRecord) -> [DayRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -(daysKept - 1), to: today.day) ?? today.day
        var kept = records.filter { $0.day >= cutoff && $0.day != today.day }
        kept.append(today)
        return kept.sorted { $0.day < $1.day }
    }
}

/// A bar for each of the last 7 or 30 days: emissions when the grid is known, energy otherwise.
struct DailyCard: View {
    var records: [DayRecord]

    @AppStorage("historyDays") private var span = 7

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    CardTitle(title: showsEmissions ? "Emissions by Day" : "Energy by Day",
                              symbol: "calendar", color: .green)
                    Spacer()
                    if let summary {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    Picker("Period", selection: $span) {
                        Text("7 Days").tag(7)
                        Text("30 Days").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    .controlSize(.small)
                }
                Chart(visible) { record in
                    BarMark(x: .value("Day", record.day, unit: .day),
                            y: .value(showsEmissions ? "Grams of CO₂e" : "Watt-hours", value(of: record)),
                            width: .ratio(0.6))
                        .clipShape(.rect(cornerRadius: 3))
                        .foregroundStyle(Calendar.current.isDateInToday(record.day)
                                         ? Color.green : Color.green.opacity(0.55))
                }
                .chartXScale(domain: range)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: span == 7 ? 1 : 7)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: span == 7 ? .dateTime.weekday(.abbreviated)
                                                         : .dateTime.month(.abbreviated).day(),
                                       centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(showsEmissions ? amount.co2.text.replacingOccurrences(of: " CO₂e", with: "")
                                                    : amount.wattHours.text)
                            }
                        }
                    }
                }
                .frame(height: 110)
                .accessibilityLabel(showsEmissions ? "Emissions for each of the last \(span) days"
                                                   : "Energy for each of the last \(span) days")
            }
        }
    }

    /// The days on the chart: from `span` days ago up to the end of today.
    private var range: ClosedRange<Date> {
        let today = Calendar.current.startOfDay(for: .now)
        let start = Calendar.current.date(byAdding: .day, value: -(span - 1), to: today) ?? today
        let end = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        return start...end
    }

    private var visible: [DayRecord] { records.filter { range.contains($0.day) } }

    /// Emissions are charted only when every visible day has a carbon figure.
    private var showsEmissions: Bool { !visible.isEmpty && visible.allSatisfy { $0.gramsPerKWh != nil } }

    private func value(of record: DayRecord) -> Double {
        showsEmissions ? record.emissionsGrams ?? 0 : record.energyWh
    }

    private var summary: String? {
        guard !visible.isEmpty else { return nil }
        var parts = [showsEmissions ? visible.compactMap(\.emissionsGrams).reduce(0, +).co2.text
                                    : visible.map(\.energyWh).reduce(0, +).wattHours.text]
        let currencies = Set(visible.compactMap(\.currencyCode))
        if visible.allSatisfy({ $0.pricePerKWh != nil }), currencies.count == 1, let code = currencies.first {
            parts.append(visible.compactMap(\.cost).reduce(0, +).costText(code))
        }
        return "Total " + parts.joined(separator: " · ")
    }
}

extension DayRecord {
    /// Sample days for previews.
    static let preview: [DayRecord] = (0..<30).map { offset in
        let today = Calendar.current.startOfDay(for: .now)
        let day = Calendar.current.date(byAdding: .day, value: offset - 29, to: today) ?? today
        let energy: Double = 90 + 60 * sin(Double(offset) / 2.3) + Double((offset * 37) % 50)
        return DayRecord(day: day, energyWh: energy, gramsPerKWh: 195, pricePerKWh: 0.3258, currencyCode: "USD")
    }
}
