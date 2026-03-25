import Foundation
import RadioCatalog

/// Сырая модель станции из radio-browser API.
///
/// Эта структура отражает формат API.
/// Она не используется в UI напрямую.
extension RadioBrowserStation {

    /// Преобразует API модель
    /// в доменную модель Station.
    public func toStation() -> Station? {

        guard let url_resolved else { return nil }

        guard let codec else { return nil }
        guard codec.lowercased().contains("mp3") || codec.lowercased().contains("aac") else { return nil }
        guard let votes, votes > 5 else { return nil }
        guard bitrate ?? 0 >= 32 else { return nil }
        //TODO: убрать только табы / множественные пробелы / странные символы внутри
        //let normalizedName = TextNormalizer.normalize(name)

        let normalizedTags = TagNormalizer.normalize(name: name, tags: tags ?? "")

        
        return Station(
            id: stationuuid,
            name: name,
            url: url_resolved,
            homepage: homepage.flatMap(URL.init),
            logo: favicon.flatMap(URL.init),
            countryCode: countrycode?.uppercased(),
            languages: languagecodes?
                .split(separator: ",")
                .map { $0.lowercased() } ?? [],
            genres: normalizedTags.genres,
            decades: normalizedTags.decades,
            formats: normalizedTags.formats,
            tags: normalizedTags.misc,
            codec: codec,
            bitrate: bitrate,
            frequency: FrequencyNormalizer.extract(from: name)
        )
    }
}
