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
    
    
    /*
    <li><label class="checkbox-label"><input type="checkbox" value="7886" name="" onchange="changeFavorite($(this))"><span></span></label><a href="web/comedy" title="Comedy Radio"><img class="b-lazy" data-src="assets/image/radio/100/comedyradio.png" src="assets/image/load.gif" alt="Comedy Radio"><p>Comedy Radio</p></a></li>

    <li><label class="checkbox-label"><input type="checkbox" value="7107" name="" onchange="changeFavorite($(this))"><span></span></label><a href="web/relax-fm" title="Relax FM"><img class="b-lazy" data-src="assets/image/radio/100/relaxfmru.png" src="assets/image/load.gif" alt="Relax FM"><p>Relax FM</p></a></li>
     */
    // пока бесполезно, но так можно.
    func fetchStationsAjax(offset: Int) async throws -> String {
        let url = URL(string: "https://top-radio.ru/ajax")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://top-radio.ru/web", forHTTPHeaderField: "Referer")
        
        let body = "action=web-radio&offset=\(offset)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return String(decoding: data, as: UTF8.self)
    }
}
