import Foundation

struct Country: Codable, Sendable, Identifiable, Hashable, CustomStringConvertible {
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

extension Country {
    func html() async throws -> String {
        guard let url = URL(string: self.url) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return html
    }
}
