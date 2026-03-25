import Foundation

/// Декады в нормализованном виде.
/// Используем Int как rawValue для сортировки и диапазонов.
public enum Decade: Int, CaseIterable, Codable, Sendable {
    case y1930 = 1930
    case y1940 = 1940
    case y1950 = 1950
    case y1960 = 1960
    case y1970 = 1970
    case y1980 = 1980
    case y1990 = 1990
    case y2000 = 2000
    case y2010 = 2010
    case y2020 = 2020
}

extension Decade: Comparable {
    public static func < (lhs: Decade, rhs: Decade) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Decade: CustomStringConvertible {
    public var description: String {
        "\(rawValue)"
    }
}
