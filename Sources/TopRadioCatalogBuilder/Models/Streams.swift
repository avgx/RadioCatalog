import Foundation

struct Streams: Codable, Sendable, Hashable, CustomStringConvertible {
    let url: URL
    let streams: [Stream]
    
    var description: String {
        "\(url.absoluteString)|\(streams.count)"
    }
}
