import Foundation

enum TopRadioCatalogBuilderMain {
    static func main() async {
        var state: HarvestState?
        do {
            let cli = try CLI.parse(CommandLine.arguments)
            let io = try HarvestIO(outDir: cli.outDir)
            let harvest = HarvestState(io: io)
            state = harvest

            let interrupt = InterruptGuard()
            interrupt.install {
                harvest.requestStop()
                harvest.dumpAll()
            }

            let runner = CommandRunner(state: harvest)
            try await runner.run(cli.command)
            print("Done")
        } catch is CancellationError {
            state?.dumpAll()
            print("Stopped")
            Foundation.exit(130)
        } catch let error as CLIError {
            fputs("Error: \(error)\n", stderr)
            Foundation.exit(2)
        } catch {
            state?.dumpAll()
            fputs("Error: \(error)\n", stderr)
            Foundation.exit(1)
        }
    }
}

await TopRadioCatalogBuilderMain.main()
