import Foundation

extension URL {
    static let baseURL = URL(string: "https://top-radio.ru")!
    static let ajaxURL = URL(string: "https://top-radio.ru/ajax")!
    static let rating = URL(string: "https://top-radio.ru/rating")!
    static let genres = URL(string: "https://top-radio.ru/genres")!
    static let stranyi = URL(string: "https://top-radio.ru/stranyi")!

    static func makeAbsolute(_ href: String) -> String {
        if href.hasPrefix("http") {
            return href
        }
        return baseURL.appendingPathComponent(href).absoluteString
    }
}
