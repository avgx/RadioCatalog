import Darwin
import Foundation

final class InterruptGuard: @unchecked Sendable {
    private var sources: [DispatchSourceSignal] = []
    private let lock = NSLock()
    private var fired = false

    func install(_ handler: @escaping () -> Void) {
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        for sig in [SIGINT, SIGTERM] {
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .global())
            source.setEventHandler { [weak self] in
                guard let self else { return }
                self.lock.lock()
                if self.fired {
                    self.lock.unlock()
                    return
                }
                self.fired = true
                self.lock.unlock()
                print("interrupt (\(sig)), dumping…")
                handler()
                Foundation.exit(sig == SIGINT ? 130 : 143)
            }
            source.resume()
            sources.append(source)
        }
    }
}
