import Foundation
import TopRadioCatalog

struct CommandRunner {
    let state: HarvestState

    private var io: HarvestIO { state.io }

    func run(_ command: CLI.Command) async throws {
        switch command {
        case .rating:
            try await runRating()
        case .genres:
            try await runGenres()
        case .countries:
            try await runCountries()
        case .cities:
            try await runCities()
        case .web:
            try await runWeb()
        case .city:
            try await runCity()
        case .assemble:
            try assemble()
        case .all:
            try await runRating()
            try await runGenres()
            try await runCountries()
            try await runCities()
            try await runWeb()
            try await runCity()
            try ensureNotStopped()
            try assemble()
        }
    }

    private func ensureNotStopped() throws {
        if state.stopRequested {
            throw CancellationError()
        }
    }

    private func runRating() async throws {
        try ensureNotStopped()
        let builder = RatingBuilder()
        let rating = try await builder.run()
        state.rating = rating
        try io.save(rating, as: "rating.json")
        print("Rating saved: \(rating.count)")
    }

    private func runGenres() async throws {
        try ensureNotStopped()
        let builder = GenresBuilder()
        let genres = try await builder.run()
        state.genres = genres
        try io.save(genres, as: "genres.json")
        print("Genres saved: \(genres.count)")
    }

    private func runCountries() async throws {
        try ensureNotStopped()
        let builder = CountriesBuilder()
        let countries = try await builder.run()
        state.countries = countries
        try io.save(countries, as: "countries.json")
        print("Countries saved: \(countries.count)")
    }

    private func runCities() async throws {
        try ensureNotStopped()
        let countries = try loadCountries()
        let builder = CitiesBuilder()
        let cities = try await builder.run(countries: countries)
        state.countries = countries
        state.cities = cities
        try io.save(cities, as: "cities.json")
        print("Cities saved: \(cities.count)")
    }

    private func runWeb() async throws {
        try ensureNotStopped()
        let genres = try loadGenres()
        let countries = try loadCountries()
        try state.loadExistingWeb()
        let harvester = StationsBuilder(state: state)
        try await harvester.runWeb(genres: genres, countries: countries)
        try state.saveWeb()
        print("Web stations saved: \(state.webCount)")
    }

    private func runCity() async throws {
        try ensureNotStopped()
        let cities = try loadCities()
        try state.loadExistingCity()
        let harvester = StationsBuilder(state: state)
        try await harvester.runCity(cities: cities)
        try state.saveCity()
        print("City stations saved: \(state.cityCount)")
    }

    private func assemble() throws {
        let dump = TopRadioDump.assemble(
            countries: try io.load([Country].self, from: "countries.json") ?? [],
            cities: try io.load([City].self, from: "cities.json") ?? [],
            genres: try io.load([Genre].self, from: "genres.json") ?? [],
            rating: try io.load([RatingEntry].self, from: "rating.json") ?? [],
            webStations: try io.load([WebStation].self, from: "webStations.json") ?? [],
            cityStations: try io.load([CityStation].self, from: "cityStations.json") ?? []
        )
        try io.save(dump, as: "tr-stations.json", pretty: false)
        print(
            "assembled tr-stations.json: web=\(dump.webStations.count) city=\(dump.cityStations.count)"
        )
    }

    private func loadGenres() throws -> [Genre] {
        if !state.genres.isEmpty { return state.genres }
        guard let loaded = try io.load([Genre].self, from: "genres.json") else {
            throw HarvestError.missingInput("genres.json")
        }
        state.genres = loaded
        return loaded
    }

    private func loadCountries() throws -> [Country] {
        if !state.countries.isEmpty { return state.countries }
        guard let loaded = try io.load([Country].self, from: "countries.json") else {
            throw HarvestError.missingInput("countries.json")
        }
        state.countries = loaded
        return loaded
    }

    private func loadCities() throws -> [City] {
        if !state.cities.isEmpty { return state.cities }
        guard let loaded = try io.load([City].self, from: "cities.json") else {
            throw HarvestError.missingInput("cities.json")
        }
        state.cities = loaded
        return loaded
    }
}

enum HarvestError: Error, CustomStringConvertible {
    case missingInput(String)

    var description: String {
        switch self {
        case .missingInput(let name):
            return "Missing \(name). Run the preceding harvest command first."
        }
    }
}
