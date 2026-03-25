import Foundation

/// Примитивная транслитерация (достаточно для жанров)
enum Transliteration {

    static func latin(_ input: String) -> String {
        input.applyingTransform(.toLatin, reverse: false)?
            .applyingTransform(.stripDiacritics, reverse: false)?
            .lowercased() ?? input.lowercased()
    }
}
