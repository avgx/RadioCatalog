import Foundation

final class StationsBuilder {
    
    var cstations: [CityStationRef] = []
    var stations: [StationRef] = []
    var webStations: [WebStation] = []
    var cityStations: [CityStation] = []
    
    var links: [URL] {
        let x: [String] = [
            cstations.map({ $0.url }),
            stations.map({ $0.url }),
            webStations.map({ $0.url.absoluteString }),
            cityStations.map({ $0.url.absoluteString }),
        ].flatMap({ $0 })
        
        
        let xx = x
            .reduce(into: Set(), { res, next in
                res.insert(next)
            })
        
        let xxx = Array(xx).sorted()
        
        let xxxx = xxx
            .map({ URL(string: $0) })
            .filter({ $0 != nil })
            .map({ $0! })
        
        return xxxx
    }
    
    func saveLinks() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        try (try encoder.encode(self.links)).write(to: URL(fileURLWithPath: "links.json"))
        
        print("links saved: \(links.count)")
    }
    
    func run(genres: [Genre]) async throws {
        for genre in genres {
            try await parseGenrePage(genre: genre)
        }
    }
    
    func run(countries: [Country]) async throws {
        for country in countries {
            try await parseCountryPage(country: country)
        }
    }
    
    func run(cities: [City]) async throws {
        for city in cities {
            try await parseCityPage(city: city)
        }
    }
    
    func parseGenrePage(genre: Genre) async throws {
        print("-----------\nparseGenrePage \(genre)")
        let url = URL(string: genre.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cpp = GenreStationsParser()
        let stations = cpp.parseStations(html: html, genre: genre)
        print(stations.map({$0.description}).joined(separator: "\n"))
        self.stations.append(contentsOf: stations)
        
//        for station in stations {
//            try await parseStationPage(ref: station, genre: genre)
//        }
    }
    
    func parseCountryPage(country: Country) async throws {
        print("-----------\nparseCountryPage \(country)")
        let url = URL(string: country.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cpp = CountryPageParser()
        let (_, stations) = cpp.parse(html: html, country: country)
//        print(stations.map({$0.description}).joined(separator: "\n"))
        self.stations.append(contentsOf: stations)
        
//        for station in stations {
//            try await parseStationPage(ref: station, country: country)
//        }
    }
    
    func parseStationPage(ref: StationRef, country: Country? = nil, genre: Genre? = nil) async throws {
        print("-----------\nparseStationPage \(ref) \(country?.slug ?? "") \(genre?.slug ?? "")")
        let url = URL(string: ref.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let sp = WebStationParser()
        let station = sp.parseStation(html: html, fileURL: url)
        print(station)
        if let station {
            self.webStations.append(station)
        }
    }
    
    func parseCityPage(city: City) async throws {
        print("-----------\nparseCityPage \(city)")
        let url = URL(string: city.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cpp = CityPageParser()
        let cityStations = cpp.parse(html: html, citySlug: city.slug)
        print(cityStations.map({$0.description}).joined(separator: "\n"))
        self.cstations.append(contentsOf: cityStations)
        
//        for station in cityStations {
//            try await parseCityStationPage(ref: station, city: city)
//        }
    }
    
    func parseCityStationPage(ref: CityStationRef, city: City) async throws {
        print("-----------\nparseCityStationPage \(ref) \(city.countrySlug) \(city.slug)")
        
        let url = URL(string: ref.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let parser = CityStationParser()
        
        if let station = parser.parseStation(
            html: html,
            fileURL: url,
            citySlug: city.slug,
            countrySlug: city.countrySlug
        ) {
            print(station)
            self.cityStations.append(station)
        }
    }
    
}
