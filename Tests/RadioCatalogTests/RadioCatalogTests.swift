import Testing
import Foundation
@testable import RadioCatalog

@Test func radioCatalogBuildIndex() async throws {
    let start = Date()
    let stations: [Station] = try CatalogLoader.load()

    print("stations loaded (\(stations.count)) after \(Date().timeIntervalSince(start)) from start")
    let index = await StationIndex.build(stations)
    print("index build for (\(stations.count)) after \(Date().timeIntervalSince(start)) from start")
    let genres = await index.allGenres()
    print("\(genres)")
    let stationCountsByCountry = await index.stationCountsByCountry()
    print("\(stationCountsByCountry)")
    let stationCountsByLanguage = await index.stationCountsByLanguage()
    print("\(stationCountsByLanguage)")
}
