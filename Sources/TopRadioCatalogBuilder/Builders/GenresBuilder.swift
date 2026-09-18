import Foundation
import TopRadioCatalog

final class GenresBuilder {
    func run() async throws -> [Genre] {
        let html = try await HTMLFetcher.get(.genres)
        return GenreParser().parseGenres(html: html)
    }
}
