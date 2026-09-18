import Foundation

/// In-memory indexes over a `TopRadioDump`. Web and city cards link by shared `slug`.
public struct TopRadioLookups: Sendable {
    public let dump: TopRadioDump
    public let webBySlug: [String: WebStation]
    public let localsBySlug: [String: [CityStation]]
    public let cityStationsByCity: [String: [CityStation]]
    public let citiesBySlug: [String: City]
    public let countriesBySlug: [String: Country]
    public let ratingBySlug: [String: RatingEntry]
    public let stations: [TopRadioStation]

    public init(dump: TopRadioDump) {
        self.dump = dump

        var webBySlug: [String: WebStation] = [:]
        webBySlug.reserveCapacity(dump.webStations.count)
        for station in dump.webStations {
            webBySlug[station.slug] = station
        }
        self.webBySlug = webBySlug

        var localsBySlug: [String: [CityStation]] = [:]
        var cityStationsByCity: [String: [CityStation]] = [:]
        localsBySlug.reserveCapacity(dump.cityStations.count)
        for station in dump.cityStations {
            localsBySlug[station.slug, default: []].append(station)
            cityStationsByCity[station.citySlug, default: []].append(station)
        }
        self.localsBySlug = localsBySlug
        self.cityStationsByCity = cityStationsByCity

        var citiesBySlug: [String: City] = [:]
        for city in dump.cities {
            citiesBySlug[city.slug] = city
        }
        self.citiesBySlug = citiesBySlug

        var countriesBySlug: [String: Country] = [:]
        for country in dump.countries {
            countriesBySlug[country.slug] = country
        }
        self.countriesBySlug = countriesBySlug

        var ratingBySlug: [String: RatingEntry] = [:]
        for entry in dump.rating {
            if ratingBySlug[entry.slug] == nil {
                ratingBySlug[entry.slug] = entry
            }
        }
        self.ratingBySlug = ratingBySlug

        let countryTitleToSlug = Dictionary(
            dump.countries.map { ($0.title, $0.slug) },
            uniquingKeysWith: { first, _ in first }
        )

        var slugs = Set(webBySlug.keys)
        slugs.formUnion(localsBySlug.keys)

        self.stations = slugs.sorted().compactMap { slug in
            let web = webBySlug[slug]
            let locals = localsBySlug[slug] ?? []
            guard web != nil || !locals.isEmpty else { return nil }

            let title = web?.title ?? locals.first?.title ?? slug
            var genres: [String] = web?.genres ?? []
            for local in locals {
                for genre in local.genres where !genres.contains(genre) {
                    genres.append(genre)
                }
            }

            var countrySlugs = Set(locals.map(\.countrySlug))
            if let countryName = web?.country, let mapped = countryTitleToSlug[countryName] {
                countrySlugs.insert(mapped)
            }

            return TopRadioStation(
                slug: slug,
                title: title,
                web: web,
                locals: locals,
                votes: ratingBySlug[slug]?.rating,
                genres: genres,
                citySlugs: locals.map(\.citySlug),
                countrySlugs: countrySlugs.sorted()
            )
        }
    }

    public func web(for cityStation: CityStation) -> WebStation? {
        webBySlug[cityStation.slug]
    }

    public func locals(for webStation: WebStation) -> [CityStation] {
        localsBySlug[webStation.slug] ?? []
    }

    public func web(forSlug slug: String) -> WebStation? {
        webBySlug[slug]
    }

    public func locals(forSlug slug: String) -> [CityStation] {
        localsBySlug[slug] ?? []
    }

    public func station(forSlug slug: String) -> TopRadioStation? {
        stations.first { $0.slug == slug }
    }
}
