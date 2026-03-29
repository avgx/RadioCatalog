import Foundation

final class Builder {
    var rating: [RatingEntry] = []
    var genres: [Genre] = []
    var countries: [Country] = []
    var cities: [City] = []
    var cstations: [CityStationRef] = []
    var stations: [StationRef] = []
    var webStations: [WebStation] = []
    var cityStations: [CityStation] = []
    
    func parseCountries() async throws {
        let url = URL(string: "https://top-radio.ru/stranyi")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cp = CountryParser()
        let countries = cp.parseCountries(html: html, baseURL: URL(string: "https://top-radio.ru")!)
        print(countries.map({$0.description}).joined(separator: "\n"))
        self.countries = countries
        
        for country in countries {
            try await parseCountryPage(country: country)
        }
    }
    
    func parseCountryPage(country: Country) async throws {
        print("-----------\nparseCountryPage \(country)")
        let url = URL(string: country.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cpp = CountryPageParser()
        let (cities, stations) = cpp.parse(html: html, country: country, baseURL: URL(string: "https://top-radio.ru")!)
        print(cities.map({$0.description}).joined(separator: "\n"))
        print(stations.map({$0.description}).joined(separator: "\n"))
        self.cities.append(contentsOf: cities)
        self.stations.append(contentsOf: stations)
        
        for city in cities {
            try await parseCityPage(city: city, country: country)
        }
        
        for station in stations {
            try await parseStationPage(ref: station, country: country)
        }
    }
    
    func parseCityPage(city: City, country: Country) async throws {
        print("-----------\nparseCityPage \(city)")
        let url = URL(string: city.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cpp = CityPageParser()
        let cityStations = cpp.parse(html: html, baseURL: URL(string: "https://top-radio.ru")!, citySlug: city.slug)
        print(cityStations.map({$0.description}).joined(separator: "\n"))
        self.cstations.append(contentsOf: cityStations)
        
        for station in cityStations {
            try await parseCityStationPage(ref: station, city: city, country: country)
        }
    }
    
    func parseGenres() async throws {
        let url = URL(string: "https://top-radio.ru/genres")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let gp = GenreParser()
        let genres = gp.parseGenres(html: html, baseURL: URL(string: "https://top-radio.ru")!)
        print(genres.map({$0.description}).joined(separator: "\n"))
        self.genres = genres
        
        for genre in genres {
            try await parseGenrePage(genre: genre)
        }
    }
    
    func parseGenrePage(genre: Genre) async throws {
        print("-----------\nparseGenrePage \(genre)")
        let url = URL(string: genre.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let cpp = GenreStationsParser()
        let stations = cpp.parseStations(html: html, genre: genre, baseURL: URL(string: "https://top-radio.ru")!)
        print(stations.map({$0.description}).joined(separator: "\n"))
        self.stations.append(contentsOf: stations)
        
        for station in stations {
            try await parseStationPage(ref: station, genre: genre)
        }
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
    
    func parseCityStationPage(ref: CityStationRef, city: City, country: Country) async throws {
        print("-----------\nparseStationPage \(ref) \(country.slug) \(city.slug)")
        let url = URL(string: ref.url)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        //TODO: impl
//        let ssp = CityStationParser()
//        let station = sp.parseStation(html: html, fileURL: url)
//        print(station)
//        if let station {
//            self.cityStations.append(station)
//        }
    }
    
    func parseRating() async throws {
        let url = URL(string: "https://top-radio.ru/rating")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""
        
        let rp = RatingParser()
        let ratings: [RatingEntry] = rp.parse(html: html, baseURL: URL(string: "https://top-radio.ru")!)
        print(ratings.map({$0.description}).joined(separator: "\n"))
        self.rating.append(contentsOf: ratings)
        
        /// докачка ajax
        let ratings100: [RatingEntry] = try await fetchAllRatings(baseURL: URL(string: "https://top-radio.ru")!)
        print(ratings100.map({$0.description}).joined(separator: "\n"))
        self.rating.append(contentsOf: ratings100)
    }
    
    func fetchAllRatings(baseURL: URL) async throws -> [RatingEntry] {
        
        var all: [RatingEntry] = []
        
        let rp = RatingParser()
        
        // 1. первая страница уже распарсена ранее
        // all += firstPage
        
        var offset = 100
        
        while true {
            print("➡️ rating offset \(offset)")
            
            let html = try await fetchRatingPage(offset: offset)
            let chunk = rp.parseAjaxPage(html, baseURL: baseURL)
            
            if chunk.isEmpty {
                break
            }
            
            all.append(contentsOf: chunk)
            
            if chunk.count < 50 {
                break
            }
            
            offset += 50
        }
        
        return all
    }
    
    func fetchRatingPage(offset: Int) async throws -> String {
        let url = URL(string: "https://top-radio.ru/ajax")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("application/x-www-form-urlencoded; charset=UTF-8",
                         forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://top-radio.ru/rating", forHTTPHeaderField: "Referer")
        request.setValue("https://top-radio.ru", forHTTPHeaderField: "Origin")
        
        let body = "action=rating&offset=\(offset)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return String(decoding: data, as: UTF8.self)
    }
    
    /*
    <li><label class="checkbox-label"><input type="checkbox" value="7886" name="" onchange="changeFavorite($(this))"><span></span></label><a href="web/comedy" title="Comedy Radio"><img class="b-lazy" data-src="assets/image/radio/100/comedyradio.png" src="assets/image/load.gif" alt="Comedy Radio"><p>Comedy Radio</p></a></li>

    <li><label class="checkbox-label"><input type="checkbox" value="7107" name="" onchange="changeFavorite($(this))"><span></span></label><a href="web/relax-fm" title="Relax FM"><img class="b-lazy" data-src="assets/image/radio/100/relaxfmru.png" src="assets/image/load.gif" alt="Relax FM"><p>Relax FM</p></a></li>
     */
    // пока бесполезно, но так можно.
    func fetchStationsAjax(offset: Int) async throws -> String {
        let url = URL(string: "https://top-radio.ru/ajax")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("https://top-radio.ru/web", forHTTPHeaderField: "Referer")
        
        let body = "action=web-radio&offset=\(offset)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return String(decoding: data, as: UTF8.self)
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        
        try (try encoder.encode(self.rating)).write(to: URL(fileURLWithPath: "rating.json"))
        try (try encoder.encode(self.genres)).write(to: URL(fileURLWithPath: "genres.json"))
        try (try encoder.encode(self.countries)).write(to: URL(fileURLWithPath: "countries.json"))
        try (try encoder.encode(self.cities)).write(to: URL(fileURLWithPath: "cities.json"))
        try (try encoder.encode(self.cstations)).write(to: URL(fileURLWithPath: "cstations.json"))
        try (try encoder.encode(self.stations)).write(to: URL(fileURLWithPath: "stations.json"))
        try (try encoder.encode(self.webStations)).write(to: URL(fileURLWithPath: "webStations.json"))
        try (try encoder.encode(self.cityStations)).write(to: URL(fileURLWithPath: "cityStations.json"))
        
    }
    
    func main() async throws {
        try await parseRating()
        try await parseCountries()
        try await parseGenres()
        try await save()
    }
}


try await Builder().main()


