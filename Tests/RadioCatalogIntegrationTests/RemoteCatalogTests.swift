import Testing
import Foundation
@testable import RadioCatalog

@Test func remoteCatalog_load() async throws {
    let start = Date()
    let stations: [Station] = try await RemoteCatalog.load(size: .large)

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

@Test func remoteCatalog_fetchLatestVersion() async throws {
    let start = Date()
    let v = try await RemoteCatalog.fetchLatestVersion()

    print("fetchLatestVersion: \(v) after \(Date().timeIntervalSince(start)) from start")
}


