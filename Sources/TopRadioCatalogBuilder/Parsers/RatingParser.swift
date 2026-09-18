import Foundation
import SwiftSoup
import TopRadioCatalog

final class RatingParser {
    
    func parse(html: String) -> [RatingEntry] {
        do {
            let doc = try SwiftSoup.parse(html)
            
            let rows = try doc.select("#table-rating li")
            
            var result: [RatingEntry] = []
            result.reserveCapacity(rows.size())
            
            for row in rows {
                
                // пропускаем header
                if try row.select("a").isEmpty() {
                    continue
                }
                
                guard
                    let link = try row.select("a").first()
                else {
                    continue
                }
                
                let href = try link.attr("href")         // web/marusya-fm
                let title = link.ownText().trimmingCharacters(in: .whitespacesAndNewlines)
                
                let slug = extractSlug(from: href)
                let url = URL.makeAbsolute(href)
                
                let positionText = try row.select(".top").text()
                let position = Int(positionText) ?? 0
                
                let ratingText = try row.select(".rating").text()
                let rating = Int(ratingText) // может быть nil
                
                result.append(
                    RatingEntry(
                        position: position,
                        slug: slug,
                        url: url,
                        title: title,
                        rating: rating
                    )
                )
            }
            
            return result
            
        } catch {
            print("❌ Rating parse error:", error)
            return []
        }
    }
    
    func parseAjaxPage(_ html: String) -> [RatingEntry] {
        do {
            let doc = try SwiftSoup.parseBodyFragment(html)
            let rows = try doc.select("li")
            
            return try rows.compactMap {
                try parseRatingItem($0)
            }
            
        } catch {
            print("❌ AJAX rating parse error:", error)
            return []
        }
    }
    
    func parseRatingItem(_ row: Element) throws -> RatingEntry? {
        
        guard let link = try row.select("a").first() else {
            return nil
        }
        
        let href = try link.attr("href")
        let slug = extractSlug(from: href)
        let url = URL.makeAbsolute(href)
        
        let title = link.ownText().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let position = Int(try row.select(".top").text()) ?? 0
        
        let ratingText = try row.select(".rating").text()
        let rating = Int(ratingText)
        
        return RatingEntry(
            position: position,
            slug: slug,
            url: url,
            title: title,
            rating: rating
        )
    }
}

private extension RatingParser {
    
    func extractSlug(from href: String) -> String {
        return href
            .split(separator: "/")
            .last
            .map(String.init) ?? href
    }
    
}

