import Foundation

final class CitiesBuilder {
    var cities: [City] = []
    
    func run(countries: [Country]) async throws {
        for country in countries {
            try await parseCountryPage(country: country)
        }        
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        try (try encoder.encode(self.cities)).write(to: URL(fileURLWithPath: "cities.json"))
        
        print("Cities saved: \(cities.count)")
    }
    
    func parseCountryPage(country: Country) async throws {
        let html = try await country.html()
        
        let parser = CountryPageParser()
        let (cities, _) = parser.parse(html: html, country: country)
        self.cities.append(contentsOf: cities)
        
        
    }
}
