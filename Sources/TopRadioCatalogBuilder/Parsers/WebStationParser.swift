import Foundation
import SwiftSoup
import TopRadioCatalog

final class WebStationParser {
    func parseStation(html: String, fileURL: URL) -> WebStation? {
        do {
            let doc = try SwiftSoup.parse(html)

            guard let root = try doc.select("div.radio-station").first() else {
                return nil
            }

            let slug = fileURL.lastPathComponent

            let title = try root
                .select("h1[itemprop=name]")
                .first()?
                .text() ?? slug

            let image = try root
                .select("img[itemprop=image]")
                .first()?
                .attr("src")

            let genres = try root
                .select("p.genres a")
                .array()
                .map { try $0.text() }

            let country = try root
                .select("p:has(span:contains(Страна)) a")
                .first()?
                .text()

            let homepage = try doc
                .select(".contact-info-radio a[href]")
                .first()?
                .attr("href")

            let rating = try root
                .select("[itemprop=ratingValue]")
                .first()?
                .text()

            let streams = StreamsParser().extractStreams(html)

            return WebStation(
                slug: slug,
                url: fileURL,
                title: title,
                country: country,
                genres: genres,
                homepage: homepage.flatMap(URL.init),
                rating: rating,
                image: image.flatMap { makeAbsolute($0) },
                streams: streams
            )
        } catch {
            print("parse error \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }

    private func makeAbsolute(_ path: String) -> URL? {
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        return URL(string: "https://top-radio.ru/\(path)")
    }
}
