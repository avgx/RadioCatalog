import Foundation

public enum TextNormalizer {

    public static func normalize(_ s: String) -> String {

        s.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(
                of: #"\d+(\.\d+)?"#,
                with: "",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: "[^a-zа-я0-9 ]",
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(in: .whitespaces)
    }
}
