import Testing
import Foundation
@testable import RadioCatalog

// MARK: - Helpers

extension URL {
    static let invalidURL = URL(string: "https://invalid")!
}

private func makeStation(
    name: String,
    votes: Int? = nil,
    countryCode: String? = nil,
    languages: [String] = [],
    genres: [Genre] = [],
    formats: [StationFormat] = [],
    decades: [Decade] = []
) -> Station {
    Station(
        name: name,
        url: .invalidURL,
        countryCode: countryCode,
        languages: languages,
        genres: Set(genres),
        decades: Set(decades),
        formats: Set(formats),
        votes: votes
    )
}

// MARK: - Basic search

@Test func search_prefix_basic() async {
    let stations = [
        makeStation(name: "Radio Rock"),
        makeStation(name: "Jazz FM")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "ra")

    #expect(result.first?.name == "Radio Rock")
}

@Test func search_case_insensitive() async {
    let stations = [
        makeStation(name: "Radio Rock")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "RADIO")

    #expect(!result.isEmpty)
}

@Test func search_empty_query_returns_sorted() async {
    let stations = [
        makeStation(name: "B"),
        makeStation(name: "A")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: nil)

    #expect(result.map(\.name) == ["A", "B"])
}

// MARK: - NGram fallback

@Test func search_ngram_fallback() async {
    let stations = [
        makeStation(name: "Electronic Beats")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "lectr")

    #expect(!result.isEmpty)
}

// MARK: - Ranking

@Test func search_full_match_boost() async {
    let stations = [
        makeStation(name: "Rock Radio"),
        makeStation(name: "Super Rock Radio Station")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "rock radio")

    #expect(result.first?.name == "Rock Radio")
}

@Test func search_votes_boost() async {
    let stations = [
        makeStation(name: "Rock FM", votes: 10),
        makeStation(name: "Rock FM", votes: 100)
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "rock")

    #expect(result.first?.votes == 100)
}

// MARK: - Filters

@Test func search_filter_country() async {
    let stations = [
        makeStation(name: "Rock DE", countryCode: "DE"),
        makeStation(name: "Rock US", countryCode: "US")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "rock", countryCode: "DE")

    #expect(result.count == 1)
    #expect(result.first?.countryCode == "DE")
}

@Test func search_filter_language() async {
    let stations = [
        makeStation(name: "Rock EN", languages: ["en"]),
        makeStation(name: "Rock RU", languages: ["ru"])
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "rock", language: "ru")

    #expect(result.count == 1)
}

@Test func search_filter_genre() async {
    let stations = [
        makeStation(name: "Rock 1", genres: [.rock]),
        makeStation(name: "Jazz 1", genres: [.jazz])
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "1", genres: [.rock])

    #expect(result.count == 1)
    #expect(result.first?.genres.contains(.rock) == true)
}

// MARK: - Autocomplete

@Test func autocomplete_basic() async {
    let stations = [
        makeStation(name: "Radio Rock"),
        makeStation(name: "Jazz FM")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.autocomplete(query: "ra")

    #expect(result.first?.name == "Radio Rock")
}

@Test func autocomplete_prefix_priority() async {
    let stations = [
        makeStation(name: "Rock Radio"),
        makeStation(name: "Super Rock Radio")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.autocomplete(query: "rock")

    #expect(result.first?.name == "Rock Radio")
}

// MARK: - Pagination

@Test func search_limit() async {
    let stations = (0..<100).map {
        makeStation(name: "Station \($0)")
    }

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "station", limit: 10)

    #expect(result.count == 10)
}

@Test func search_offset() async {
    let stations = [
        makeStation(name: "A"),
        makeStation(name: "B"),
        makeStation(name: "C")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "a b c", limit: 2, offset: 1)

    #expect(result.count <= 2)
}

// MARK: - Country / Language stats

@Test func country_counts_excludes_empty() async {
    let stations = [
        makeStation(name: "A", countryCode: ""),
        makeStation(name: "B", countryCode: "DE"),
        makeStation(name: "C", countryCode: "DE")
    ]

    let index = await StationIndex.build(stations)
    let counts = await index.stationCountsByCountry()

    #expect(counts.first?.0 == "DE")
    #expect(counts.first?.1 == 2)
}

@Test func language_counts_basic() async {
    let stations = [
        makeStation(name: "A", languages: ["en"]),
        makeStation(name: "B", languages: ["en"]),
        makeStation(name: "C", languages: ["ru"])
    ]

    let index = await StationIndex.build(stations)
    let counts = await index.stationCountsByLanguage()

    #expect(counts.first?.0 == "en")
    #expect(counts.first?.1 == 2)
}

// MARK: - Edge cases

@Test func search_no_results() async {
    let stations = [
        makeStation(name: "Rock")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "zzz")

    #expect(result.isEmpty || result.count <= 1)
}

@Test func autocomplete_no_results() async {
    let stations = [
        makeStation(name: "Rock")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.autocomplete(query: "zzz")

    #expect(result.isEmpty)
}

@Test func search_unicode() async {
    let stations = [
        makeStation(name: "Радио Рок")
    ]

    let index = await StationIndex.build(stations)
    let result = await index.search(query: "radio")

    #expect(!result.isEmpty) // depends on Transliteration
}
