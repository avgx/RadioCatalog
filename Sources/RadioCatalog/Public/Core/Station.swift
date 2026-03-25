import Foundation

/// модель радиостанции.
///
/// Содержит только нормализованные данные.
public struct Station:
    Codable,
    Sendable,
    Identifiable,
    Hashable,
    Equatable
{
    public let id: UUID

    /// отображаемое имя станции
    public let name: String
    
    /// URL аудиопотока
    public let url: URL

    /// сайт станции
    public let homepage: URL?

    /// логотип
    public let logo: URL?

    /// код страны ISO 3166-1 alpha-2
    public let countryCode: String?

    /// языки ISO 639
    public let languages: [String]

    public let genres: Set<Genre>
    public let decades: Set<Decade>
    public let formats: Set<StationFormat>
    public let tags: Set<String>
    
    /// кодек потока
    public let codec: String?

    /// битрейт
    public let bitrate: Int?

    /// FM частота (если есть)
    public let frequency: String?

    public let votes: Int?
    
    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        homepage: URL? = nil,
        logo: URL? = nil,
        countryCode: String? = nil,
        languages: [String] = [],
        genres: Set<Genre> = [],
        decades: Set<Decade> = [],
        formats: Set<StationFormat> = [],
        tags: Set<String> = [],
        codec: String? = nil,
        bitrate: Int? = nil,
        frequency: String? = nil,
        votes: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.homepage = homepage
        self.logo = logo
        self.countryCode = countryCode
        self.languages = languages
        self.genres = genres
        self.decades = decades
        self.formats = formats
        self.tags = tags
        self.codec = codec
        self.bitrate = bitrate
        self.frequency = frequency
        self.votes = votes
    }
}

extension Station: CustomDebugStringConvertible {

    public var debugDescription: String {
        "\(id)|\(name.prefix(32))|\(countryCode ?? "?")|\(languages)|\(genres)|\(decades)"
    }
}
