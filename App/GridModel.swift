import Foundation
import CoreLocation
import Observation

/// Works out which electricity grid this Mac is on, and the carbon intensity that goes with it.
///
/// The country comes from Location Services when the user allows it (approximate accuracy is
/// enough), otherwise from the Mac's region setting. Only the country code is kept; the
/// coordinates are never stored. The user can override the country and both figures in Settings.
@MainActor @Observable
final class GridModel: NSObject, CLLocationManagerDelegate {
    enum LocationAccess { case notAsked, denied, allowed }

    /// Country found from the Mac's location, remembered between launches.
    private(set) var locatedRegion: String?
    /// State, province or territory found from the Mac's location (its abbreviation).
    private(set) var locatedState: String?
    /// EPA grid subregion found from the Mac's location, when it is in the US. The ZIP code
    /// used to find it is not kept.
    private(set) var locatedSubregion: String?
    private(set) var locationAccess = LocationAccess.notAsked

    /// A country chosen by hand, or "" to detect it.
    var regionOverride: String { didSet { defaults.set(regionOverride, forKey: Keys.regionOverride) } }
    /// A state or province chosen by hand, "" to detect it, or `nationalAverage`.
    var stateOverride: String { didSet { defaults.set(stateOverride, forKey: Keys.stateOverride) } }
    static let nationalAverage = "national"
    /// For the US: a ZIP code typed by hand, or "" to use the Mac's location.
    var zipOverride: String { didSet { defaults.set(zipOverride, forKey: Keys.zipOverride) } }
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
        static let zipOverride = "zipOverride"
        static let customIntensity = "customGramsPerKWh"
    }

    override init() {
        let saved = UserDefaults.standard
        locatedRegion = saved.string(forKey: Keys.locatedRegion)
        locatedState = saved.string(forKey: Keys.locatedState)
        regionOverride = saved.string(forKey: Keys.regionOverride) ?? ""
        stateOverride = saved.string(forKey: Keys.stateOverride) ?? ""
        locatedSubregion = saved.string(forKey: Keys.locatedSubregion)
        zipOverride = saved.string(forKey: Keys.zipOverride) ?? ""
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

    /// The states of the country in use, or nil if there are no figures below country level.
    private var states: [String: (name: String, gramsPerKWh: Double)]? {
        regionCode.flatMap { GridData.states[$0] }
    }

    /// The state or province found from location, if the Mac is in the country in use.
    var detectedState: String? {
        guard locatedRegion == regionCode, let state = locatedState, states?[state] != nil else { return nil }
        return state
    }

    /// The state or province whose figures are used, or nil for the national average.
    var stateCode: String? {
        guard let states else { return nil }
        switch stateOverride {
        case "": return detectedState
        case Self.nationalAverage: return nil
        default: return states[stateOverride] == nil ? nil : stateOverride
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

    var gridName: String? { subregionCode.flatMap { GridData.subregions[$0]?.name } }

    var placeName: String? {
        if let state = stateCode.flatMap({ states?[$0] }) { return state.name }
        return regionCode.flatMap { Locale.current.localizedString(forRegionCode: $0) }
    }

    var defaultIntensity: Double? {
        if let grams = subregionCode.flatMap({ GridData.subregionGramsPerKWh($0) }) { return grams }
        if let state = stateCode.flatMap({ states?[$0] }) { return state.gramsPerKWh }
        return regionCode.flatMap { GridData.gramsPerKWh[$0] }
    }

    var rates: GridRates {
        GridRates(regionCode: regionCode,
                  stateCode: stateCode,
                  placeName: placeName,
                  gridName: gridName,
                  gramsPerKWh: customIntensity ?? defaultIntensity)
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
            // `administrativeArea` is the state's or province's abbreviation ("CA", "ON", "NSW").
            let state = place.administrativeArea
            let zip = code == "US" ? place.postalCode.map { String($0.prefix(5)) } : nil
            Task { @MainActor in
                guard let self else { return }
                let subregion = zip.flatMap { GridData.subregion(forZIP: $0) }
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
