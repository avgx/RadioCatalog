# RadioCatalog

RadioCatalog is a **thread-safe index and search system for radio stations**, based on [Radio Browser data](https://radio-browser.info/).
It provides fast search, autocomplete, filtering, and ranking by BM25 and votes.

---

## Features

* **Unified search**: BM25 scoring + prefix/ngram boosts + full name matches + votes ranking.
* **Autocomplete**: fast prefix-based suggestions for instant search.
* **Filtering**: by country, language, genres, format, decade.
* **Metadata**: list of all genres, formats, decades, and counts per country/language.
* **Thread-safe**: `StationIndex` is implemented as an `actor`.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/avgx/RadioCatalog.git", from: "1.0.0")
]
```

---

## Quick Start

```swift
let stations: [Station] = try await RemoteCatalog.load(size: .large)
let index = await StationIndex.build(stations)

// Search
let results = await index.search(query: "rock", countryCode: "US", limit: 10)

// Autocomplete
let suggestions = await index.autocomplete(query: "super rock", limit: 5)

```

---

## Core API

### `StationIndex.build(_ stations: [Station]) -> StationIndex`

Builds an index from a list of `Station`.

### `search(...) -> [Station]`

Search stations with scoring and filtering.

**Parameters:**

* `query: String?` — search query (optional). Empty query returns filtered stations sorted by name.
* `countryCode: String?` — filter by ISO country code.
* `language: String?` — filter by station language.
* `genres: [Genre]?` — filter by genres.
* `format: StationFormat?` — filter by format (MP3, AAC, etc.).
* `decade: Decade?` — filter by decade.
* `limit: Int` — max results (default 100).
* `offset: Int` — for pagination (default 0).

### `autocomplete(query: String, limit: Int = 20) -> [Station]`

Fast prefix-based search optimized for autocomplete.

### `allGenres() -> [Genre]`

Return a sorted list of all genres in the index.

### `allFormats() -> [StationFormat]`

Return a sorted list of all formats.

### `allDecades() -> [Decade]`

Return a sorted list of decades.

### `stationCountsByCountry() -> [(String, Int)]`

Counts of stations per country, sorted descending.

### `stationCountsByLanguage() -> [(String, Int)]`

Counts of stations per language, sorted descending.

---

## Usage Examples

```swift
import Foundation

@main
struct ExampleApp {
    static func main() async {
        // Sample stations (in real usage, load with RemoteCatalog)
        let stations: [Station] = [
            Station(id: UUID(), name: "Rock Radio", genres: [.rock], formats: [.mp3], decades: [.decade1990s], countryCode: "US", languages: ["en"], votes: 100),
            Station(id: UUID(), name: "Super Rock Radio Station", genres: [.rock], formats: [.aac], decades: [.decade2000s], countryCode: "US", languages: ["en"], votes: 250),
            Station(id: UUID(), name: "Jazz FM", genres: [.jazz], formats: [.mp3], decades: [.decade1980s], countryCode: "UK", languages: ["en"], votes: 50)
        ]

        let index = await StationIndex.build(stations)

        // --------------------------
        // Example 1: Full search
        // --------------------------
        let results = await index.search(
            query: "Rock Radio",
            countryCode: "US",
            genres: [.rock],
            limit: 5
        )

        print("Search results:")
        for s in results {
            print(" - \(s.name) (\(s.votes ?? 0) votes)")
        }

        // --------------------------
        // Example 2: Autocomplete
        // --------------------------
        let suggestions = await index.autocomplete(query: "Supe", limit: 5)
        print("\nAutocomplete suggestions:")
        for s in suggestions {
            print(" - \(s.name)")
        }

        // --------------------------
        // Example 3: Filter by decade and format
        // --------------------------
        let oldMP3 = await index.search(
            decade: .decade1990s,
            format: .mp3,
            limit: 10
        )
        print("\n1990s MP3 stations:")
        for s in oldMP3 {
            print(" - \(s.name)")
        }

        // --------------------------
        // Example 4: Metadata
        // --------------------------
        print("\nAvailable genres: \(await index.allGenres())")
        print("Available formats: \(await index.allFormats())")
        print("Available decades: \(await index.allDecades())")
        print("Station counts by country: \(await index.stationCountsByCountry())")
        print("Station counts by language: \(await index.stationCountsByLanguage())")
    }
}
```

**Sample Output:**

```
Search results:
 - Super Rock Radio Station (250 votes)
 - Rock Radio (100 votes)

Autocomplete suggestions:
 - Super Rock Radio Station

1990s MP3 stations:
 - Rock Radio

Available genres: [rock, jazz]
Available formats: [mp3, aac]
Available decades: [1980s, 1990s, 2000s]
Station counts by country: [(US, 2), (UK, 1)]
Station counts by language: [(en, 3)]
```

---

## Performance Notes & Indexing Strategy

`RadioCatalog` is designed for **fast search and filtering** over large datasets of radio stations. The core strategies are:

### 1. Index Structure

* **Prefix Index** (`nameIndex`)
  Stores the first 1–4 characters of each station name token. Used for fast candidate retrieval and autocomplete.

* **NGram Index** (`ngramIndex`)
  Stores all character n-grams of each token to support partial matches and fuzzy recall.

* **Tag Indexes** (`genresIndex`, `formatsIndex`, `decadesIndex`, `countryCodeIndex`, `languageIndex`)
  Maps tags to sets of station IDs, enabling **strict filtering** without scanning all stations.

* **Document Metadata**
  `docLength`, `avgDocLength`, and `documentFrequency` are used for BM25 scoring.

---

### 2. Search Strategy

1. **Hard Filters First**
   Filtering by country, language, genres, formats, or decades is applied before scoring. This reduces the candidate set for expensive operations.

2. **BM25 Scoring**
   For a query, each token contributes to a BM25 score based on:

   * Term frequency in the station name.
   * Document length normalization using `avgDocLength`.
   * Inverse document frequency (`idf`) to favor rare terms.

3. **Boosting**

   * **Prefix Boost**: candidate stations matching token prefixes receive additional points.
   * **NGram Boost**: partial token matches increase recall.
   * **Full Name Match Boost**: exact query substring matches receive higher scores.
   * **Votes Boost**: stations with more votes get a proportional score increase.

4. **Fallback**
   If no candidates remain after filtering and scoring, a simple filtered list is returned to ensure results are never empty.

---

### 3. Autocomplete

* Uses **only the prefix index** for maximum speed.
* Prioritizes:

  1. Names starting with the query.
  2. Higher votes.
  3. Alphabetical order.

---

### 4. Thread Safety

* `StationIndex` is implemented as an `actor` in Swift, making **all indexing and search operations safe for concurrent access**.

---

### 5. Scaling Notes

* Prefix + n-gram candidate generation allows BM25 scoring to operate on a subset of stations, **reducing computational cost**.
* Indexing is performed once at startup or when loading new station data (`StationIndex.build`).
* Designed to handle datasets of **100k+ stations efficiently** in memory.

---

## Indexing

Stations are indexed with:

* **Prefix index** for fast autocomplete
* **N-gram index** for partial match recall
* **Tag indexes** (genre, format, decade)
* **Document frequencies** for BM25 ranking
* **Country and language counts**

```mermaid
flowchart TD
    A[StationIndex] --> B[stations (UUID → Station)]
    A --> C[nameIndex (prefix → Set<UUID>)]
    A --> D[ngramIndex (ngram → Set<UUID>)]
    A --> E[genresIndex (Genre → Set<UUID>)]
    A --> F[formatsIndex (StationFormat → Set<UUID>)]
    A --> G[decadesIndex (Decade → Set<UUID>)]
    A --> H[countryCodeIndex (String → Set<UUID>)]
    A --> I[languageIndex (String → Set<UUID>)]
    A --> J[docLength (UUID → Int)]
    A --> K[avgDocLength (Double)]
    A --> L[documentFrequency (String → Int)]

    C -->|prefix match| M[Candidate UUIDs]
    D -->|ngram match| M
    E -->|genre filter| M
    F -->|format filter| M
    G -->|decade filter| M
    H -->|country filter| M
    I -->|language filter| M

    M --> N[Scoring: BM25 + boosts + votes]
    N --> O[Sorted Station Results]
```


```
                   ┌───────────────────────┐
                   │     StationIndex      │
                   │  (all stations + idx) │
                   └─────────┬─────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
 ┌───────────────┐   ┌───────────────┐   ┌───────────────┐
 │  nameIndex    │   │  ngramIndex   │   │ tagIndexes    │
 │ (prefix → IDs)│   │ (ngram → IDs) │   │ genre/format/ │
 │               │   │               │   │ decade → IDs  │
 └───────────────┘   └───────────────┘   └───────────────┘
         │                   │                   │
         └───────────┬───────┴───────┬───────────┘
                     │               │
             ┌───────▼────────┐      │
             │ Candidate UUIDs│◄─────┘
             │ (after filters)│
             └───────┬────────┘
                     │
            ┌────────▼────────┐
            │  Scoring Layer  │
            │ BM25 + boosts   │
            │ + votes         │
            └────────┬────────┘
                     │
             ┌───────▼────────┐
             │ Sorted Results │
             │  [Station]     │
             └────────────────┘
```

---

## Data Source

RadioCatalog uses data fetched from [Radio Browser API](https://all.api.radio-browser.info/) with options to hide broken streams and limit results.
