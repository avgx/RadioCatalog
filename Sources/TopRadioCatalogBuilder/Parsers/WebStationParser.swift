import Foundation
import SwiftSoup

final class WebStationParser {
    
    func parseStation(html: String, fileURL: URL) -> WebStation? {
        do {
            print("\(fileURL.absoluteString)")
            let doc = try SwiftSoup.parse(html)
            
            guard let root = try doc.select("div.radio-station").first() else {
                return nil
            }
            
            let slug = fileURL.lastPathComponent
            
            // title
            let title = try root.select("h1[itemprop=name]").text()
            
            // image
            let image = try root.select("img[itemprop=image]").first()?.attr("src")
            
            // genres
            let genres = try root
                .select("p.genres a")
                .array()
                .map { try $0.text() }
            
            // country
            let country = try root
                .select("p:has(span:contains(Страна)) a")
                .first()?
                .text()
            
            // city (если появится в других страницах)
            let city = try root
                .select("p:has(span:contains(Город)) a")
                .first()?
                .text()
            
            // frequency (не в этом примере, но на других есть)
            let frequency = try root
                .select("p:has(span:contains(Частота))")
                .first()?
                .ownText()
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // homepage (если есть ссылка "Сайт")
            let homepage = try doc
                .select("a:contains(Сайт)")
                .first()?
                .attr("href")
            
            // rating
            let rating = try root
                .select("span[itemprop=ratingValue]")
                .first()?
                .text()
            
            // rating count (можно добавить в модель позже)
            let ratingCount = try root
                .select("span[itemprop=reviewCount]")
                .first()?
                .text()
            
            let streams = StreamsParser().extractStreams(html)
            
            return WebStation(
                slug: slug,
                url: URL(string: "https://top-radio.ru/web/\(slug)")!,
                title: title,
                country: country,
                genres: genres,
                homepage: homepage.flatMap(URL.init),
                rating: rating,
                image: image.flatMap { makeAbsolute($0, slug: slug) },
                streams: streams
            )
            
        } catch {
            print("❌ parse error \(fileURL.lastPathComponent): \(error)")
            return nil
        }
    }
    
    
    
    // MARK: - Helpers
    
    private func makeAbsolute(_ path: String, slug: String) -> URL? {
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        return URL(string: "https://top-radio.ru/\(path)")
    }
    
    
    // MARK: - Links
    
    func extractLinks(html: String) -> [String] {
        let pattern = #"href="([^"]+)""#
        let regex = try! NSRegularExpression(pattern: pattern)
        
        let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        
        return matches.compactMap {
            Range($0.range(at: 1), in: html).map { String(html[$0]) }
        }
    }
}
