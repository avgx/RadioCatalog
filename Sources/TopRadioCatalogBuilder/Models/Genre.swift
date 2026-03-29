import Foundation

struct Genre: Codable, Sendable, Identifiable, Hashable, CustomStringConvertible {
    let slug: String
    let url: String
    let title: String
    
    var id: String {
        slug
    }
    
    var description: String {
        "\(slug)|\(title)|\(url)"
    }
}
