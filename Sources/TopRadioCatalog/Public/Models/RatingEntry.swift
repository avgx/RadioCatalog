import Foundation

public struct RatingEntry: Codable, Sendable, Hashable, CustomStringConvertible {
    public let position: Int
    public let slug: String
    public let url: String
    public let title: String
    public let rating: Int?

    public var description: String {
        "\(position)|\(slug)|\(title)|\(rating ?? -1)|\(url)"
    }

    public init(
        position: Int,
        slug: String,
        url: String,
        title: String,
        rating: Int?
    ) {
        self.position = position
        self.slug = slug
        self.url = url
        self.title = title
        self.rating = rating
    }
}
