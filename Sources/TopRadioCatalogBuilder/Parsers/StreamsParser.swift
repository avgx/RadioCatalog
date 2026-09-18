import Foundation
import TopRadioCatalog

class StreamsParser {
    // MARK: - Streams
    
    func extractStreams(_ html: String) -> [RadioStream] {
        let pattern = #"var STREAMS = '([^']*)';"#
        
        guard let raw = match(html, pattern), !raw.isEmpty else {
            return []
        }
        
        // фикс экранирования из примера (\/)
        let cleaned = raw.replacingOccurrences(of: #"\\/"#, with: "/")
        
        guard let data = cleaned.data(using: .utf8) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([RadioStream].self, from: data)
        } catch {
            print("❌ '\(cleaned)' | Streams decode error:", error)
            return []
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
