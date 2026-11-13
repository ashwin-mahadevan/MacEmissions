import Foundation

/// Built-in per-country figures for electricity, keyed by ISO 3166 two-letter code.
enum GridData {
    /// Carbon intensity of electricity generation, in grams of CO₂-equivalent per kWh.
    ///
    /// Source: Our World in Data, "Carbon intensity of electricity generation"
    /// (data from Ember and the Energy Institute), latest year, labelled 2025.
    /// https://ourworldindata.org/grapher/carbon-intensity-electricity
    /// Fetched 2026-11-12. Check the dataset's licence and attribution wording before release.
    static let gramsPerKWh: [String: Double] = [
        "AF": 131.31, "AL": 25.18, "DZ": 632.94, "AO": 185.38, "AG": 594.6, "AR": 346, "AM": 211.93,
        "AU": 525.18, "AT": 116.91, "AZ": 631.9, "BS": 653.33, "BH": 902.24, "BD": 696.13, "BB": 594.6,
        "BY": 309.25, "BE": 149.82, "BZ": 170.21, "BJ": 584.16, "BT": 23.64, "BO": 481.29, "BA": 570.64,
        "BW": 851.31, "BR": 109.95, "BN": 892.09, "BG": 275.55, "BF": 562.13, "BI": 183.67, "KH": 498.87,
        "CM": 225.9, "CA": 190.72, "CV": 461.54, "TD": 621.62, "CL": 289.49, "CN": 525.34, "CO": 186.81,
        "KM": 642.86, "CG": 716.12, "CR": 24.2, "CI": 405.01, "HR": 158.5, "CU": 642.82, "CY": 489,
        "CZ": 401.46, "CD": 27.64, "DK": 114.41, "DJ": 450, "DM": 600, "DO": 537.48, "TL": 666.67,
        "EC": 159.02, "EG": 563.23, "SV": 139.32, "GQ": 644.3, "ER": 577.78, "EE": 319.15, "SZ": 131.15,
        "ET": 23.08, "FJ": 278.26, "FI": 57.47, "FR": 41.44, "GF": 244.9, "GA": 523.08, "GM": 666.67,
        "GE": 145.93, "DE": 329.65, "GH": 468.89, "GR": 315.09, "GL": 150, "GD": 666.67, "GT": 301.46,
        "GN": 181.14, "GW": 625, "GY": 644.93, "HT": 534.88, "HN": 322.12, "HU": 163.02, "IS": 27.82,
        "IN": 670.13, "ID": 680.25, "IR": 659.53, "IQ": 683.1, "IE": 256.54, "IL": 492.69, "IT": 284.78,
        "JM": 563.01, "JP": 477.26, "JO": 529.79, "KZ": 805.32, "KE": 95.44, "KI": 500, "XK": 900.94,
        "KW": 635.31, "KG": 152.73, "LA": 232.08, "LV": 138.76, "LB": 389.51, "LS": 20.83, "LR": 315.79,
        "LY": 826.83, "LT": 138.36, "LU": 123.38, "MG": 432.1, "MW": 54.65, "MY": 601.97, "MV": 611.77,
        "ML": 538.59, "MT": 484.02, "MR": 512.08, "MU": 642.23, "MX": 474.02, "MD": 633.12, "MN": 816.31,
        "ME": 264.23, "MA": 596.4, "MZ": 129.36, "MM": 502.99, "NA": 48.78, "NR": 600, "NP": 24.26,
        "NL": 253.56, "NC": 560.9, "NZ": 92.76, "NI": 300.89, "NE": 673.68, "NG": 455.71, "KP": 340.59,
        "MK": 441.35, "NO": 28.11, "OM": 544.47, "PK": 346.56, "PS": 414.14, "PA": 221.15, "PG": 513.74,
        "PY": 24.7, "PE": 238.25, "PH": 588.29, "PL": 588.6, "PT": 127.91, "PR": 654.66, "QA": 581.52,
        "RO": 250.75, "RU": 449.73, "RW": 353.98, "KN": 608.7, "LC": 650, "VC": 600, "WS": 375,
        "ST": 555.56, "SA": 691.95, "SN": 539.97, "RS": 695.8, "SC": 555.56, "SL": 47.62, "SG": 497.09,
        "SK": 94.85, "SI": 183.29, "SB": 636.36, "SO": 511.63, "ZA": 699.29, "KR": 417.06, "SS": 642.86,
        "ES": 153.6, "LK": 329.28, "SD": 153.69, "SR": 321.84, "SE": 35.26, "CH": 39.22, "SY": 706.19,
        "TW": 633.21, "TJ": 72.56, "TZ": 345.02, "TH": 545.74, "TG": 422.54, "TO": 571.43, "TT": 681.68,
        "TN": 560.29, "TR": 474.74, "TM": 1306.27, "UG": 58.52, "UA": 250.47, "AE": 467.51, "GB": 217.41,
        "US": 384.4, "UY": 80.4, "UZ": 1000, "VE": 85.86, "VU": 500, "VN": 460.73, "YE": 592.38,
        "ZM": 119.68, "ZW": 384.02,
    ]

    /// A typical household electricity price per kWh, in the local currency.
    ///
    /// PLACEHOLDERS: rough 2024–2025 figures written from memory, not taken from a dataset.
    /// Replace with sourced figures (for example EIA for the US, Eurostat for the EU) before
    /// release. Countries not listed have no default; the user enters their own price in Settings.
    /// The US figure is sourced: EIA Electric Power Monthly, Table 5.6.B, residential,
    /// January–August 2026 year-to-date.
    static let prices: [String: (amount: Double, currency: String)] = [
        "US": (0.1819, "USD"), "CA": (0.17, "CAD"), "GB": (0.26, "GBP"), "IE": (0.37, "EUR"),
        "FR": (0.25, "EUR"), "DE": (0.39, "EUR"), "ES": (0.25, "EUR"), "PT": (0.25, "EUR"),
        "IT": (0.33, "EUR"), "NL": (0.30, "EUR"), "BE": (0.35, "EUR"), "AT": (0.31, "EUR"),
        "FI": (0.22, "EUR"), "GR": (0.23, "EUR"), "CH": (0.29, "CHF"), "SE": (2.0, "SEK"),
        "NO": (1.5, "NOK"), "DK": (2.8, "DKK"), "PL": (1.1, "PLN"), "CZ": (7.5, "CZK"),
        "AU": (0.33, "AUD"), "NZ": (0.33, "NZD"), "JP": (31, "JPY"), "KR": (150, "KRW"),
        "CN": (0.55, "CNY"), "TW": (2.8, "TWD"), "SG": (0.30, "SGD"), "IN": (7, "INR"),
        "BR": (0.85, "BRL"), "IL": (0.64, "ILS"), "SA": (0.18, "SAR"), "ID": (1445, "IDR"),
        "TH": (4.2, "THB"), "VN": (2200, "VND"), "PH": (12, "PHP"),
    ]

    /// US states and DC, keyed by postal abbreviation.
    ///
    /// - gramsPerKWh: EPA eGRID2023 (Revision 2), Summary Table 3 "State Output Emission Rates",
    ///   total output CO₂e rate, converted from lb/MWh (× 0.45359237). This is the rate of power
    ///   generated inside the state; it ignores imports, and counts combustion only, so it is not
    ///   directly comparable with the lifecycle country figures above.
    ///   https://www.epa.gov/egrid/summary-data
    /// - price: EIA Electric Power Monthly, Table 5.6.B, average residential price,
    ///   January–August 2026 year-to-date (preliminary), in US dollars per kWh.
    ///   https://www.eia.gov/electricity/monthly/epm_table_grapher.php?t=epmt_5_6_b
    static let usStates: [String: (name: String, gramsPerKWh: Double, price: Double)] = [
        "AL": ("Alabama", 323.9, 0.1651), "AK": ("Alaska", 369.4, 0.2732), "AZ": ("Arizona", 312.6, 0.1536),
        "AR": ("Arkansas", 452.9, 0.1374), "CA": ("California", 179.1, 0.3258), "CO": ("Colorado", 494.9, 0.1680),
        "CT": ("Connecticut", 245.2, 0.2747), "DE": ("Delaware", 319.4, 0.1798),
        "DC": ("District of Columbia", 179.2, 0.2486), "FL": ("Florida", 357.9, 0.1532),
        "GA": ("Georgia", 325.4, 0.1548), "HI": ("Hawaii", 632.6, 0.4641), "ID": ("Idaho", 142.4, 0.1302),
        "IL": ("Illinois", 215.2, 0.1923), "IN": ("Indiana", 664.7, 0.1704), "IA": ("Iowa", 287.6, 0.1455),
        "KS": ("Kansas", 332.6, 0.1526), "KY": ("Kentucky", 792.4, 0.1420), "LA": ("Louisiana", 346.1, 0.1327),
        "ME": ("Maine", 143.7, 0.3023), "MD": ("Maryland", 236.9, 0.2131), "MA": ("Massachusetts", 376.5, 0.3019),
        "MI": ("Michigan", 361.7, 0.2173), "MN": ("Minnesota", 341.3, 0.1644), "MS": ("Mississippi", 375.7, 0.1506),
        "MO": ("Missouri", 659.8, 0.1428), "MT": ("Montana", 482.6, 0.1413), "NE": ("Nebraska", 465.3, 0.1292),
        "NV": ("Nevada", 292.0, 0.1336), "NH": ("New Hampshire", 125.3, 0.2691), "NJ": ("New Jersey", 213.3, 0.2409),
        "NM": ("New Mexico", 350.9, 0.1534), "NY": ("New York", 211.7, 0.2926),
        "NC": ("North Carolina", 284.1, 0.1494), "ND": ("North Dakota", 588.7, 0.1246), "OH": ("Ohio", 484.6, 0.1881),
        "OK": ("Oklahoma", 294.3, 0.1381), "OR": ("Oregon", 165.5, 0.1546), "PA": ("Pennsylvania", 293.9, 0.2113),
        "RI": ("Rhode Island", 381.0, 0.2905), "SC": ("South Carolina", 254.2, 0.1590),
        "SD": ("South Dakota", 152.2, 0.1458), "TN": ("Tennessee", 299.9, 0.1380), "TX": ("Texas", 349.8, 0.1603),
        "UT": ("Utah", 644.7, 0.1319), "VT": ("Vermont", 23.7, 0.2393), "VA": ("Virginia", 244.8, 0.1695),
        "WA": ("Washington", 120.9, 0.1442), "WV": ("West Virginia", 893.1, 0.1558),
        "WI": ("Wisconsin", 527.8, 0.1905), "WY": ("Wyoming", 831.6, 0.1401),
    ]

    /// EPA eGRID subregions: the parts of the US grid that EPA reports emissions for. Each has
    /// its total output CO₂e rate in lb/MWh, from eGRID2023 (Revision 2), Summary Table 1
    /// "Subregion Output Emission Rates". https://www.epa.gov/egrid/summary-data
    static let subregions: [String: (name: String, lbPerMWh: Double)] = [
        "AKGD": ("ASCC Alaska Grid", 905.109), "AKMS": ("ASCC Miscellaneous", 522.4),
        "AZNM": ("WECC Southwest", 706.189), "CAMX": ("WECC California", 429.983),
        "ERCT": ("ERCOT All", 736.629), "FRCC": ("FRCC All", 784.785),
        "HIMS": ("HICC Miscellaneous", 1133.294), "HIOA": ("HICC Oahu", 1498.947),
        "MROE": ("MRO East", 1404.963), "MROW": ("MRO West", 926.552),
        "NEWE": ("NPCC New England", 543.178), "NWPP": ("WECC Northwest", 635.267),
        "NYCW": ("NPCC NYC/Westchester", 865.744), "NYLI": ("NPCC Long Island", 1189.333),
        "NYUP": ("NPCC Upstate NY", 242.776), "PRMS": ("Puerto Rico Miscellaneous", 1548.53),
        "RFCE": ("RFC East", 599.17), "RFCM": ("RFC Michigan", 975.978), "RFCW": ("RFC West", 916.054),
        "RMPA": ("WECC Rockies", 1042.539), "SPNO": ("SPP North", 867.74), "SPSO": ("SPP South", 875.567),
        "SRMV": ("SERC Mississippi Valley", 741.741), "SRMW": ("SERC Midwest", 1248.582),
        "SRSO": ("SERC South", 846.007), "SRTV": ("SERC Tennessee Valley", 903.306),
        "SRVC": ("SERC Virginia/Carolina", 596.326),
    ]

    /// A subregion's carbon intensity in grams of CO₂e per kWh.
    static func subregionGramsPerKWh(_ code: String) -> Double? {
        subregions[code].map { $0.lbPerMWh * 0.45359237 }
    }

    /// The eGRID subregion a five-digit ZIP code is in, or nil if EPA doesn't list it.
    ///
    /// From EPA's Power Profiler ZIP Code Tool v14.3 (eGRID2023 data), bundled as
    /// `ZipSubregions.txt`: one line per run of consecutive listed ZIP codes sharing a
    /// subregion. Where EPA lists more than one subregion for a
    /// ZIP code (about 7% of them), this is the first one.
    /// https://www.epa.gov/egrid/power-profiler
    static func subregion(forZIP zip: String) -> String? {
        zipSubregions.value(forZIP: zip)
    }

    /// The average residential price per kWh, in US dollars, of the utilities serving a ZIP code,
    /// or nil if none is listed.
    ///
    /// From "U.S. Electric Utility Companies and Rates: Look-up by Zip Code (2025)", National
    /// Laboratory of the Rockies, built on EIA Form 861 data. https://data.openei.org/submissions/10259
    /// Bundled as `ZipPrices.txt` in hundredths of a cent. Each utility has one average rate for
    /// its whole territory, matched to its "likely" ZIP codes. Only bundled-service rates are
    /// used (delivery-only rates leave out the energy itself), and where several utilities serve
    /// a ZIP code their rates are averaged without weighting.
    static func price(forZIP zip: String) -> Double? {
        zipPrices.value(forZIP: zip).flatMap { Double($0) }.map { $0 / 10_000 }
    }

    private static let zipSubregions = ZIPTable(resource: "ZipSubregions")
    private static let zipPrices = ZIPTable(resource: "ZipPrices")

    /// A bundled text file with one line per run of consecutive listed ZIP codes that share a
    /// value, as "first last value".
    private struct ZIPTable {
        private let ranges: [(first: Int, last: Int, value: String)]

        init(resource: String) {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "txt"),
                  let text = try? String(contentsOf: url, encoding: .utf8) else {
                ranges = []
                return
            }
            ranges = text.split(separator: "\n").compactMap { line in
                let parts = line.split(separator: " ")
                guard parts.count == 3, let first = Int(parts[0]), let last = Int(parts[1]) else { return nil }
                return (first, last, String(parts[2]))
            }
        }

        func value(forZIP zip: String) -> String? {
            guard zip.count == 5, let number = Int(zip) else { return nil }
            var low = 0, high = ranges.count - 1
            while low <= high {
                let middle = (low + high) / 2
                let range = ranges[middle]
                if number < range.first {
                    high = middle - 1
                } else if number > range.last {
                    low = middle + 1
                } else {
                    return range.value
                }
            }
            return nil
        }
    }

    static let usStateList: [(code: String, name: String)] = usStates
        .map { (code: $0.key, name: $0.value.name) }
        .sorted { $0.name < $1.name }

    /// Every region with a carbon-intensity figure, sorted by its name in the user's language.
    static let regions: [(code: String, name: String)] = gramsPerKWh.keys
        .map { (code: $0, name: Locale.current.localizedString(forRegionCode: $0) ?? $0) }
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
}
