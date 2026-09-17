import Foundation

struct Stream: Codable, Sendable, Hashable {
    let bitrate: String?
    let url: String?
    
    var description: String {
        "\(bitrate ?? "-")|\(url ?? "-")"
    }
}
