import Foundation

struct CityStationRef: Codable, Sendable, Hashable, CustomStringConvertible {
    let citySlug: String
    let stationSlug: String
    let url: String
    let title: String
    let frequency: String?
    
    var description: String {
        "\(citySlug)|\(stationSlug)|\(frequency ?? "")|\(title)|\(url)"
    }
}
