import Foundation

final class CountriesBuilder {
    var countries: [Country] = []
    
    func run() async throws {
        let html = try await html()
        try await parse(html)
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        try (try encoder.encode(self.countries)).write(to: URL(fileURLWithPath: "countries.json"))
        
        print("Countries saved: \(countries.count)")
    }
    
    func html() async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: .stranyi)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return html
    }
    
    func parse(_ html: String) async throws {
        let parser = CountryParser()
        let countries = parser.parseCountries(html: html)
        //print(countries.map({$0.description}).joined(separator: "\n"))
        self.countries = countries
    }    
}
