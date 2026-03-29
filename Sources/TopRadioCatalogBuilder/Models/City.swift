import Foundation

struct City: Codable, Sendable, Identifiable, Hashable, CustomStringConvertible {
    let slug: String
    let url: String
    let title: String
    let stationCount: Int
    let countrySlug: String
    
    var id: String {
        slug
    }
    
    var description: String {
        "\(slug)|\(countrySlug)|\(title)|\(url)"
    }
}

