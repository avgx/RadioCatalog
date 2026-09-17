import Foundation

final class StreamsBuilder {
    var streams: [Streams] = []
    
    func run(urls: [URL]) async throws {
        let parser = StreamsParser()
        
        for url in urls {
            let html = try await html(url)
            let streams: [Stream] = parser.extractStreams(html).filter({ $0.url != nil })
            self.streams.append(.init(url: url, streams: streams))
        }
    }
    
    func save() async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        
        try (try encoder.encode(self.streams)).write(to: URL(fileURLWithPath: "streams.json"))
        
        print("streams saved: \(streams.count)")
    }
    
    func html(_ url: URL) async throws -> String {
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        return html
    }
    
}
