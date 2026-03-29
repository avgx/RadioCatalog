import Foundation

struct StationRef: Codable, Sendable, Hashable, CustomStringConvertible {
    let slug: String
    let url: String
    let title: String
    let genreSlug: String
    let countrySlug: String
    let id: String?
    
    var description: String {
        "\(slug)|\(title)|\(url)"
    }
}
