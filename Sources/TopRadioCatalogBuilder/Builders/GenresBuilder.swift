import Foundation

final class GenresBuilder {
    var genres: [Genre] = []
    
    func run() async throws {
        let html = try await html()
        try await parse(html)
        try await save()
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        try (try encoder.encode(self.genres)).write(to: URL(fileURLWithPath: "genres.json"))
        
        print("Genres saved: \(genres.count)")
    }
    
    func html() async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: .genres)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return html
    }
    
    func parse(_ html: String) async throws {
        let parser = GenreParser()
        let genres = parser.parseGenres(html: html)
        //print(genres.map({$0.description}).joined(separator: "\n"))
        self.genres = genres        
    }
}
