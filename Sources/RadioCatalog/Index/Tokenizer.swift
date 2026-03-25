import Foundation

/// Базовый токенайзер.
/// Удаляет мусор и приводит к lowercased.
enum Tokenizer {

    static func tokenize(_ input: String) -> [String] {

        var result: [String] = []
        var current = ""

        for c in input.lowercased() {

            if c.isLetter || c.isNumber {
                current.append(c)
            } else {
                if !current.isEmpty {
                    result.append(current)
                    current.removeAll(keepingCapacity: true)
                }
            }
        }

        if !current.isEmpty {
            result.append(current)
        }

        return result
    }
}
