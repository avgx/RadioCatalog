import Foundation

struct RatingEntry: Codable, Sendable, Hashable, CustomStringConvertible {
    let position: Int
    let slug: String
    let url: String
    let title: String
    let rating: Int?
    
    var description: String {
        "\(position)|\(slug)|\(title)|\(rating ?? -1)|\(url)"
    }
}
