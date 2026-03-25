//import Foundation
//
///*
// 
// curl -X GET "https://de2.api.radio-browser.info/json/stations?hidebroken=true&limit=10000&order=votes&reverse=true" | \
//   jq '[.[] | {stationuuid: .stationuuid, name: .name, url_resolved: .url_resolved, homepage: .homepage, favicon: .favicon, tags: .tags, countrycode: .countrycode, state: .state, codec: .codec, bitrate: .bitrate, iso_3166_2: .iso_3166_2, languagecodes: .languagecodes, geo_lat: .geo_lat, geo_long: .geo_long, votes: .votes}]' > offline-10k.json
// 
// 
// curl -X GET "https://de2.api.radio-browser.info/json/stations?hidebroken=true&limit=100000&order=votes&reverse=true" | jq '[.[] | {stationuuid: .stationuuid, name: .name, url_resolved: .url_resolved, homepage: .homepage, favicon: .favicon, tags: .tags, countrycode: .countrycode, state: .state, codec: .codec, bitrate: .bitrate, iso_3166_2: .iso_3166_2, languagecodes: .languagecodes, geo_lat: .geo_lat, geo_long: .geo_long, votes: .votes }]' >offline.json
// 
//*/
//
//public class RadioBrowserAPI {
//    /// https://de2.api.radio-browser.info/
//    static let API = "de2.api.radio-browser.info"
//    
//    public static func dumpStations(
//        limit: Int = 100,
//        offset: Int = 0
//    ) async throws -> [RadioBrowserStation] {
//        
//        var components = URLComponents()
//        components.scheme = "https"
//        components.host = API
//        components.path = "/json/stations/search"
//        
//        
//        var queryItems = [
//            URLQueryItem(name: "limit", value: "\(limit)"),
//            URLQueryItem(name: "offset", value: "\(offset)"),
//            URLQueryItem(name: "hidebroken", value: "true"),
//            URLQueryItem(name: "order", value: "votes"),
//            URLQueryItem(name: "reverse", value: "true")
//        ]
//        
//        components.queryItems = queryItems
//        
//        guard let url = components.url else {
//            throw URLError(.badURL)
//        }
//        
//        let (data, response) = try await URLSession.shared.data(from: url)
//        let result = try JSONDecoder().decode([RadioBrowserStation].self, from: data)
//        
//        
//        return result
//    }
//    
//}
