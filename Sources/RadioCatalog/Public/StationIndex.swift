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
                documentFrequency[token, default: 0] += 1
                
                // PREFIX INDEX
                for i in 1...min(4, token.count) {
                    let prefix = String(token.prefix(i))
                    nameIndex[prefix, default: []].insert(station.id)
                }

                // NGRAM INDEX
                for gram in NGram.grams(token) {
                    ngramIndex[gram, default: []].insert(station.id)
                }
            }

            for genre in station.genres {
                genresIndex[genre, default: []].insert(station.id)
            }
            for format in station.formats {
                formatsIndex[format, default: []].insert(station.id)
            }
            for decade in station.decades {
                decadesIndex[decade, default: []].insert(station.id)
            }

            if let cc = station.countryCode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
               !cc.isEmpty {
                countryCodeIndex[cc, default: []].insert(station.id)
            }

            for language in station.languages {
                languageIndex[language, default: []].insert(station.id)
            }
        }

        avgDocLength = Double(docLength.values.reduce(0, +)) / Double(docLength.count)
        countryCodeCounts = countryCodeIndex.mapValues { $0.count }
        languageCounts = languageIndex.mapValues { $0.count }
    }

    private func idf(_ term: String) -> Double {
        let df = Double(documentFrequency[term] ?? 0)
        return log((Double(totalDocs) - df + 0.5) / (df + 0.5) + 1)
    }

    // MARK: - Unified Search

    /// Search stations with filters, BM25 scoring, prefix/ngram boosts, full name boost, and votes.
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

        if let cc = countryCode, let ids = countryCodeIndex[cc] { intersect(ids) }
        if let lang = language, let ids = languageIndex[lang] { intersect(ids) }
        if let gs = genres {
            let ids = gs.compactMap { genresIndex[$0] }.reduce(into: Set<UUID>()) { $0.formUnion($1) }
            if !ids.isEmpty { intersect(ids) }
        }
        if let f = format, let ids = formatsIndex[f] { intersect(ids) }
        if let d = decade, let ids = decadesIndex[d] { intersect(ids) }

        // MARK: - Empty query
        guard let query = query, !query.isEmpty else {
            let base = stations.values.filter { allowedIDs == nil || allowedIDs!.contains($0.id) }
            return Array(base.sorted { $0.name < $1.name }.dropFirst(offset).prefix(limit))
        }

        // MARK: - Scoring
        let tokens = Tokenizer.tokenize(query).map { Transliteration.latin($0).lowercased() }
        var scores: [UUID: Double] = [:]

        let k1 = 1.5
        let b = 0.75
        let lowerQuery = query.lowercased()

        for token in tokens {

            let idfValue = idf(token)

            // Candidate IDs from prefix index
            let candidateIDs = nameIndex[token] ?? []

            for id in candidateIDs {
                if let allowed = allowedIDs, !allowed.contains(id) { continue }
                guard let station = stations[id], let dl = docLength[id] else { continue }

                let nameTokens = Tokenizer.tokenize(station.name).map { $0.lowercased() }
                let freq = Double(nameTokens.filter { $0 == token }.count)
                if freq == 0 { continue }

                let numerator = freq * (k1 + 1)
                let denominator = freq + k1 * (1 - b + b * Double(dl) / avgDocLength)
                let bm25 = idfValue * (numerator / denominator)

                scores[id, default: 0] += bm25 * 100
            }
        }

        // Prefix boost
        for token in tokens {
            if let ids = nameIndex[token] {
                for id in ids {
                    if let allowed = allowedIDs, !allowed.contains(id) { continue }
                    scores[id, default: 0] += 50
                }
            }
        }

        // NGram boost
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

        // Full name exact match boost
        for (id, station) in stations {
            if let allowed = allowedIDs, !allowed.contains(id) { continue }

            let stationNameLower = station.name.lowercased()
            if stationNameLower == lowerQuery {
                scores[id, default: 0] += 500 // exact match boost
            } else if stationNameLower.contains(lowerQuery) {
                scores[id, default: 0] += 100 // substring match
            }
        }

        // Votes boost
        for (id, station) in stations {
            if let allowed = allowedIDs, !allowed.contains(id) { continue }
            if let votes = station.votes {
                scores[id, default: 0] += log(Double(votes) + 1) * 10
            }
        }

        // Fallback
        if scores.isEmpty {
            let base = stations.values.filter { allowedIDs == nil || allowedIDs!.contains($0.id) }
            return Array(base.prefix(limit))
        }

        // Sort + paginate
        return scores
            .sorted { $0.value > $1.value }
            .dropFirst(offset)
            .prefix(limit)
            .compactMap { stations[$0.key] }
    }

    // MARK: - Autocomplete

    public func autocomplete(query: String, limit: Int = 20) -> [Station] {
        let tokens = Tokenizer.tokenize(query)
        guard let lastToken = tokens.last?.lowercased(), !lastToken.isEmpty else { return [] }
        guard let ids = nameIndex[lastToken] else { return [] }

        let lowerQuery = query.lowercased()
        let candidates = ids.compactMap { stations[$0] }

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

    // MARK: - Metadata

    public func allGenres() -> [Genre] { Array(genresIndex.keys.sorted()) }
    public func allFormats() -> [StationFormat] { Array(formatsIndex.keys.sorted()) }
    public func allDecades() -> [Decade] { Array(decadesIndex.keys.sorted()) }
    public func stationCountsByCountry() -> [(String, Int)] { countryCodeCounts.sorted { $0.value > $1.value } }
    public func stationCountsByLanguage() -> [(String, Int)] { languageCounts.sorted { $0.value > $1.value } }
}
