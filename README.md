# MacEmissions

A Mac app, menu bar item and desktop widget that show how many watts this Mac is using, whether
they come from the power adapter or the battery, and an estimate of the carbon emissions and cost
of that electricity. Native SwiftUI, sandboxed, public APIs only — built for the Mac App Store.

## Layout

- `App/` — the main window, menu bar panel and Settings; `PowerSampler` (a reading every 2 s);
  `GridModel` (finds the country and its electricity figures); `GridData` (the built-in tables)
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
- Emissions: energy used × the carbon intensity of the country's electricity (g CO₂e per kWh).
  The table in `GridData` is the latest year of "Carbon intensity of electricity generation" from
  Our World in Data (Ember and Energy Institute data), fetched 2026-11-12. It is a yearly national
  average, not the live mix.
- In the US, carbon intensity is per EPA eGRID subregion (27 parts of the grid), found from the
  ZIP code with EPA's Power Profiler ZIP Code Tool v14.3 (eGRID2023), bundled in compact form as
  `App/ZipSubregions.txt`. Where EPA lists several subregions for a ZIP code, the first is used.
  If the ZIP code is unknown, the state's eGRID2023 rate is used instead. eGRID rates count
  combustion only, so they are not directly comparable with the lifecycle country figures.
- In the US, price is per ZIP code where possible: the average residential rate of the utilities
  serving it, from "U.S. Electric Utility Companies and Rates: Look-up by Zip Code (2025)"
  (National Laboratory of the Rockies, from EIA Form 861), bundled as `App/ZipPrices.txt`. Each
  utility has one average rate for its whole territory; only bundled-service rates are used, and
  several utilities in one ZIP code are averaged without weighting. ZIP codes with no bundled
  rate (for example much of Texas) fall back to the state's residential price from EIA Electric
  Power Monthly Table 5.6.B (January–August 2026 year-to-date).
- Cost: energy used × a price per kWh. Outside the US, the built-in prices in `GridData` are rough
  placeholders and need replacing with sourced figures before release. Users can enter their own
  in Settings.
- Place: Location Services at kilometre accuracy, reverse-geocoded to a country code and, in the
  US, a state and ZIP code. The ZIP code is turned into a grid subregion and a price and
  discarded; only the country, state, subregion and price are stored. Without location access the app uses the Mac's
  region setting (country only), and the user can pick a country and state and type a ZIP code.
- Energy is added up per calendar day, only while the app is running, and survives relaunches.
  The last 30 days are kept, each with the carbon intensity and price that applied that day.

The app writes its latest reading to the app group container for the widget. If the app isn't
running, the widget takes its own reading and reuses the app's last electricity figures.

## App Store submission

Both targets use automatic signing with the team in `project.yml`. Archive with
`xcodebuild archive -allowProvisioningUpdates`, then `xcodebuild -exportArchive` with
`ExportOptions.plist`, or use Product › Archive in Xcode.

## Licence

The code is under the MIT licence; see `LICENSE`. The bundled data comes from the sources named
above and stays under their terms.
