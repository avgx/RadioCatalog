import Foundation

/// Thread-safe index of radio stations with scoring and filtering.
public actor StationIndex {

    // MARK: - Private storage

    private var stations: [UUID: Station] = [:]

    private var nameIndex: [String: Set<UUID>] = [:]      // prefix index
    private var ngramIndex: [String: Set<UUID>] = [:]
    private var genresIndex: [Genre: Set<UUID>] = [:]
    private var formatsIndex: [StationFormat: Set<UUID>] = [:]
    private var decadesIndex: [Decade: Set<UUID>] = [:]

    private var countryCodeIndex: [String: Set<UUID>] = [:]
    private var countryCodeCounts: [String: Int] = [:]

    private var languageIndex: [String: Set<UUID>] = [:]
    private var languageCounts: [String: Int] = [:]

    private var docLength: [UUID: Int] = [:]
    private var avgDocLength: Double = 0
    
    private var documentFrequency: [String: Int] = [:]
    private var totalDocs: Int = 0
    
    // MARK: - Construction

    /// Build an index from a list of stations.
    public static func build(_ stations: [Station]) async -> StationIndex {
        let index = StationIndex()
        await index.index(stations)
        return index
    }

    /// Number of indexed stations.
    public var stationCount: Int {
        stations.count
    }

    // MARK: - Indexing

    private func index(_ input: [Station]) {
        for station in input {
            stations[station.id] = station

            let tokens = Tokenizer.tokenize(station.name)
            docLength[station.id] = tokens.count
            
            totalDocs += 1

            let uniqueTokens = Set(tokens.map { $0.lowercased() })
            
            for token in uniqueTokens {
                let lowerToken = token.lowercased()
                documentFrequency[token, default: 0] += 1
                
                // PREFIX INDEX
                for i in 1...min(4, lowerToken.count) {
                    let prefix = String(lowerToken.prefix(i))
                    nameIndex[prefix, default: []].insert(station.id)
                }

                // NGRAM INDEX
                for gram in NGram.grams(lowerToken) {
                    ngramIndex[gram, default: []].insert(station.id)
                }
            }

            // TAG INDEXES
            for genre in station.genres {
                genresIndex[genre, default: []].insert(station.id)
            }
            for format in station.formats {
                formatsIndex[format, default: []].insert(station.id)
            }
            for decade in station.decades {
                decadesIndex[decade, default: []].insert(station.id)
            }

            if let cc = station.countryCode?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased(),
               !cc.isEmpty {
                countryCodeIndex[cc, default: []].insert(station.id)
            }

            for language in station.languages {
                languageIndex[language, default: []].insert(station.id)
            }
        }

        avgDocLength = Double(docLength.values.reduce(0, +)) / Double(docLength.count)
        
        // Reduce to counts
        countryCodeCounts = countryCodeIndex
            .filter { !$0.key.isEmpty }
            .mapValues { $0.count }
        languageCounts = languageIndex.mapValues { $0.count }
    }
    
    private func idf(_ term: String) -> Double {
        let df = Double(documentFrequency[term] ?? 0)
        return log((Double(totalDocs) - df + 0.5) / (df + 0.5) + 1)
    }

    // MARK: - Search

    /// Search stations by query string with scoring and strict filtering.
    public func search(
        query: String? = nil,
        countryCode: String? = nil,
        language: String? = nil,
        genres: [Genre]? = nil,
        decade: Decade? = nil,
        format: StationFormat? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) -> [Station] {

        // MARK: - Build allowed IDs (HARD FILTERS)

        var allowedIDs: Set<UUID>? = nil

        func intersect(_ ids: Set<UUID>) {
            if let existing = allowedIDs {
                allowedIDs = existing.intersection(ids)
            } else {
                allowedIDs = ids
            }
        }

        if let countryCode,
           let ids = countryCodeIndex[countryCode] {
            intersect(ids)
        }

        if let language,
           let ids = languageIndex[language] {
            intersect(ids)
        }

        if let genres {
            let ids = genres
                .compactMap { genresIndex[$0] }
                .reduce(into: Set<UUID>()) { $0.formUnion($1) }

            if !ids.isEmpty {
                intersect(ids)
            }
        }

        if let format,
           let ids = formatsIndex[format] {
            intersect(ids)
        }

        if let decade,
           let ids = decadesIndex[decade] {
            intersect(ids)
        }

        // MARK: - Empty query → filtered + sorted

        if query == nil || query!.isEmpty {
            let base = stations.values.filter {
                allowedIDs == nil || allowedIDs!.contains($0.id)
            }

            return Array(
                base.sorted { $0.name < $1.name }
                    .dropFirst(offset)
                    .prefix(limit)
            )
        }

        // MARK: - Scoring

        let tokens = Tokenizer.tokenize(query!)
        var scores: [UUID: Int] = [:]

        for token in tokens {
            let normalized = Transliteration.latin(token).lowercased()

            // FULL MATCH (still O(N), acceptable for now)
            for (id, station) in stations {
                if station.name.lowercased().contains(normalized) {
                    scores[id, default: 0] += 200
                }
            }

            // PREFIX
            if let ids = nameIndex[normalized] {
                for id in ids {
                    scores[id, default: 0] += 100
                }
            }

            // NGRAM
            for gram in NGram.grams(normalized) {
                if let ids = ngramIndex[gram] {
                    for id in ids {
                        scores[id, default: 0] += 10
                    }
                }
            }
        }

        // MARK: - Apply filters

        let filteredScores = scores.filter { id, _ in
            allowedIDs == nil || allowedIDs!.contains(id)
        }

        // MARK: - Votes boost

        var finalScores = filteredScores

        for (id, _) in finalScores {
            if let votes = stations[id]?.votes {
                finalScores[id]! += Int(log(Double(votes) + 1) * 10)
            }
        }

        // MARK: - Fallback (important: still respect filters)

        if finalScores.isEmpty {
            let base = stations.values.filter {
                allowedIDs == nil || allowedIDs!.contains($0.id)
            }

            return Array(
                base.prefix(limit)
            )
        }

        // MARK: - Sort + pagination

        let result = finalScores
            .sorted { $0.value > $1.value }
            .dropFirst(offset)
            .prefix(limit)
            .compactMap { stations[$0.key] }

        return Array(result)
    }

    /// Fast prefix-based search optimized for autocomplete.
    /// Uses prefix index only (no scoring, no full scan).
    public func autocomplete(
        query: String,
        limit: Int = 20
    ) -> [Station] {

        let tokens = Tokenizer.tokenize(query)
        guard let lastToken = tokens.last?.lowercased(), !lastToken.isEmpty else {
            return []
        }

        // Берём кандидатов по последнему токену
        guard let ids = nameIndex[lastToken] else {
            return []
        }

        // Мапим в станции
        let candidates = ids.compactMap { stations[$0] }

        // Простая сортировка:
        // 1. сначала те, у кого имя начинается с query
        // 2. потом по алфавиту
        let lowerQuery = query.lowercased()

        let sorted = candidates.sorted {
            let aStarts = $0.name.lowercased().hasPrefix(lowerQuery)
            let bStarts = $1.name.lowercased().hasPrefix(lowerQuery)

            if aStarts != bStarts { return aStarts }

            let aVotes = $0.votes ?? 0
            let bVotes = $1.votes ?? 0

            if aVotes != bVotes { return aVotes > bVotes }

            return $0.name < $1.name
        }

        return Array(sorted.prefix(limit))
    }
    
    /// Unified search: BM25 + prefix/ngram + votes + strict filters.
    public func searchBM25(
        query: String? = nil,
        countryCode: String? = nil,
        language: String? = nil,
        genres: [Genre]? = nil,
        decade: Decade? = nil,
        format: StationFormat? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) -> [Station] {

        // MARK: - HARD FILTERS

        var allowedIDs: Set<UUID>? = nil

        func intersect(_ ids: Set<UUID>) {
            if let existing = allowedIDs {
                allowedIDs = existing.intersection(ids)
            } else {
                allowedIDs = ids
            }
        }

        if let countryCode,
           let ids = countryCodeIndex[countryCode] {
            intersect(ids)
        }

        if let language,
           let ids = languageIndex[language] {
            intersect(ids)
        }

        if let genres {
            let ids = genres
                .compactMap { genresIndex[$0] }
                .reduce(into: Set<UUID>()) { $0.formUnion($1) }

            if !ids.isEmpty { intersect(ids) }
        }

        if let format,
           let ids = formatsIndex[format] {
            intersect(ids)
        }

        if let decade,
           let ids = decadesIndex[decade] {
            intersect(ids)
        }

        // MARK: - EMPTY QUERY

        if query == nil || query!.isEmpty {
            let base = stations.values.filter {
                allowedIDs == nil || allowedIDs!.contains($0.id)
            }

            return Array(
                base.sorted { $0.name < $1.name }
                    .dropFirst(offset)
                    .prefix(limit)
            )
        }

        // MARK: - PREPARE

        let tokens = Tokenizer.tokenize(query!)
            .map { Transliteration.latin($0).lowercased() }

        var scores: [UUID: Double] = [:]

        let k1 = 1.5
        let b = 0.75

        // MARK: - BM25 CORE

        for token in tokens {

            let idfValue = idf(token)

            // используем prefix index как candidate generator
            guard let candidateIDs = nameIndex[token] else { continue }

            for id in candidateIDs {

                // FILTER EARLY (важно для perf)
                if let allowedIDs, !allowedIDs.contains(id) {
                    continue
                }

                guard let station = stations[id],
                      let dl = docLength[id],
                      avgDocLength > 0 else { continue }

                let nameTokens = Tokenizer.tokenize(station.name)
                    .map { $0.lowercased() }

                let freq = Double(nameTokens.filter { $0 == token }.count)
                if freq == 0 { continue }

                let numerator = freq * (k1 + 1)
                let denominator = freq + k1 * (1 - b + b * Double(dl) / avgDocLength)

                let bm25 = idfValue * (numerator / denominator)

                scores[id, default: 0] += bm25 * 100 // scale for mixing
            }
        }

        // MARK: - PREFIX BOOST

        for token in tokens {
            if let ids = nameIndex[token] {
                for id in ids {
                    if let allowedIDs, !allowedIDs.contains(id) { continue }
                    scores[id, default: 0] += 50
                }
            }
        }

        // MARK: - NGRAM BOOST (recall)

        for token in tokens {
            for gram in NGram.grams(token) {
                if let ids = ngramIndex[gram] {
                    for id in ids {
                        if let allowedIDs, !allowedIDs.contains(id) { continue }
                        scores[id, default: 0] += 5
                    }
                }
            }
        }

        // MARK: - FULL MATCH BOOST (cheap version)

        let lowerQuery = query!.lowercased()

        for (id, station) in stations {
            if let allowedIDs, !allowedIDs.contains(id) { continue }

            if station.name.lowercased().contains(lowerQuery) {
                scores[id, default: 0] += 100
            }
        }

        // MARK: - VOTES BOOST

        for (id, station) in stations {
            if let allowedIDs, !allowedIDs.contains(id) { continue }

            if let votes = station.votes {
                scores[id, default: 0] += log(Double(votes) + 1) * 10
            }
        }

        // MARK: - FALLBACK

        if scores.isEmpty {
            let base = stations.values.filter {
                allowedIDs == nil || allowedIDs!.contains($0.id)
            }

            return Array(base.prefix(limit))
        }

        // MARK: - SORT

        let result = scores
            .sorted { $0.value > $1.value }
            .dropFirst(offset)
            .prefix(limit)
            .compactMap { stations[$0.key] }

        return Array(result)
    }
    
    public func searchBM25(
        query: String,
        limit: Int = 100
    ) -> [Station] {

        let tokens = Tokenizer.tokenize(query).map {
            Transliteration.latin($0).lowercased()
        }

        var scores: [UUID: Double] = [:]

        let k1 = 1.5
        let b = 0.75

        for token in tokens {

            let idfValue = idf(token)

            guard let ids = nameIndex[token] else { continue }

            for id in ids {
                guard let station = stations[id],
                      let dl = docLength[id] else { continue }

                let nameTokens = Tokenizer.tokenize(station.name)
                    .map { $0.lowercased() }

                let freq = Double(nameTokens.filter { $0 == token }.count)

                if freq == 0 { continue }

                let numerator = freq * (k1 + 1)
                let denominator = freq + k1 * (1 - b + b * Double(dl) / avgDocLength)

                let score = idfValue * (numerator / denominator)

                scores[id, default: 0] += score
            }
        }

        return scores
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { stations[$0.key] }
    }
    
    // MARK: - Metadata

    /// List all available genres.
    public func allGenres() -> [Genre] {
        Array(genresIndex.keys.sorted())
    }

    /// List all available formats.
    public func allFormats() -> [StationFormat] {
        Array(formatsIndex.keys.sorted())
    }

    /// List all available decades.
    public func allDecades() -> [Decade] {
        Array(decadesIndex.keys.sorted())
    }

    /// Counts of stations per country sorted descending.
    public func stationCountsByCountry() -> [(String, Int)] {
        countryCodeCounts.sorted { $0.value > $1.value }
    }

    /// Counts of stations per language sorted descending.
    public func stationCountsByLanguage() -> [(String, Int)] {
        languageCounts.sorted { $0.value > $1.value }
    }
}
