import Foundation

/// Формат станции (не жанр!)
public enum StationFormat: String, CaseIterable, Codable, Sendable {
    case music
    case news
    case talk
    case talkNews
    case publicRadio
    case commercial
    case community
    case traffic
    case comedy
    case sports
    case religious
}

extension StationFormat: Comparable {
    public static func < (lhs: StationFormat, rhs: StationFormat) -> Bool {
        lhs.rawValue.caseInsensitiveCompare(rhs.rawValue) == .orderedAscending
    }
}

extension StationFormat: CustomStringConvertible {
    public var description: String {
        "\(rawValue)"
    }
}
