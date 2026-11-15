# App Store listing

Text for App Store Connect. Limits are in brackets.

## Name [30]

MacEmissions

Fallback if Apple rejects the name for using "Mac": Emissions Meter

## Subtitle [30]

Carbon footprint of your Mac

## Promotional text [170]

See how much power your Mac is drawing right now and what that means in carbon emissions, based on the electricity grid you're actually plugged into.

## Description [4000]

MacEmissions shows the carbon footprint of the electricity your Mac uses.

It reads how many watts your Mac is drawing, adds that up through the day, and turns it into an estimate of carbon emissions using the carbon intensity of your local electricity grid. A Mac in Vermont and a Mac in West Virginia can draw the same power and be responsible for very different emissions. MacEmissions shows you yours.

EMISSIONS FROM YOUR OWN GRID
• In the United States, your location is matched to one of 27 EPA eGRID subregions, down to the ZIP code.
• In Canada and Australia, figures are per province, state or territory.
• Everywhere else, the national average is used, for about 190 countries and regions.
• Know your supplier's own figure? Enter it in Settings.

EVERYWHERE YOU LOOK
• A dashboard with today's emissions, the rate you're emitting at now, energy used, and how clean your grid is.
• A menu bar item showing emissions today, emissions per hour or power, your choice.
• Desktop and Notification Center widgets in three sizes.
• A chart of the last 30 minutes of power use, and up to 30 days of daily history.

KNOW YOUR MAC
• Live power draw, from the adapter or the battery.
• Adapter wattage, battery level and charging status.
• CPU load, thermal state and Low Power Mode.

PRIVATE BY DESIGN
• No account, no analytics, no ads, no tracking.
• The app has no access to the network. All carbon figures are built in.
• Location is optional and used only to find your grid. Your coordinates are never stored. You can pick your region by hand instead.

GOOD TO KNOW
• Mac laptops report their real power draw. On desktop Macs (Mac mini, iMac, Mac Studio, Mac Pro), macOS doesn't report power use, so MacEmissions estimates it from Apple's published figures for your model and how busy the processor is, and labels it as an estimate.
• Emissions are estimates based on yearly average figures for your grid, not a live reading of the grid's mix.
• Totals are counted while the app is running. Turn on Open at Login to count the whole day.

Data sources: Ember (2026), with major processing by Our World in Data; US EPA eGRID; Environment and Climate Change Canada; Australian Government DCCEEW.

## Keywords [100]

carbon,co2,energy,power,watts,battery,climate,footprint,electricity,grid,menu bar,widget,green,usage

## URLs

- Support URL: https://ashwinm.com/MacEmissions
- Marketing URL: https://ashwinm.com/MacEmissions
- Privacy Policy URL: https://ashwinm.com/MacEmissions/privacy

## Other fields

- Copyright: 2026 Ashwin Mahadevan
- Primary category: Utilities
- Price: USD 4.99
- Age rating: 4+ (no restricted content)
- App Privacy: Data Not Collected

## Notes for App Review

On a Mac laptop, MacEmissions reads the power draw from the public IOKit AppleSmartBattery registry entry. Desktop Macs have no such entry, so the app estimates the draw from Apple's published idle and maximum wattage for the model (Apple Support power consumption pages) and CPU load, and labels it "Estimated". A desktop model not in the built-in table shows "No Power Data".

Location (When In Use) is requested once at first launch, only to find which electricity grid the Mac is on. It is reverse-geocoded with CLGeocoder to a country, a state or province and, in the US, a ZIP code that is matched to an EPA grid subregion using a table bundled in the app. Coordinates and the ZIP code are not stored, and the app has no network entitlement. If location is declined, the app uses the Mac's region setting, and the region can be chosen in Settings > Electricity.

No sign-in is needed. The widget is added from the desktop's Edit Widgets gallery.
