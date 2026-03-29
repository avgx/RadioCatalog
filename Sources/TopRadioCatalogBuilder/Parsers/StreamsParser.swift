import Foundation

class StreamsParser {
    // MARK: - Streams
    
    func extractStreams(_ html: String) -> [Stream] {
        guard let raw = match(html, #"var STREAMS = '(.+?)';"#) else {
            return []
        }
        
        let cleaned = raw.replacingOccurrences(of: #"\\/"#, with: "/")
        
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else {
            return []
        }
        
        return json.map {
            Stream(
                bitrate: $0["bitrate"] as? String,
                url: $0["url"] as? String
            )
        }
    }
    
    private func match(_ html: String, _ pattern: String) -> String? {
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        
        guard let m = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let r = Range(m.range(at: 1), in: html)
        else { return nil }
        
        return String(html[r])
    }
    
}
