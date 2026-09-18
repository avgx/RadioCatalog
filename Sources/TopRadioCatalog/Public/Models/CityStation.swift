import Foundation

public struct CityStation: Codable, Sendable, Hashable {
    public let slug: String
    public let url: URL
    public let title: String

    public let citySlug: String
    public let countrySlug: String
    public let genres: [String]
    public let frequency: String?

    public let homepage: URL?
    public let rating: String?

    public let image: URL?
    public let streams: [RadioStream]

    public var description: String {
        "\(slug)|\(title)|\(citySlug)|\(frequency ?? "")|\(url)"
    }

    public init(
        slug: String,
        url: URL,
        title: String,
        citySlug: String,
        countrySlug: String,
        genres: [String] = [],
        frequency: String? = nil,
        homepage: URL? = nil,
        rating: String? = nil,
        image: URL? = nil,
        streams: [RadioStream] = []
    ) {
        self.slug = slug
        self.url = url
        self.title = title
        self.citySlug = citySlug
        self.countrySlug = countrySlug
        self.genres = genres
        self.frequency = frequency
        self.homepage = homepage
        self.rating = rating
        self.image = image
        self.streams = streams
    }

    public func withStreams(_ streams: [RadioStream]) -> CityStation {
        CityStation(
            slug: slug,
            url: url,
            title: title,
            citySlug: citySlug,
            countrySlug: countrySlug,
            genres: genres,
            frequency: frequency,
            homepage: homepage,
            rating: rating,
            image: image,
            streams: streams
        )
    }
}
