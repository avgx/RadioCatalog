import Foundation

/// Assembled top-radio.ru catalog written as `tr-stations.json`.
public struct TopRadioDump: Codable, Sendable {
    public let countries: [Country]
    public let cities: [City]
    public let genres: [Genre]
    public let rating: [RatingEntry]
    public let webStations: [WebStation]
    public let cityStations: [CityStation]

    public init(
        countries: [Country],
        cities: [City],
        genres: [Genre],
        rating: [RatingEntry],
        webStations: [WebStation],
        cityStations: [CityStation]
    ) {
        self.countries = countries
        self.cities = cities
        self.genres = genres
        self.rating = rating
        self.webStations = webStations
        self.cityStations = cityStations
    }

    /// Dedupes by slug, drops non-playable streams, and drops cards that have none left.
    public static func assemble(
        countries: [Country],
        cities: [City],
        genres: [Genre],
        rating: [RatingEntry],
        webStations: [WebStation],
        cityStations: [CityStation]
    ) -> TopRadioDump {
        var webBySlug: [String: WebStation] = [:]
        webBySlug.reserveCapacity(webStations.count)
        for station in webStations {
            let playable = station.withStreams(station.streams.filter(\.isPlayable))
            guard !playable.streams.isEmpty else { continue }
            if webBySlug[playable.slug] == nil {
                webBySlug[playable.slug] = playable
            }
        }

        var cityByKey: [String: CityStation] = [:]
        cityByKey.reserveCapacity(cityStations.count)
        for station in cityStations {
            let playable = station.withStreams(station.streams.filter(\.isPlayable))
            guard !playable.streams.isEmpty else { continue }
            let key = "\(playable.citySlug)/\(playable.slug)"
            if cityByKey[key] == nil {
                cityByKey[key] = playable
            }
        }

        let webSorted = webBySlug.values.sorted { $0.slug < $1.slug }
        let citySorted = cityByKey.values.sorted {
            if $0.citySlug != $1.citySlug { return $0.citySlug < $1.citySlug }
            return $0.slug < $1.slug
        }

        return TopRadioDump(
            countries: countries,
            cities: cities,
            genres: genres,
            rating: rating,
            webStations: webSorted,
            cityStations: citySorted
        )
    }

    public func lookups() -> TopRadioLookups {
        TopRadioLookups(dump: self)
    }
}
