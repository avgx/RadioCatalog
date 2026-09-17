import Foundation
import SwiftSoup

//пример https://top-radio.ru/rossiya там можно получить список городов и список станций.

final class CountryPageParser {
    
    func parse(html: String, country: Country) -> (cities: [City], stations: [StationRef]) {
        do {
            let doc = try SwiftSoup.parse(html)
            
            let cities = try parseCities(doc: doc, country: country)
            let stations = try parseStations(doc: doc, country: country)
            
            return (cities, stations)
            
        } catch {
            print("❌ Country page parse error:", error)
            return ([], [])
        }
    }
}

private extension CountryPageParser {
    
    func parseCities(doc: Document, country: Country) throws -> [City] {
        let items = try doc.select("ul.threecolumn li")
        
        var result: [City] = []
        result.reserveCapacity(items.size())
        
        for item in items {
            guard let link = try item.select("a").first() else { continue }
            
            let href = try link.attr("href")        // abakan
            let title = try link.text()             // Абакан
            
            let countText = try item.select("span").text() // "(20)"
            let count = extractCount(countText)
            
            let slug = extractSlug(from: href)
            let url = URL.makeAbsolute(href)
            
            result.append(
                City(
                    slug: slug,
                    url: url,
                    title: title,
                    stationCount: count,
                    countrySlug: country.slug
                )
            )
        }
        
        return result
    }
}

private extension CountryPageParser {
    
    func extractCount(_ text: String) -> Int {
        // "(20)" → 20
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }
}

private extension CountryPageParser {
    
    func parseStations(doc: Document, country: Country) throws -> [StationRef] {
        let items = try doc.select("ul.catalog li")
        
        var result: [StationRef] = []
        result.reserveCapacity(items.size())
        
        for item in items {
            guard let link = try item.select("a[href^=web/]").first() else {
                continue
            }
            
            let href = try link.attr("href")     // web/marusya-fm
            let title = try link.select("p").text()
            
            let slug = extractSlug(from: href)   // marusya-fm
            let url = URL.makeAbsolute(href)
            
            // id лежит в checkbox value
            let id = try item.select("input[type=checkbox]").attr("value")
            
            result.append(
                StationRef(
                    slug: slug,
                    url: url,
                    title: title,
                    genreSlug: "",
                    countrySlug: country.slug,
                    id: id.isEmpty ? nil : id
                )
            )
        }
        
        return result
    }
}

private extension CountryPageParser {
    
    func extractSlug(from href: String) -> String {
        return href
            .split(separator: "/")
            .last
            .map(String.init) ?? href
    }    
}
