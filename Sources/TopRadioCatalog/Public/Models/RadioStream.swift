import Foundation

public struct RadioStream: Codable, Sendable, Hashable {
    public let bitrate: String?
    public let url: String?

    public var description: String {
        "\(bitrate ?? "-")|\(url ?? "-")"
    }

    public init(bitrate: String?, url: String?) {
        self.bitrate = bitrate
        self.url = url
    }

    /// Rejects player pages and other non-audio URLs (`.htm`, `.html`, …).
    /// Icecast-style URLs without an extension are treated as playable.
    public var isPlayable: Bool {
        Self.isPlayable(url)
    }

    public static func isPlayable(_ urlString: String?) -> Bool {
        guard let urlString, !urlString.isEmpty else { return false }
        guard let url = URL(string: urlString) else { return false }
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return false
        }

        let path = url.path.lowercased()
        let bannedExtensions = [".htm", ".html", ".php", ".asp", ".aspx"]
        if bannedExtensions.contains(where: { path.hasSuffix($0) }) {
            return false
        }
        return true
    }
}
