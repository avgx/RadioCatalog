import Foundation

struct CLI {
    enum Command: String, CaseIterable {
        case rating
        case genres
        case countries
        case cities
        case web
        case city
        case assemble
        case all
    }

    var outDir: URL
    var command: Command

    static func parse(_ arguments: [String]) throws -> CLI {
        var outDir = URL(fileURLWithPath: "Dumps", isDirectory: true)
        var command = Command.all
        var args = Array(arguments.dropFirst())

        while !args.isEmpty {
            let arg = args.removeFirst()
            if arg == "--out" {
                guard let path = args.first else {
                    throw CLIError.missingOutPath
                }
                args.removeFirst()
                outDir = URL(fileURLWithPath: path, isDirectory: true)
            } else if arg.hasPrefix("--") {
                throw CLIError.unknownOption(arg)
            } else if let parsed = Command(rawValue: arg) {
                command = parsed
            } else {
                throw CLIError.unknownCommand(arg)
            }
        }

        return CLI(outDir: outDir, command: command)
    }
}

enum CLIError: Error, CustomStringConvertible {
    case missingOutPath
    case unknownOption(String)
    case unknownCommand(String)

    var description: String {
        switch self {
        case .missingOutPath:
            return "Missing path after --out"
        case .unknownOption(let option):
            return "Unknown option \(option)"
        case .unknownCommand(let command):
            return "Unknown command \(command). Use: \(CLI.Command.allCases.map(\.rawValue).joined(separator: ", "))"
        }
    }
}
