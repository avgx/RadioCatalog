import Foundation
import TopRadioCatalog

final class RatingBuilder {
    func run() async throws -> [RatingEntry] {
        let html = try await HTMLFetcher.get(.rating)
        let parser = RatingParser()
        var rating = parser.parse(html: html)
        rating.append(contentsOf: try await fetchAllRatings())
        return rating
    }

    private func fetchAllRatings() async throws -> [RatingEntry] {
        var all: [RatingEntry] = []
        let parser = RatingParser()
        var offset = 100

        while true {
            print("rating offset \(offset)")
            let html = try await fetchRatingPage(offset: offset)
            let chunk = parser.parseAjaxPage(html)
            if chunk.isEmpty { break }
            all.append(contentsOf: chunk)
            if chunk.count < 50 { break }
            offset += 50
        }

        return all
    }

    private func fetchRatingPage(offset: Int) async throws -> String {
        var request = URLRequest(url: .ajaxURL)
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded; charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://top-radio.ru/rating", forHTTPHeaderField: "Referer")
        request.setValue("https://top-radio.ru", forHTTPHeaderField: "Origin")
        request.httpBody = "action=rating&offset=\(offset)".data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        return String(decoding: data, as: UTF8.self)
    }
}
