import Foundation
import SwiftSoup

// https://top-radio.ru/stranyi получаем список стран.

final class CountryParser {
    
    func parseCountries(html: String) -> [Country] {
        do {
            let doc = try SwiftSoup.parse(html)
            
            let links = try doc.select("ul.catalog a")
            
            var result: [Country] = []
            result.reserveCapacity(links.size())
            
            for link in links {
                let href = try link.attr("href")     // rossiа, belarus, web
                let title = try link.select("p").text()
                
                guard !href.isEmpty, !title.isEmpty else { continue }
                
                // фильтр
                if !["rossiya", "belarus", "kazaxstan"].contains(href) {
                    continue
                }
                
                let slug = extractSlug(from: href)
                let url = URL.makeAbsolute(href)
                
                result.append(
                    Country(
                        slug: slug,
                        url: url,
                        title: title
                    )
                )
            }
            
            return result
            
        } catch {
            print("❌ Country parse error:", error)
            return []
        }
    }
    
    // MARK: - Helpers
    
    private func extractSlug(from href: String) -> String {
        // rossiа → rossiа
        return href
            .split(separator: "/")
            .last
            .map(String.init) ?? href
    }
    
}
