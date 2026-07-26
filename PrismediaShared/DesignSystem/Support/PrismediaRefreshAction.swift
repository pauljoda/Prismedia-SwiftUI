import Foundation

@MainActor
enum PrismediaRefreshAction {
    static let minimumIndicatorDuration: Duration = .milliseconds(450)

    static func perform(
        minimumDuration: Duration = minimumIndicatorDuration,
        operation: () async -> Void
    ) async {
        let clock = ContinuousClock()
        let startedAt = clock.now

        await operation()

        guard !Task.isCancelled else { return }
        let elapsed = startedAt.duration(to: clock.now)
        guard elapsed < minimumDuration else { return }
        try? await Task.sleep(for: minimumDuration - elapsed)
    }
}
