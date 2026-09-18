import Foundation

public struct WebStation: Codable, Sendable, Hashable {
    public let slug: String
    public let url: URL
    public let title: String

    public let country: String?
    public let genres: [String]

    public let homepage: URL?
    public let rating: String?

    public let image: URL?
    public let streams: [RadioStream]

    public var description: String {
        "\(slug)|\(title)|\(String(describing: homepage))|\(url)|\(streams)|\(String(describing: image))"
    }

    public init(
        slug: String,
        url: URL,
        title: String,
        country: String? = nil,
        genres: [String] = [],
        homepage: URL? = nil,
        rating: String? = nil,
        image: URL? = nil,
        streams: [RadioStream] = []
    ) {
        self.slug = slug
        self.url = url
        self.title = title
        self.country = country
        self.genres = genres
        self.homepage = homepage
        self.rating = rating
        self.image = image
        self.streams = streams
    }

    public func withStreams(_ streams: [RadioStream]) -> WebStation {
        WebStation(
            slug: slug,
            url: url,
            title: title,
            country: country,
            genres: genres,
            homepage: homepage,
            rating: rating,
            image: image,
            streams: streams
        )
    }
}
