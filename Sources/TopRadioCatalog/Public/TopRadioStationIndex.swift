import Foundation

/// Thread-safe search index over brand-level top-radio stations (keyed by slug).
public actor TopRadioStationIndex {

    public let lookups: TopRadioLookups

    private var stations: [String: TopRadioStation] = [:]

    private var nameIndex: [String: Set<String>] = [:]
    private var ngramIndex: [String: Set<String>] = [:]
    private var genreIndex: [String: Set<String>] = [:]
    private var cityIndex: [String: Set<String>] = [:]
    private var countryIndex: [String: Set<String>] = [:]

    private var docLength: [String: Int] = [:]
    private var avgDocLength: Double = 0
    private var documentFrequency: [String: Int] = [:]
    private var totalDocs: Int = 0

    public static func build(_ dump: TopRadioDump) async -> TopRadioStationIndex {
        await build(dump.lookups())
    }

    public static func build(_ lookups: TopRadioLookups) async -> TopRadioStationIndex {
        let index = TopRadioStationIndex(lookups: lookups)
        await index.index(lookups.stations)
        return index
    }

    private init(lookups: TopRadioLookups) {
        self.lookups = lookups
    }

    public var stationCount: Int {
        stations.count
    }

    private func index(_ input: [TopRadioStation]) {
        for station in input {
            stations[station.slug] = station

            let tokens = Tokenizer.tokenize(station.title)
            docLength[station.slug] = tokens.count
            totalDocs += 1

            let uniqueTokens = Set(tokens.map { $0.lowercased() })
            for token in uniqueTokens {
                documentFrequency[token, default: 0] += 1

                for i in 1...min(4, token.count) {
                    let prefix = String(token.prefix(i))
                    nameIndex[prefix, default: []].insert(station.slug)
                }

                for gram in NGram.grams(token) {
                    ngramIndex[gram, default: []].insert(station.slug)
                }
            }

            for genre in station.genres {
                genreIndex[genre, default: []].insert(station.slug)
            }
            for citySlug in station.citySlugs {
                cityIndex[citySlug, default: []].insert(station.slug)
            }
            for countrySlug in station.countrySlugs {
                countryIndex[countrySlug, default: []].insert(station.slug)
            }
        }

        if !docLength.isEmpty {
            avgDocLength = Double(docLength.values.reduce(0, +)) / Double(docLength.count)
        }
    }

    private func idf(_ term: String) -> Double {
        let df = Double(documentFrequency[term] ?? 0)
        return log((Double(totalDocs) - df + 0.5) / (df + 0.5) + 1)
    }

    public func search(
        query: String? = nil,
        countrySlug: String? = nil,
        citySlug: String? = nil,
        genre: String? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) -> [TopRadioStation] {
        var allowedIDs: Set<String>? = nil

        func intersect(_ ids: Set<String>) {
            if let existing = allowedIDs {
                allowedIDs = existing.intersection(ids)
            } else {
                allowedIDs = ids
            }
        }

        if let countrySlug, let ids = countryIndex[countrySlug] { intersect(ids) }
        if let citySlug, let ids = cityIndex[citySlug] { intersect(ids) }
        if let genre, let ids = genreIndex[genre] { intersect(ids) }

        guard let query, !query.isEmpty else {
            let base = stations.values.filter { allowedIDs == nil || allowedIDs!.contains($0.slug) }
            return Array(
                base.sorted { lhs, rhs in
                    let lv = lhs.votes ?? 0
                    let rv = rhs.votes ?? 0
                    if lv != rv { return lv > rv }
                    return lhs.title < rhs.title
                }
                .dropFirst(offset)
                .prefix(limit)
            )
        }

        let tokens = Tokenizer.tokenize(query).map { Transliteration.latin($0).lowercased() }
        var scores: [String: Double] = [:]

        let k1 = 1.5
        let b = 0.75
        let lowerQuery = query.lowercased()

        for token in tokens {
            let idfValue = idf(token)
            let candidateIDs = nameIndex[token] ?? []

            for id in candidateIDs {
                if let allowed = allowedIDs, !allowed.contains(id) { continue }
                guard let station = stations[id], let dl = docLength[id] else { continue }

                let nameTokens = Tokenizer.tokenize(station.title).map { $0.lowercased() }
                let freq = Double(nameTokens.filter { $0 == token }.count)
                if freq == 0 { continue }

                let numerator = freq * (k1 + 1)
                let denominator = freq + k1 * (1 - b + b * Double(dl) / max(avgDocLength, 1))
                scores[id, default: 0] += idfValue * (numerator / denominator) * 100
            }
        }

        for token in tokens {
            if let ids = nameIndex[token] {
                for id in ids {
                    if let allowed = allowedIDs, !allowed.contains(id) { continue }
                    scores[id, default: 0] += 50
                }
            }
        }

        for token in tokens {
            for gram in NGram.grams(token) {
                if let ids = ngramIndex[gram] {
                    for id in ids {
                        if let allowed = allowedIDs, !allowed.contains(id) { continue }
                        scores[id, default: 0] += 5
                    }
                }
            }
        }

        for (id, station) in stations {
            if let allowed = allowedIDs, !allowed.contains(id) { continue }
            let nameLower = station.title.lowercased()
            if nameLower == lowerQuery {
                scores[id, default: 0] += 500
            } else if nameLower.contains(lowerQuery) {
                scores[id, default: 0] += 100
            }
        }

        for (id, station) in stations {
            if let allowed = allowedIDs, !allowed.contains(id) { continue }
            if let votes = station.votes {
                scores[id, default: 0] += log(Double(votes) + 1) * 10
            }
        }

        if scores.isEmpty {
            let base = stations.values.filter { allowedIDs == nil || allowedIDs!.contains($0.slug) }
            return Array(base.prefix(limit))
        }

        return scores
            .sorted { $0.value > $1.value }
            .dropFirst(offset)
            .prefix(limit)
            .compactMap { stations[$0.key] }
    }

    public func autocomplete(query: String, limit: Int = 20) -> [TopRadioStation] {
        let tokens = Tokenizer.tokenize(query)
        guard let lastToken = tokens.last?.lowercased(), !lastToken.isEmpty else { return [] }
        guard let ids = nameIndex[lastToken] else { return [] }

        let lowerQuery = query.lowercased()
        let candidates = ids.compactMap { stations[$0] }

        let sorted = candidates.sorted {
            let aStarts = $0.title.lowercased().hasPrefix(lowerQuery)
            let bStarts = $1.title.lowercased().hasPrefix(lowerQuery)
            if aStarts != bStarts { return aStarts }
            let aVotes = $0.votes ?? 0
            let bVotes = $1.votes ?? 0
            if aVotes != bVotes { return aVotes > bVotes }
            return $0.title < $1.title
        }

        return Array(sorted.prefix(limit))
    }

    public func stations(inCity citySlug: String) -> [CityStation] {
        lookups.cityStationsByCity[citySlug] ?? []
    }

    public func cities(inCountry countrySlug: String) -> [City] {
        lookups.dump.cities.filter { $0.countrySlug == countrySlug }
    }

    public func locals(forSlug slug: String) -> [CityStation] {
        lookups.locals(forSlug: slug)
    }

    public func web(forSlug slug: String) -> WebStation? {
        lookups.web(forSlug: slug)
    }

    public func allGenres() -> [String] {
        Array(genreIndex.keys.sorted())
    }

    public func allCities() -> [City] {
        lookups.dump.cities
    }

    public func stationCountsByCountry() -> [(String, Int)] {
        countryIndex.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }

    public func stationCountsByCity() -> [(String, Int)] {
        cityIndex.map { ($0.key, $0.value.count) }.sorted { $0.1 > $1.1 }
    }
}
