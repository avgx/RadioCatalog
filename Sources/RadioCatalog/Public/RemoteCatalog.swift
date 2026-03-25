import Foundation
import ZIPFoundation

public enum RemoteCatalog {
    
    public enum Size: String {
        case small, medium, large
    }
    
    public static func load( size: Size, version: String = "latest" ) async throws -> [Station] {
        if let cached = try? loadFromCache(size: size, version: version) {
            return cached
        }
        
        let zipURL = URL(string:
          "https://github.com/avgx/RadioCatalog/releases/download/\(version)/stations-\(size.rawValue).zip"
        )!
        
        let (data, _) = try await URLSession.shared.data(from: zipURL)
        
        let jsonData = try unzipSingleFile(data: data, fileName: "stations-\(size.rawValue).json")
        
        let stations = try JSONDecoder().decode([Station].self, from: jsonData)
        
        try? saveToCache(stations: stations, size: size, version: version)
        
        return stations
    }
    
    public static func bundledSmall() -> [Station] {
        guard let url = Bundle.main.url(forResource: "stations-small", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stations = try? JSONDecoder().decode([Station].self, from: data)
        else { return [] }
        return stations
    }
    
    public static func fetchLatestVersion() async throws -> String {
        let url = URL(string: "https://api.github.com/repos/avgx/RadioCatalog/releases/latest")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "RemoteCatalog", code: 3, userInfo: [NSLocalizedDescriptionKey: "Cannot fetch latest release"])
        }
        
        struct Release: Decodable { let tag_name: String }
        let release = try JSONDecoder().decode(Release.self, from: data)
        return release.tag_name
    }
}

extension RemoteCatalog {
    private static func cacheURL(size: Size, version: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDir.appendingPathComponent("stations-\(size.rawValue)-\(version).json")
    }

    private static func loadFromCache(size: Size, version: String) throws -> [Station]? {
        let url = cacheURL(size: size, version: version)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([Station].self, from: data)
    }

    private static func saveToCache(stations: [Station], size: Size, version: String) throws {
        let url = cacheURL(size: size, version: version)
        let data = try JSONEncoder().encode(stations)
        try data.write(to: url)
    }

    private static func unzipSingleFile(data: Data, fileName: String) throws -> Data {
        //via ZIPFoundation
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        try data.write(to: tempURL)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let archive = try Archive(url: tempURL, accessMode: .read)
        
        guard let entry = archive[fileName]
        else { throw NSError(domain: "RemoteCatalog", code: 4, userInfo: [NSLocalizedDescriptionKey: "File not found in zip"]) }

        let outputURL = tempDir.appendingPathComponent(fileName)
        _ = try archive.extract(entry, to: outputURL)
        let jsonData = try Data(contentsOf: outputURL)

        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
        try? FileManager.default.removeItem(at: tempDir)

        return jsonData
    }
}
