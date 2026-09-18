import Foundation

public struct Genre: Codable, Sendable, Identifiable, Hashable, CustomStringConvertible {
    public let slug: String
    public let url: String
    public let title: String

    public var id: String { slug }

    public var description: String {
        "\(slug)|\(title)|\(url)"
    }

    public init(slug: String, url: String, title: String) {
        self.slug = slug
        self.url = url
        self.title = title
    }
}
