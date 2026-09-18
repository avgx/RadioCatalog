import Foundation

enum HTMLFetcher {
    static func get(_ url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        if let html = String(data: data, encoding: .utf8) {
            return html
        }
        return String(decoding: data, as: UTF8.self)
    }
}
