import Foundation

/// Генерация n-грамм для fuzzy поиска.
enum NGram {

    static func grams(_ input: String, min: Int = 2, max: Int = 4) -> [String] {
        guard input.count >= min else { return [input] }

        var result: Set<String> = []

        let chars = Array(input)

        for n in min...max {
            guard chars.count >= n else { continue }

            for i in 0...(chars.count - n) {
                let gram = String(chars[i..<i+n])
                result.insert(gram)
            }
        }

        return Array(result)
    }
}
