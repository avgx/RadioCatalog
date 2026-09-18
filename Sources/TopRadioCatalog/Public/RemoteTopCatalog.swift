import Foundation
import ZIPFoundation

public enum RemoteTopCatalog {

    public static let defaultVersion = "tr-latest"
    public static let fileName = "tr-stations.json"
    public static let zipName = "tr-stations.zip"

    public static func load(version: String = defaultVersion) async throws -> TopRadioDump {
        if let cached = try? loadFromCache(version: version) {
            return cached
        }

        let zipURL = URL(string:
            "https://github.com/avgx/RadioCatalog/releases/download/\(version)/\(zipName)"
        )!

        let (data, _) = try await URLSession.shared.data(from: zipURL)
        let dump = try load(fromZip: data)
        try? saveToCache(dump: dump, version: version)
        return dump
    }

    public static func load(from jsonURL: URL) throws -> TopRadioDump {
        let data = try Data(contentsOf: jsonURL)
        return try JSONDecoder().decode(TopRadioDump.self, from: data)
    }

    public static func load(fromZip data: Data) throws -> TopRadioDump {
        let jsonData = try unzipSingleFile(data: data, fileName: fileName)
        return try JSONDecoder().decode(TopRadioDump.self, from: jsonData)
    }

    public static func fetchLatestVersion() async throws -> String {
        let url = URL(string: "https://api.github.com/repos/avgx/RadioCatalog/releases?per_page=40")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(
                domain: "RemoteTopCatalog",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Cannot fetch releases"]
            )
        }

        struct Release: Decodable { let tag_name: String }
        let releases = try JSONDecoder().decode([Release].self, from: data)
        let tags = releases.map(\.tag_name)

        let monthly = tags.filter { $0.hasPrefix("tr-") && $0.dropFirst(3).allSatisfy(\.isNumber) }
        if let newest = monthly.sorted().last {
            return newest
        }
        if tags.contains(defaultVersion) {
            return defaultVersion
        }
        throw NSError(
            domain: "RemoteTopCatalog",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "No tr-* release found"]
        )
    }
}

extension RemoteTopCatalog {
    private static func cacheURL(version: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cacheDir.appendingPathComponent("tr-stations-\(version).json")
    }

    private static func loadFromCache(version: String) throws -> TopRadioDump? {
        let url = cacheURL(version: version)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try load(from: url)
    }

    private static func saveToCache(dump: TopRadioDump, version: String) throws {
        let url = cacheURL(version: version)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let data = try encoder.encode(dump)
        try data.write(to: url)
    }

    private static func unzipSingleFile(data: Data, fileName: String) throws -> Data {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".zip")
        try data.write(to: tempURL)
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
            try? FileManager.default.removeItem(at: tempDir)
        }

        let archive = try Archive(url: tempURL, accessMode: .read)
        guard let entry = archive[fileName] else {
            throw NSError(
                domain: "RemoteTopCatalog",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "File not found in zip"]
            )
        }

        let outputURL = tempDir.appendingPathComponent(fileName)
        _ = try archive.extract(entry, to: outputURL)
        return try Data(contentsOf: outputURL)
    }
}
