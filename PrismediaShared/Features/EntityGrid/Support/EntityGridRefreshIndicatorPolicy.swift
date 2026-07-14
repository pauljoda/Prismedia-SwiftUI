import Foundation

struct EntityGridRefreshIndicatorPolicy: Sendable {
    static let minimumDuration: Duration = .milliseconds(450)

    static func remainingDuration(after elapsed: Duration) -> Duration? {
        guard elapsed < minimumDuration else { return nil }
        return minimumDuration - elapsed
    }
}
