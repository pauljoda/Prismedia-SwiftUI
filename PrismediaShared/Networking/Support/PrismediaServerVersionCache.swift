import Foundation

/// Remembers the connected server's build version for the lifetime of one API client session, so
/// version-gated features read `GET /api/health` once.
final class PrismediaServerVersionCache: @unchecked Sendable {
    // MARK: - Variables

    private let lock = NSLock()
    private var version: PrismediaServerVersion?
    private var isResolved = false

    /// The resolved version: `.some(nil)` for a server that reports none, `.none` before the
    /// first successful lookup.
    var resolution: PrismediaServerVersion?? {
        lock.withLock { isResolved ? .some(version) : .none }
    }

    // MARK: - Mutators

    func resolve(_ version: PrismediaServerVersion?) {
        lock.withLock {
            self.version = version
            isResolved = true
        }
    }
}
