import Foundation

final class RatingBuilder {
    var rating: [RatingEntry] = []
    
    func run() async throws {
        let html = try await html()
        try await parse(html)
        try await save()
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        try (try encoder.encode(self.rating)).write(to: URL(fileURLWithPath: "rating.json"))
        
        print("Rating saved: \(rating.count)")
    }
    
    func html() async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: .rating)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return html
    }
    
    func parse(_ html: String) async throws {
        let parser = RatingParser()
        let ratings: [RatingEntry] = parser.parse(html: html)
        print(ratings.map({$0.description}).joined(separator: "\n"))
        self.rating.append(contentsOf: ratings)
        
        /// докачка ajax
        let ratings100: [RatingEntry] = try await fetchAllRatings()
        print(ratings100.map({$0.description}).joined(separator: "\n"))
        self.rating.append(contentsOf: ratings100)
    }
    
    func fetchAllRatings() async throws -> [RatingEntry] {
        
        var all: [RatingEntry] = []
        
        let parser = RatingParser()
        
        // 1. первая страница уже распарсена ранее
        // all += firstPage
        
        var offset = 100
        
        while true {
            print("➡️ rating offset \(offset)")
            
            let html = try await fetchRatingPage(offset: offset)
            let chunk = parser.parseAjaxPage(html)
            
            if chunk.isEmpty {
                break
            }
            
            all.append(contentsOf: chunk)
            
            if chunk.count < 50 {
                break
            }
            
            offset += 50
        }
        
        return all
    }
    
    func fetchRatingPage(offset: Int) async throws -> String {
        var request = URLRequest(url: .ajaxURL)
        request.httpMethod = "POST"
        
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8",
                         forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://top-radio.ru/rating", forHTTPHeaderField: "Referer")
        request.setValue("https://top-radio.ru", forHTTPHeaderField: "Origin")
        
        let body = "action=rating&offset=\(offset)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return String(decoding: data, as: UTF8.self)
    }
    
    
    
}
