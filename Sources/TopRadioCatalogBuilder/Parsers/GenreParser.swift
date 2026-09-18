import Foundation
import SwiftSoup
import TopRadioCatalog

final class GenreParser {
    
    func parseGenres(html: String) -> [Genre] {
        do {
            let doc = try SwiftSoup.parse(html)
            
            // ключевой контейнер
            let links = try doc.select("ul.catalog a")
            
            var result: [Genre] = []
            result.reserveCapacity(links.size())
            
            for link in links {
                let href = try link.attr("href")          // genres/pop
                let title = try link.select("p").text()   // Поп-музыка
                
                guard !href.isEmpty, !title.isEmpty else { continue }
                
                let slug = extractSlug(from: href)
                let url = URL.makeAbsolute(href)
                
                result.append(
                    Genre(
                        slug: slug,
                        url: url,
                        title: title
                    )
                )
            }
            
            return result
            
        } catch {
            print("❌ Genre parse error:", error)
            return []
        }
    }
    
    // MARK: - Helpers
    
    private func extractSlug(from href: String) -> String {
        // genres/pop -> pop
        return href
            .split(separator: "/")
            .last
            .map(String.init) ?? href
    }    
}
