import Foundation
import SwiftSoup

final class GenreStationsParser {
    
    func parseStations(
        html: String,
        genre: Genre
    ) -> [StationRef] {
        
        do {
            let doc = try SwiftSoup.parse(html)
            
            // только реальные станции
            let links = try doc.select("ul.catalog a[href^=web/]")
            
            var result: [StationRef] = []
            result.reserveCapacity(links.size())
            
            for link in links {
                
                let href = try link.attr("href") // web/marusya-fm
                let title = try link.select("p").text()
                
                guard !href.isEmpty else { continue }
                
                let slug = extractSlug(from: href)
                let url = URL.makeAbsolute(href)
                
                result.append(
                    StationRef(
                        slug: slug,
                        url: url,
                        title: title,
                        genreSlug: genre.slug,
                        countrySlug: "",
                        id: nil
                    )
                )
            }
            
            return result
            
        } catch {
            print("❌ parseStations error:", error)
            return []
        }
    }
    
    // MARK: - Helpers
    
    private func extractSlug(from href: String) -> String {
        // web/marusya-fm → marusya-fm
        return href
            .split(separator: "/")
            .last
            .map(String.init) ?? href
    }
}
