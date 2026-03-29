import Foundation
import SwiftSoup

final class CityPageParser {
    
    func parse(html: String, baseURL: URL, citySlug: String) -> [CityStationRef] {
        do {
            let doc = try SwiftSoup.parse(html)
            let rows = try doc.select("table.stations-list tr")
            
            var result: [CityStationRef] = []
            result.reserveCapacity(rows.size())
            
            for row in rows {
                
                // пропускаем header
                if try !row.select("th").isEmpty() {
                    continue
                }
                
                guard
                    let link = try row.select("a[href]").first(),
                    let nameEl = try link.select(".name").first()
                else {
                    continue
                }
                
                let href = try link.attr("href") // rostov-na-donu/nashe
                let stationSlug = extractStationSlug(from: href)
                let url = makeAbsolute(href, baseURL: baseURL)
                
                let title = try nameEl.text()
                
                let frequency = try row.select(".frequency").text().nilIfEmpty
                
                result.append(
                    CityStationRef(
                        citySlug: citySlug,
                        stationSlug: stationSlug,
                        url: url,
                        title: title,
                        frequency: frequency
                    )
                )
            }
            
            return result
            
        } catch {
            print("❌ City parse error:", error)
            return []
        }
    }
}

private extension CityPageParser {
    
    func extractStationSlug(from href: String) -> String {
        // rostov-na-donu/nashe → nashe
        return href
            .split(separator: "/")
            .last
            .map(String.init) ?? href
    }
    
    func makeAbsolute(_ href: String, baseURL: URL) -> String {
        if href.hasPrefix("http") {
            return href
        }
        return baseURL.appendingPathComponent(href).absoluteString
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
