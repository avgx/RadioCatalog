import Foundation
import TopRadioCatalog

final class HarvestState: @unchecked Sendable {
    let io: HarvestIO
    private let lock = NSLock()

    private var _stopRequested = false
    private var _rating: [RatingEntry] = []
    private var _genres: [Genre] = []
    private var _countries: [Country] = []
    private var _cities: [City] = []
    private var _stationRefs: [StationRef] = []
    private var _cityRefs: [CityStationRef] = []
    private var _webStations: [String: WebStation] = [:]
    private var _cityStations: [String: CityStation] = [:]

    init(io: HarvestIO) {
        self.io = io
    }

    var stopRequested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _stopRequested
    }

    func requestStop() {
        lock.lock()
        _stopRequested = true
        lock.unlock()
    }

    var rating: [RatingEntry] {
        get { withLock { _rating } }
        set { withLock { _rating = newValue } }
    }

    var genres: [Genre] {
        get { withLock { _genres } }
        set { withLock { _genres = newValue } }
    }

    var countries: [Country] {
        get { withLock { _countries } }
        set { withLock { _countries = newValue } }
    }

    var cities: [City] {
        get { withLock { _cities } }
        set { withLock { _cities = newValue } }
    }

    var webCount: Int { withLock { _webStations.count } }
    var cityCount: Int { withLock { _cityStations.count } }

    static func cityKey(citySlug: String, slug: String) -> String {
        "\(citySlug)/\(slug)"
    }

    func putWeb(_ station: WebStation) {
        withLock { _webStations[station.slug] = station }
    }

    func containsWeb(_ slug: String) -> Bool {
        withLock { _webStations[slug] != nil }
    }

    func putCity(_ station: CityStation) {
        withLock {
            _cityStations[Self.cityKey(citySlug: station.citySlug, slug: station.slug)] = station
        }
    }

    func containsCity(citySlug: String, slug: String) -> Bool {
        withLock { _cityStations[Self.cityKey(citySlug: citySlug, slug: slug)] != nil }
    }

    func appendStationRefs(_ refs: [StationRef]) {
        withLock { _stationRefs.append(contentsOf: refs) }
    }

    func appendCityRefs(_ refs: [CityStationRef]) {
        withLock { _cityRefs.append(contentsOf: refs) }
    }

    func dumpAll() {
        let snapshot = withLock {
            Snapshot(
                rating: _rating,
                genres: _genres,
                countries: _countries,
                cities: _cities,
                stationRefs: _stationRefs,
                cityRefs: _cityRefs,
                webStations: Array(_webStations.values).sorted { $0.slug < $1.slug },
                cityStations: Array(_cityStations.values).sorted {
                    if $0.citySlug != $1.citySlug { return $0.citySlug < $1.citySlug }
                    return $0.slug < $1.slug
                }
            )
        }

        print("dumping harvest state…")
        saveIfNeeded(snapshot.rating, as: "rating.json")
        saveIfNeeded(snapshot.genres, as: "genres.json")
        saveIfNeeded(snapshot.countries, as: "countries.json")
        saveIfNeeded(snapshot.cities, as: "cities.json")
        saveIfNeeded(snapshot.stationRefs, as: "stations.json")
        saveIfNeeded(snapshot.cityRefs, as: "cstations.json")
        saveIfNeeded(snapshot.webStations, as: "webStations.json")
        saveIfNeeded(snapshot.cityStations, as: "cityStations.json")
    }

    func saveWeb() throws {
        let snapshot = withLock {
            (
                Array(_webStations.values).sorted { $0.slug < $1.slug },
                _stationRefs
            )
        }
        try io.save(snapshot.0, as: "webStations.json")
        try io.save(snapshot.1, as: "stations.json")
    }

    func saveCity() throws {
        let snapshot = withLock {
            (
                Array(_cityStations.values).sorted {
                    if $0.citySlug != $1.citySlug { return $0.citySlug < $1.citySlug }
                    return $0.slug < $1.slug
                },
                _cityRefs
            )
        }
        try io.save(snapshot.0, as: "cityStations.json")
        try io.save(snapshot.1, as: "cstations.json")
    }

    func loadExistingWeb() throws {
        if let loaded = try io.load([WebStation].self, from: "webStations.json") {
            withLock {
                for station in loaded {
                    _webStations[station.slug] = station
                }
            }
            print("resumed webStations: \(webCount)")
        }
        if let loaded = try io.load([StationRef].self, from: "stations.json") {
            withLock { _stationRefs = loaded }
        }
    }

    func loadExistingCity() throws {
        if let loaded = try io.load([CityStation].self, from: "cityStations.json") {
            withLock {
                for station in loaded {
                    _cityStations[Self.cityKey(citySlug: station.citySlug, slug: station.slug)] = station
                }
            }
            print("resumed cityStations: \(cityCount)")
        }
        if let loaded = try io.load([CityStationRef].self, from: "cstations.json") {
            withLock { _cityRefs = loaded }
        }
    }

    private struct Snapshot {
        let rating: [RatingEntry]
        let genres: [Genre]
        let countries: [Country]
        let cities: [City]
        let stationRefs: [StationRef]
        let cityRefs: [CityStationRef]
        let webStations: [WebStation]
        let cityStations: [CityStation]
    }

    private func saveIfNeeded<T: Encodable>(_ value: [T], as name: String) {
        guard !value.isEmpty else { return }
        try? io.save(value, as: name)
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }
}
