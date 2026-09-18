import Foundation
import TopRadioCatalog

final class CitiesBuilder {
    func run(countries: [Country]) async throws -> [City] {
        var cities: [City] = []
        for country in countries {
            let html = try await HTMLFetcher.get(URL(string: country.url)!)
            let (parsed, _) = CountryPageParser().parse(html: html, country: country)
            cities.append(contentsOf: parsed)
        }
        return cities
    }
}
