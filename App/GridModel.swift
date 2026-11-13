import Foundation
import CoreLocation
import Observation

/// Works out which country's electricity this Mac is using, and the carbon intensity and
/// price that go with it.
///
/// The country comes from Location Services when the user allows it (approximate accuracy is
/// enough), otherwise from the Mac's region setting. Only the country code is kept; the
/// coordinates are never stored. The user can override the country and both figures in Settings.
@MainActor @Observable
final class GridModel: NSObject, CLLocationManagerDelegate {
    enum LocationAccess { case notAsked, denied, allowed }

    /// Country found from the Mac's location, remembered between launches.
    private(set) var locatedRegion: String?
    /// US state found from the Mac's location (postal abbreviation), when it is in the US.
    private(set) var locatedState: String?
    /// EPA grid subregion found from the Mac's location, when it is in the US. The ZIP code
    /// used to find it is not kept.
    private(set) var locatedSubregion: String?
    /// Local utilities' residential price per kWh, found the same way from the ZIP code.
    private(set) var locatedPrice: Double?
    private(set) var locationAccess = LocationAccess.notAsked

    /// A country chosen by hand, or "" to detect it.
    var regionOverride: String { didSet { defaults.set(regionOverride, forKey: Keys.regionOverride) } }
    /// For the US: a state chosen by hand, "" to detect it, or `nationalAverage`.
    var stateOverride: String { didSet { defaults.set(stateOverride, forKey: Keys.stateOverride) } }
    static let nationalAverage = "national"
    /// For the US: a ZIP code typed by hand, or "" to use the Mac's location.
    var zipOverride: String { didSet { defaults.set(zipOverride, forKey: Keys.zipOverride) } }
    /// The user's own price per kWh, or nil to use the built-in figure.
    var customPrice: Double? { didSet { store(customPrice, forKey: Keys.customPrice) } }
    /// The user's own carbon intensity in g CO₂e/kWh, or nil to use the built-in figure.
    var customIntensity: Double? { didSet { store(customIntensity, forKey: Keys.customIntensity) } }

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private let geocoder = CLGeocoder()
    @ObservationIgnored private let defaults = UserDefaults.standard

    private enum Keys {
        static let locatedRegion = "locatedRegion"
        static let locatedState = "locatedState"
        static let regionOverride = "regionOverride"
        static let stateOverride = "stateOverride"
        static let locatedSubregion = "locatedSubregion"
        static let locatedPrice = "locatedPricePerKWh"
        static let zipOverride = "zipOverride"
        static let customPrice = "customPricePerKWh"
        static let customIntensity = "customGramsPerKWh"
    }

    override init() {
        let saved = UserDefaults.standard
        locatedRegion = saved.string(forKey: Keys.locatedRegion)
        locatedState = saved.string(forKey: Keys.locatedState)
        regionOverride = saved.string(forKey: Keys.regionOverride) ?? ""
        stateOverride = saved.string(forKey: Keys.stateOverride) ?? ""
        locatedSubregion = saved.string(forKey: Keys.locatedSubregion)
        locatedPrice = saved.object(forKey: Keys.locatedPrice) as? Double
        zipOverride = saved.string(forKey: Keys.zipOverride) ?? ""
        customPrice = saved.object(forKey: Keys.customPrice) as? Double
        customIntensity = saved.object(forKey: Keys.customIntensity) as? Double
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer   // enough to get the ZIP code right
        update(manager.authorizationStatus)
        if locationAccess == .notAsked { requestLocationAccess() }
    }

    /// Shows the system's location prompt (only the first time; macOS remembers the answer).
    func requestLocationAccess() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: Resolved figures

    /// The country found without a manual choice: location first, then the Mac's region setting.
    var detectedRegion: String? { locatedRegion ?? Locale.current.region?.identifier }
    var detectedFromLocation: Bool { locatedRegion != nil }
    var regionCode: String? { regionOverride.isEmpty ? detectedRegion : regionOverride }

    /// The US state found from location, if the Mac is in the US.
    var detectedState: String? {
        guard locatedRegion == "US", let state = locatedState, GridData.usStates[state] != nil else { return nil }
        return state
    }

    /// The US state whose figures are used, or nil for the national average (and outside the US).
    var stateCode: String? {
        guard regionCode == "US" else { return nil }
        switch stateOverride {
        case "": return detectedState
        case Self.nationalAverage: return nil
        default: return GridData.usStates[stateOverride] == nil ? nil : stateOverride
        }
    }

    /// Where ZIP-level figures come from: a ZIP code typed by hand, the Mac's location, or nowhere.
    private enum ZIPSource { case typed(String), located, none }

    private var zipSource: ZIPSource {
        guard regionCode == "US", stateOverride != Self.nationalAverage else { return .none }
        let typed = zipOverride.trimmingCharacters(in: .whitespaces)
        if typed.count == 5, Int(typed) != nil { return .typed(typed) }
        // A state picked by hand that isn't where the Mac is: the Mac's ZIP code doesn't apply.
        guard locatedRegion == "US", stateOverride.isEmpty || stateOverride == locatedState else { return .none }
        return .located
    }

    /// The EPA grid subregion whose carbon figure is used, or nil to use the state's or country's.
    var subregionCode: String? {
        let code: String? = switch zipSource {
        case .typed(let zip): GridData.subregion(forZIP: zip)
        case .located: locatedSubregion
        case .none: nil
        }
        return code.flatMap { GridData.subregions[$0] == nil ? nil : $0 }
    }

    /// The local utilities' price for the ZIP code, or nil to use the state's or country's.
    var zipPrice: Double? {
        switch zipSource {
        case .typed(let zip): GridData.price(forZIP: zip)
        case .located: locatedPrice
        case .none: nil
        }
    }

    var gridName: String? { subregionCode.flatMap { GridData.subregions[$0]?.name } }

    var placeName: String? {
        if let state = stateCode.flatMap({ GridData.usStates[$0] }) { return state.name }
        return regionCode.flatMap { Locale.current.localizedString(forRegionCode: $0) }
    }

    var defaultIntensity: Double? {
        if let grams = subregionCode.flatMap({ GridData.subregionGramsPerKWh($0) }) { return grams }
        if let state = stateCode.flatMap({ GridData.usStates[$0] }) { return state.gramsPerKWh }
        return regionCode.flatMap { GridData.gramsPerKWh[$0] }
    }

    var defaultPrice: Double? {
        if let zipPrice { return zipPrice }
        if let state = stateCode.flatMap({ GridData.usStates[$0] }) { return state.price }
        return regionCode.flatMap { GridData.prices[$0]?.amount }
    }

    var currencyCode: String {
        regionCode.flatMap { GridData.prices[$0]?.currency } ?? Locale.current.currency?.identifier ?? "USD"
    }

    var rates: GridRates {
        GridRates(regionCode: regionCode,
                  stateCode: stateCode,
                  placeName: placeName,
                  gridName: gridName,
                  gramsPerKWh: customIntensity ?? defaultIntensity,
                  pricePerKWh: customPrice ?? defaultPrice,
                  currencyCode: currencyCode)
    }

    // MARK: Location

    private func update(_ status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined: locationAccess = .notAsked
        case .denied, .restricted: locationAccess = .denied
        default:
            locationAccess = .allowed
            manager.requestLocation()
        }
    }

    private func lookUpCountry(of location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            guard let place = placemarks?.first, let code = place.isoCountryCode else { return }
            // For the US, `administrativeArea` is the state's postal abbreviation ("CA").
            let state = code == "US" ? place.administrativeArea : nil
            let zip = code == "US" ? place.postalCode.map { String($0.prefix(5)) } : nil
            Task { @MainActor in
                guard let self else { return }
                let subregion = zip.flatMap { GridData.subregion(forZIP: $0) }
                let price = zip.flatMap { GridData.price(forZIP: $0) }
                self.locatedPrice = price
                self.store(price, forKey: Keys.locatedPrice)
                self.locatedRegion = code
                self.locatedState = state
                self.locatedSubregion = subregion
                self.defaults.set(code, forKey: Keys.locatedRegion)
                self.defaults.set(state, forKey: Keys.locatedState)
                self.defaults.set(subregion, forKey: Keys.locatedSubregion)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.update(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in self.lookUpCountry(of: location) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep the last known country, or the Mac's region setting.
    }

    private func store(_ value: Double?, forKey key: String) {
        if let value { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
    }
}
