import Foundation

struct CityStation: Codable, Sendable {
    let slug: String
    let url: URL
    let title: String
    
    let citySlug: String
    let countrySlug: String
    let genres: [String]
    
    let homepage: URL?
    let rating: String?
    
    let image: URL?
    let streams: [Stream]
    
    var description: String {
        "\(slug)|\(title)|\(homepage)|\(url)|\(streams)|\(image)"
    }
}
