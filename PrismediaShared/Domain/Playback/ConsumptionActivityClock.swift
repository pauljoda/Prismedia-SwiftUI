import Foundation

/// Measures active wall-clock time between consumption heartbeats for any medium.
struct ConsumptionActivityClock: Sendable {
    private let maximumHeartbeatSeconds: Double
    private var startedAt: TimeInterval?

    init(maximumHeartbeatSeconds: Double = 60) {
        self.maximumHeartbeatSeconds = max(0, maximumHeartbeatSeconds)
    }

    mutating func start(at time: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        if startedAt == nil { startedAt = time }
    }

    mutating func take(at time: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Double? {
        guard let startedAt else { return nil }
        self.startedAt = time
        let seconds = min(maximumHeartbeatSeconds, max(0, time - startedAt))
        return seconds > 0 ? seconds : nil
    }

    mutating func stop(at time: TimeInterval = ProcessInfo.processInfo.systemUptime) -> Double? {
        let seconds = take(at: time)
        startedAt = nil
        return seconds
    }
}
