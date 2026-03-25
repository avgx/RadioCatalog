import Foundation

/// Извлекает частоту из строки (title/name).
/// Tags игнорируются.
enum FrequencyNormalizer {

    private static var regex: NSRegularExpression {
        try! NSRegularExpression(
            pattern: #"(?:fm\s*)?(\d{2,3}\.\d)(?:\s*fm)?"#,
            options: [.caseInsensitive]
        )
    }

    static func extract(from input: String) -> String? {
        let range = NSRange(input.startIndex..., in: input)

        guard let match = regex.firstMatch(in: input, range: range),
              let r = Range(match.range(at: 1), in: input)
        else { return nil }

        let value = Double(input[r])
        guard let value, (87.5...108.0).contains(value) else { return nil }

        return String(format: "%.1f", value)
    }

    static func normalizeOld(_ name: String) -> (name: String, frequency: String?) {

        let range = NSRange(location: 0, length: name.utf16.count)
        let patterns = [
            #"\b(\d+(?:\.\d+)?)\s*FM\b"#,
            #"\b(\d+(?:\.\d+)?)\s*МГц\b"#,
            #"\b(8[7-9]\.\d|9\d\.\d|10[0-8]\.\d)\b"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            if let match = regex.firstMatch(in: name, range: range) {
                let r = match.range(at: 1)
                let frequency = (name as NSString).substring(with: r)
                let cleaned = (name as NSString)
                    .replacingCharacters(in: match.range, with: "")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                return (cleaned, frequency)
            }
        }
        return (name, nil)
    }
}
