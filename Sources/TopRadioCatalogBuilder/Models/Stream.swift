import Foundation

struct Stream: Codable, Sendable {
    let bitrate: String?
    let url: String?
    
    var description: String {
        "\(bitrate ?? "-")|\(url ?? "-")"
    }
}
