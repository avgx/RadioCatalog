import Foundation
import TopRadioCatalog

final class StationsBuilder {
    let state: HarvestState
    private let flushEvery = 50
    private var unsavedCount = 0

    init(state: HarvestState) {
        self.state = state
    }

    func runWeb(genres: [Genre], countries: [Country]) async throws {
        for genre in genres {
            if state.stopRequested { return }
            try await parseGenrePage(genre: genre)
        }
        for country in countries {
            if state.stopRequested { return }
            try await parseCountryPage(country: country)
        }
        if unsavedCount > 0 {
            try state.saveWeb()
            unsavedCount = 0
        }
    }

    func runCity(cities: [City]) async throws {
        for city in cities {
            if state.stopRequested { return }
            try await parseCityPage(city: city)
        }
        if unsavedCount > 0 {
            try state.saveCity()
            unsavedCount = 0
        }
    }

    private func parseGenrePage(genre: Genre) async throws {
        print("parseGenrePage \(genre.slug)")
        guard let url = URL(string: genre.url) else { return }
        let html: String
        do {
            html = try await HTMLFetcher.get(url)
        } catch {
            print("failed \(url): \(error)")
            return
        }

        let stations = GenreStationsParser().parseStations(html: html, genre: genre)
        state.appendStationRefs(stations)
        for station in uniqueMissingWeb(stations) {
            if state.stopRequested { return }
            try await parseStationPage(ref: station)
        }
    }

    private func parseCountryPage(country: Country) async throws {
        print("parseCountryPage \(country.slug)")
        guard let url = URL(string: country.url) else { return }
        let html: String
        do {
            html = try await HTMLFetcher.get(url)
        } catch {
            print("failed \(url): \(error)")
            return
        }

        let (_, stations) = CountryPageParser().parse(html: html, country: country)
        state.appendStationRefs(stations)
        for station in uniqueMissingWeb(stations) {
            if state.stopRequested { return }
            try await parseStationPage(ref: station)
        }
    }

    private func parseStationPage(ref: StationRef) async throws {
        print("parseStationPage \(ref.slug)")
        guard let url = URL(string: ref.url) else { return }
        let html: String
        do {
            html = try await HTMLFetcher.get(url)
        } catch {
            print("failed \(url): \(error)")
            return
        }

        guard let station = WebStationParser().parseStation(html: html, fileURL: url) else {
            return
        }
        state.putWeb(station)
        try flushWebIfNeeded()
    }

    private func parseCityPage(city: City) async throws {
        print("parseCityPage \(city.slug)")
        guard let url = URL(string: city.url) else { return }
        let html: String
        do {
            html = try await HTMLFetcher.get(url)
        } catch {
            print("failed \(url): \(error)")
            return
        }

        let cityStations = CityPageParser().parse(html: html, citySlug: city.slug)
        state.appendCityRefs(cityStations)
        for station in uniqueMissingCity(cityStations) {
            if state.stopRequested { return }
            try await parseCityStationPage(ref: station, city: city)
        }
    }

    private func parseCityStationPage(ref: CityStationRef, city: City) async throws {
        print("parseCityStationPage \(city.slug)/\(ref.stationSlug)")
        guard let url = URL(string: ref.url) else { return }
        let html: String
        do {
            html = try await HTMLFetcher.get(url)
        } catch {
            print("failed \(url): \(error)")
            return
        }

        guard let station = CityStationParser().parseStation(
            html: html,
            fileURL: url,
            citySlug: city.slug,
            countrySlug: city.countrySlug,
            frequency: ref.frequency
        ) else {
            return
        }
        state.putCity(station)
        try flushCityIfNeeded()
    }

    private func uniqueMissingWeb(_ refs: [StationRef]) -> [StationRef] {
        var seen = Set<String>()
        var result: [StationRef] = []
        for ref in refs {
            if state.containsWeb(ref.slug) { continue }
            if seen.insert(ref.slug).inserted {
                result.append(ref)
            }
        }
        return result
    }

    private func uniqueMissingCity(_ refs: [CityStationRef]) -> [CityStationRef] {
        refs.filter { !state.containsCity(citySlug: $0.citySlug, slug: $0.stationSlug) }
    }

    private func flushWebIfNeeded() throws {
        unsavedCount += 1
        if unsavedCount >= flushEvery {
            try state.saveWeb()
            unsavedCount = 0
        }
    }

    private func flushCityIfNeeded() throws {
        unsavedCount += 1
        if unsavedCount >= flushEvery {
            try state.saveCity()
            unsavedCount = 0
        }
    }
}
