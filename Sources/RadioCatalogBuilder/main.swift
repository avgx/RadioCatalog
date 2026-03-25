import Foundation

struct Builder {

    static func main() throws {
        let args = CommandLine.arguments

        let input = args.dropFirst().first ?? "offline.json"
        let output = args.dropFirst().dropFirst().first ?? "stations"
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        
        let data = try Data(contentsOf: URL(fileURLWithPath: input))
        let raw = try JSONDecoder().decode([RadioBrowserStation].self, from: data)

        let mapped = raw.compactMap { $0.toStation() }

        try Size.allCases.forEach { size in
            let trimmed = size.limit != nil ? Array(mapped.prefix(size.limit!)) : mapped
            let file = "\(output)-\(size).json"
            let data = try encoder.encode(trimmed)
            try data.write(to: URL(fileURLWithPath: file))

            print("\(file): \(trimmed.count) stations [\(data.count)bytes]")
        }

        print("Done")
    }
    
}

try Builder.main()
