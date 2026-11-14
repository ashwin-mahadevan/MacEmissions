# MacEmissions

A Mac app, menu bar item and desktop widget that show how many watts this Mac is using, whether
they come from the power adapter or the battery, and an estimate of the carbon emissions of that
electricity. Native SwiftUI, sandboxed, public APIs only — built for the Mac App Store.

## Layout

- `App/` — the main window, menu bar panel and Settings; `PowerSampler` (a reading every 2 s);
  `GridModel` (finds the grid and its carbon figure); `GridData` (the built-in tables)
- `Widget/` — WidgetKit extension (small, medium, large)
- `Shared/` — code both use: the battery reader, `PowerSnapshot`, `GridRates`, the history chart
- `project.yml` — the Xcode project definition; the `.xcodeproj` is generated, not checked in

## Build

```bash
mise install
mise exec -- xcodegen generate
xcodebuild -project MacEmissions.xcodeproj -scheme MacEmissions -configuration Release -derivedDataPath build/dev build
```

Or run `xcodegen generate` and open `MacEmissions.xcodeproj` in Xcode.

## Where the numbers come from

- Total draw, adapter and battery figures: the `AppleSmartBattery` entry in the I/O Registry.
  macOS refreshes these about once a minute. Macs without a battery report nothing.
- CPU load: `host_statistics`. Thermal state and Low Power Mode: `ProcessInfo`.
- Emissions: energy used × the carbon intensity of the local grid (g CO₂e per kWh), using the
  most local figure available. All figures are yearly averages, not the live mix.
- Countries: `GridData.gramsPerKWh`, the latest year of "Lifecycle carbon intensity of electricity
  generation" from Ember (2026), with major processing by Our World in Data, fetched 2026-11-12
  (CC BY 4.0).
- US: per EPA eGRID subregion (27 parts of the grid), found from the ZIP code with EPA's Power
  Profiler ZIP Code Tool v14.3 (eGRID2023), bundled in compact form as `App/ZipSubregions.txt`.
  Where EPA lists several subregions for a ZIP code, the first is used. If the ZIP code is
  unknown, the state's eGRID2023 rate is used instead.
- Canada: per province and territory, from Environment and Climate Change Canada's "Emission
  Factors and Reference Values" v4.0 (September 2026), Table 5.4 (consumption intensity).
- Australia: per state and territory, from DCCEEW's "National Greenhouse Accounts Factors 2026",
  Table 1 (scope 2, location-based). Western Australia uses the SWIS figure and the Northern
  Territory the Darwin–Katherine one.
- The sources count differently (lifecycle for countries; combustion or scope 2 for the US,
  Canada and Australia), so figures from different tables are not directly comparable.
- Place: Location Services at kilometre accuracy, reverse-geocoded to a country code, a state or
  province and, in the US, a ZIP code. The ZIP code is turned into a grid subregion and
  discarded; only the country, state and subregion are stored. Without location access the app uses the Mac's
  region setting (country only), and the user can pick a country and state and type a ZIP code.
- Energy is added up per calendar day, only while the app is running, and survives relaunches.
  The last 30 days are kept, each with the carbon intensity that applied that day.

The app writes its latest reading to the app group container for the widget. If the app isn't
running, the widget takes its own reading and reuses the app's last electricity figures.

## App Store submission

Both targets use automatic signing with the team in `project.yml`. Archive with
`xcodebuild archive -allowProvisioningUpdates`, then `xcodebuild -exportArchive` with
`ExportOptions.plist`, or use Product › Archive in Xcode.

## Licence

The code is under the MIT licence; see `LICENSE`. The bundled data comes from the sources named
above and stays under their terms.
