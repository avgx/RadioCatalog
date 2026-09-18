import Foundation
import Testing
import TopRadioCatalog
import ZIPFoundation

func sampleRawDump() -> (
    countries: [Country],
    cities: [City],
    genres: [Genre],
    rating: [RatingEntry],
    web: [WebStation],
    city: [CityStation]
) {
    let countries = [
        Country(slug: "rossiya", url: "https://top-radio.ru/rossiya", title: "Россия")
    ]
    let cities = [
        City(
            slug: "moskva",
            url: "https://top-radio.ru/moskva",
            title: "Москва",
            stationCount: 1,
            countrySlug: "rossiya"
        )
    ]
    let genres = [
        Genre(slug: "pop", url: "https://top-radio.ru/genres/pop", title: "Поп-музыка")
    ]
    let rating = [
        RatingEntry(
            position: 1,
            slug: "dorozhnoe",
            url: "https://top-radio.ru/web/dorozhnoe",
            title: "Дорожное радио",
            rating: 1000
        )
    ]
    let web = [
        WebStation(
            slug: "dorozhnoe",
            url: URL(string: "https://top-radio.ru/web/dorozhnoe")!,
            title: "Дорожное радио",
            country: "Россия",
            genres: ["Поп-музыка"],
            streams: [
                RadioStream(bitrate: "128", url: "https://example.com/stream.mp3"),
                RadioStream(bitrate: "64", url: "https://example.com/player.htm")
            ]
        ),
        WebStation(
            slug: "broken",
            url: URL(string: "https://top-radio.ru/web/broken")!,
            title: "Broken",
            streams: [
                RadioStream(bitrate: "64", url: "https://example.com/listen.html")
            ]
        ),
        WebStation(
            slug: "nashe",
            url: URL(string: "https://top-radio.ru/web/nashe")!,
            title: "Наше Радио",
            country: "Россия",
            genres: ["Рок-музыка"],
            streams: [
                RadioStream(bitrate: "128", url: "https://example.com/nashe.mp3")
            ]
        )
    ]
    let city = [
        CityStation(
            slug: "dorozhnoe",
            url: URL(string: "https://top-radio.ru/moskva/dorozhnoe")!,
            title: "Дорожное радио Москва",
            citySlug: "moskva",
            countrySlug: "rossiya",
            genres: ["Поп-музыка"],
            frequency: "96.0 FM",
            streams: [
                RadioStream(bitrate: "64", url: "https://example.com/msk.mp3")
            ]
        ),
        CityStation(
            slug: "local-only",
            url: URL(string: "https://top-radio.ru/moskva/local-only")!,
            title: "Местное",
            citySlug: "moskva",
            countrySlug: "rossiya",
            streams: [
                RadioStream(bitrate: "96", url: "https://example.com/local.aac")
            ]
        )
    ]
    return (countries, cities, genres, rating, web, city)
}

func assembledDump() -> TopRadioDump {
    let raw = sampleRawDump()
    return TopRadioDump.assemble(
        countries: raw.countries,
        cities: raw.cities,
        genres: raw.genres,
        rating: raw.rating,
        webStations: raw.web,
        cityStations: raw.city
    )
}

@Test func streamPlayableRejectsHtml() {
    #expect(RadioStream(bitrate: nil, url: "https://example.com/player.htm").isPlayable == false)
    #expect(RadioStream(bitrate: nil, url: "https://example.com/listen.html").isPlayable == false)
    #expect(RadioStream(bitrate: "128", url: "https://example.com/stream.mp3").isPlayable == true)
    #expect(RadioStream(bitrate: "64", url: "https://host:8000/live").isPlayable == true)
}

@Test func assembleDropsHtmlStreamsAndEmptyCards() {
    let dump = assembledDump()

    #expect(dump.webStations.map(\.slug).sorted() == ["dorozhnoe", "nashe"])
    #expect(dump.webStations.contains { $0.slug == "broken" } == false)

    let dorozhnoe = dump.webStations.first { $0.slug == "dorozhnoe" }
    #expect(dorozhnoe?.streams.count == 1)
    #expect(dorozhnoe?.streams.first?.url == "https://example.com/stream.mp3")
    #expect(dump.cityStations.count == 2)
}

@Test func webAndCityLinkBySlug() {
    let lookups = assembledDump().lookups()
    let web = lookups.web(forSlug: "dorozhnoe")
    let locals = lookups.locals(forSlug: "dorozhnoe")

    #expect(web != nil)
    #expect(locals.count == 1)
    #expect(locals.first?.citySlug == "moskva")
    #expect(lookups.web(for: locals[0])?.slug == "dorozhnoe")
    #expect(lookups.locals(for: web!).count == 1)
    #expect(lookups.web(forSlug: "local-only") == nil)
    #expect(lookups.locals(forSlug: "local-only").count == 1)
}

@Test func indexSearchAndCityFilter() async {
    let dump = assembledDump()
    let index = await TopRadioStationIndex.build(dump)

    let byName = await index.search(query: "Дорожное")
    #expect(byName.contains { $0.slug == "dorozhnoe" })

    let inMoscow = await index.search(citySlug: "moskva")
    #expect(Set(inMoscow.map(\.slug)) == ["dorozhnoe", "local-only"])

    let rock = await index.search(genre: "Рок-музыка")
    #expect(rock.map(\.slug) == ["nashe"])

    let locals = await index.stations(inCity: "moskva")
    #expect(locals.count == 2)
    #expect(await index.web(forSlug: "dorozhnoe") != nil)
}

@Test func remoteCatalogLoadsJsonAndZip() throws {
    let dump = assembledDump()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let json = try encoder.encode(dump)

    let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: temp) }

    let jsonURL = temp.appendingPathComponent("tr-stations.json")
    try json.write(to: jsonURL)

    let fromJSON = try RemoteTopCatalog.load(from: jsonURL)
    #expect(fromJSON.webStations.map(\.slug).sorted() == dump.webStations.map(\.slug).sorted())

    let zipURL = temp.appendingPathComponent("tr-stations.zip")
    try FileManager.default.zipItem(at: jsonURL, to: zipURL)
    let zipData = try Data(contentsOf: zipURL)
    let fromZip = try RemoteTopCatalog.load(fromZip: zipData)
    #expect(fromZip.cityStations.count == dump.cityStations.count)
}
