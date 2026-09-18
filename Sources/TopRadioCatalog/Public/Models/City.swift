import Foundation

public struct City: Codable, Sendable, Identifiable, Hashable, CustomStringConvertible {
    public let slug: String
    public let url: String
    public let title: String
    public let stationCount: Int
    public let countrySlug: String

    public var id: String { slug }

    public var description: String {
        "\(slug)|\(countrySlug)|\(title)|\(url)"
    }

    public init(
        slug: String,
        url: String,
        title: String,
        stationCount: Int,
        countrySlug: String
    ) {
        self.slug = slug
        self.url = url
        self.title = title
        self.stationCount = stationCount
        self.countrySlug = countrySlug
    }
}
