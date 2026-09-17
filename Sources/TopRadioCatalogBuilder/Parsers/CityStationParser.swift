import Foundation
import SwiftSoup

final class CityStationParser {
    
    func parseStation(
        html: String,
        fileURL: URL,
        citySlug: String,
        countrySlug: String
    ) -> CityStation? {
        
        do {
            let doc = try SwiftSoup.parse(html)
            
            guard let root = try doc.select("div.radio-station").first() else {
                return nil
            }
            
            let slug = fileURL.lastPathComponent
            
            // title
            let title = try root
                .select("h1[itemprop=name]")
                .first()?
                .text() ?? slug
            
            // image
            let image = try root
                .select("img[itemprop=image]")
                .first()?
                .attr("src")
            
            // genres
            let genres = try root
                .select("p.genres a")
                .array()
                .map { try $0.text() }
            
            // homepage
            let homepage = try doc
                .select(".contact-info-radio a[href]")
                .first()?
                .attr("href")
            
            // rating
            let rating = try root
                .select("[itemprop=ratingValue]")
                .first()?
                .text()
            
            // STREAMS (локальные!)
            let streams = StreamsParser().extractStreams(html)
            
            return CityStation(
                slug: slug,
                url: fileURL,
                title: title,
                citySlug: citySlug,
                countrySlug: countrySlug,
                genres: genres,
                homepage: homepage.flatMap(URL.init),
                rating: rating,
                image: image.flatMap { makeAbsolute($0) },
                streams: streams
            )
            
        } catch {
            print("❌ CityStation parse error \(fileURL.lastPathComponent):", error)
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

//func makeAbsolute(_ href: String, baseURL: URL) -> String {
//    if href.hasPrefix("http") { return href }
//    return baseURL.appendingPathComponent(href).absoluteString
//}
