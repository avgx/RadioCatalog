import Foundation
import RadioCatalog

/// Результат нормализации тегов
public struct NormalizedTags: Sendable {
    public var genres: Set<Genre> = []
    public var decades: Set<Decade> = []
    public var formats: Set<StationFormat> = []
    public var misc: Set<String> = []

    public init() {}
}
