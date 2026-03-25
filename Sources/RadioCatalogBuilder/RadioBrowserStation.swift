import Foundation

/// Сырая модель станции из radio-browser API.
///
/// Эта структура отражает формат API.
/// Она не используется в UI напрямую.
public struct RadioBrowserStation: Codable {

    public let stationuuid: UUID
    public let name: String
    public let url_resolved: URL?
    public let homepage: String?
    public let favicon: String?

    public let countrycode: String?
    public let languagecodes: String?
    public let tags: String?

    public let codec: String?
    public let bitrate: Int?
    
    public let votes: Int?
}
