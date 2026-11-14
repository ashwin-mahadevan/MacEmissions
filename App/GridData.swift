import Foundation

/// Built-in per-country figures for electricity, keyed by ISO 3166 two-letter code.
enum GridData {
    /// Carbon intensity of electricity generation, in grams of CO₂-equivalent per kWh.
    ///
    /// Source: Ember (2026), with major processing by Our World in Data, "Lifecycle carbon
    /// intensity of electricity generation", latest year. Lifecycle basis, all greenhouse gases.
    /// https://ourworldindata.org/grapher/carbon-intensity-electricity
    /// Fetched 2026-11-12. Licensed CC BY 4.0; credit as worded above.
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

    /// US states and DC, keyed by postal abbreviation.
    ///
    /// gramsPerKWh: EPA eGRID2023 (Revision 2), Summary Table 3 "State Output Emission Rates",
    /// total output CO₂e rate, converted from lb/MWh (× 0.45359237). This is the rate of power
    /// generated inside the state; it ignores imports, and counts combustion only, so it is not
    /// directly comparable with the lifecycle country figures above.
    /// https://www.epa.gov/egrid/summary-data
    static let usStates: [String: (name: String, gramsPerKWh: Double)] = [
        "AL": ("Alabama", 323.9), "AK": ("Alaska", 369.4), "AZ": ("Arizona", 312.6),
        "AR": ("Arkansas", 452.9), "CA": ("California", 179.1), "CO": ("Colorado", 494.9),
        "CT": ("Connecticut", 245.2), "DE": ("Delaware", 319.4),
        "DC": ("District of Columbia", 179.2), "FL": ("Florida", 357.9),
        "GA": ("Georgia", 325.4), "HI": ("Hawaii", 632.6), "ID": ("Idaho", 142.4),
        "IL": ("Illinois", 215.2), "IN": ("Indiana", 664.7), "IA": ("Iowa", 287.6),
        "KS": ("Kansas", 332.6), "KY": ("Kentucky", 792.4), "LA": ("Louisiana", 346.1),
        "ME": ("Maine", 143.7), "MD": ("Maryland", 236.9), "MA": ("Massachusetts", 376.5),
        "MI": ("Michigan", 361.7), "MN": ("Minnesota", 341.3), "MS": ("Mississippi", 375.7),
        "MO": ("Missouri", 659.8), "MT": ("Montana", 482.6), "NE": ("Nebraska", 465.3),
        "NV": ("Nevada", 292.0), "NH": ("New Hampshire", 125.3), "NJ": ("New Jersey", 213.3),
        "NM": ("New Mexico", 350.9), "NY": ("New York", 211.7),
        "NC": ("North Carolina", 284.1), "ND": ("North Dakota", 588.7), "OH": ("Ohio", 484.6),
        "OK": ("Oklahoma", 294.3), "OR": ("Oregon", 165.5), "PA": ("Pennsylvania", 293.9),
        "RI": ("Rhode Island", 381.0), "SC": ("South Carolina", 254.2),
        "SD": ("South Dakota", 152.2), "TN": ("Tennessee", 299.9), "TX": ("Texas", 349.8),
        "UT": ("Utah", 644.7), "VT": ("Vermont", 23.7), "VA": ("Virginia", 244.8),
        "WA": ("Washington", 120.9), "WV": ("West Virginia", 893.1),
        "WI": ("Wisconsin", 527.8), "WY": ("Wyoming", 831.6),
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

    private static let zipSubregions = ZIPTable(resource: "ZipSubregions")

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

    /// Canadian provinces and territories: grid electricity consumption intensity, g CO₂e per kWh.
    ///
    /// Environment and Climate Change Canada, "Canada's Greenhouse Gas Offset Credit System:
    /// Emission Factors and Reference Values", Version 4.0 (September 2026), Table 5.4, which
    /// draws on the National Inventory Report 1990–2024.
    /// https://publications.gc.ca/collections/collection_2026/eccc/En84-294-2026-eng.pdf
    static let canadianProvinces: [String: (name: String, gramsPerKWh: Double)] = [
        "AB": ("Alberta", 346), "BC": ("British Columbia", 18), "MB": ("Manitoba", 3.0),
        "NB": ("New Brunswick", 375), "NL": ("Newfoundland and Labrador", 17),
        "NS": ("Nova Scotia", 628), "NT": ("Northwest Territories", 490), "NU": ("Nunavut", 760),
        "ON": ("Ontario", 73), "PE": ("Prince Edward Island", 265), "QC": ("Quebec", 2.6),
        "SK": ("Saskatchewan", 581), "YT": ("Yukon", 134),
    ]

    /// Australian states and territories: scope 2 location-based factor for purchased grid
    /// electricity, converted from kg CO₂-e per kWh.
    ///
    /// Australian Government DCCEEW, "National Greenhouse Accounts Factors 2026", Table 1
    /// (7 October 2026 revision). New South Wales and the ACT share a figure. Western Australia
    /// uses the South West Interconnected System (the North West system is 560), and the
    /// Northern Territory uses the Darwin–Katherine system.
    /// https://www.dcceew.gov.au/climate-change/publications/national-greenhouse-accounts-factors-2026
    static let australianStates: [String: (name: String, gramsPerKWh: Double)] = [
        "ACT": ("Australian Capital Territory", 600), "NSW": ("New South Wales", 600),
        "NT": ("Northern Territory", 550), "QLD": ("Queensland", 650), "SA": ("South Australia", 210),
        "TAS": ("Tasmania", 210), "VIC": ("Victoria", 740), "WA": ("Western Australia", 450),
    ]

    /// Countries with figures for their states, provinces or territories, keyed by country
    /// and then by the abbreviation the system's geocoder reports ("CA", "ON", "NSW").
    static let states: [String: [String: (name: String, gramsPerKWh: Double)]] = [
        "US": usStates, "CA": canadianProvinces, "AU": australianStates,
    ]

    /// What a country calls its states, for labels.
    static func stateLabel(for country: String) -> String {
        switch country {
        case "CA": "Province"
        case "AU": "State or Territory"
        default: "State"
        }
    }

    static func stateList(for country: String) -> [(code: String, name: String)] {
        (states[country] ?? [:])
            .map { (code: $0.key, name: $0.value.name) }
            .sorted { $0.name < $1.name }
    }

    /// Every region with a carbon-intensity figure, sorted by its name in the user's language.
    static let regions: [(code: String, name: String)] = gramsPerKWh.keys
        .map { (code: $0, name: Locale.current.localizedString(forRegionCode: $0) ?? $0) }
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
}
