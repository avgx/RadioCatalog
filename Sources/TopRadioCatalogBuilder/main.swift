import Foundation

URLSession.shared.configuration.requestCachePolicy = .returnCacheDataElseLoad
URLSession.shared.configuration.urlCache = .shared

//let ratingBuilder = RatingBuilder()
//try await ratingBuilder.run()
////try await ratingBuilder.save()
//
let genresBuilder = GenresBuilder()
try await genresBuilder.run()
////try await genresBuilder.save()
//
let countriesBuilder = CountriesBuilder()
try await countriesBuilder.run()
////try await countriesBuilder.save()
//
let citiesBuilder = CitiesBuilder()
try await citiesBuilder.run(countries: countriesBuilder.countries)
////try await citiesBuilder.save()
//
let stationsBuilder = StationsBuilder()
try await stationsBuilder.run(genres: genresBuilder.genres)
//try await stationsBuilder.run(countries: countriesBuilder.countries)
//try await stationsBuilder.run(cities: citiesBuilder.cities)
try await stationsBuilder.saveLinks()

let streamsBuilder = StreamsBuilder()
//try await streamsBuilder.run(urls: [
//    URL(string: "https://top-radio.ru/web/nashe")!,
//    URL(string: "https://top-radio.ru/rostov-na-donu/nashe")!,
//    
//    URL(string: "https://top-radio.ru/web/dorozhnoe")!,
//    URL(string: "https://top-radio.ru/web/nostalgiya-dorozhnoe")!,
//    URL(string: "https://top-radio.ru/web/dorozhnoe-rok-klub")!,
//    URL(string: "https://top-radio.ru/moskva/dorozhnoe")!,
//    URL(string: "https://top-radio.ru/petropavlovsk-kamchatskij/dorozhnoe")!,
//])
try await streamsBuilder.run(urls: Array(stationsBuilder.links.prefix(200)))
try await streamsBuilder.save()

print("Done")
