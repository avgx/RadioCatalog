import Foundation

final class HarvestIO: @unchecked Sendable {
    let outDir: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    init(outDir: URL) throws {
        self.outDir = outDir
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    func fileURL(_ name: String) -> URL {
        outDir.appendingPathComponent(name)
    }

    func save<T: Encodable>(_ value: T, as name: String, pretty: Bool = true) throws {
        lock.lock()
        defer { lock.unlock() }
        encoder.outputFormatting = pretty
            ? [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
            : [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(value)
        try data.write(to: fileURL(name), options: .atomic)
        print("saved \(name)")
    }

    func load<T: Decodable>(_ type: T.Type, from name: String) throws -> T? {
        let url = fileURL(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
}
