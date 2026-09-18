import Foundation
import TopRadioCatalog

final class CountriesBuilder {
    func run() async throws -> [Country] {
        let html = try await HTMLFetcher.get(.stranyi)
        return CountryParser().parseCountries(html: html)
    }
}
