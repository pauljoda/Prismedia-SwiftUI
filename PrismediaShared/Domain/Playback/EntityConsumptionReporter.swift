import Foundation

/// Serializes access and active-time reports for one currently viewed Entity.
@MainActor
final class EntityConsumptionReporter {
    private let service: (any EntityConsumptionServicing)?
    private let now: @MainActor () -> TimeInterval
    private var activityClock = ConsumptionActivityClock()
    private var entityID: UUID?
    private var pendingReport: Task<Void, Never>?

    init(
        service: (any EntityConsumptionServicing)?,
        now: @escaping @MainActor () -> TimeInterval = {
            ProcessInfo.processInfo.systemUptime
        }
    ) {
        self.service = service
        self.now = now
    }

    func open(id: UUID, active: Bool = true) {
        if entityID == id {
            if active { resume() }
            return
        }
        reportActivity(stopping: true)
        entityID = id
        activityClock = ConsumptionActivityClock()
        let sessionID = UUID().uuidString.lowercased()
        enqueue { service in
            try await service.recordConsumptionAccess(id: id, sessionID: sessionID)
        }
        if active { activityClock.start(at: now()) }
    }

    func resume() {
        guard entityID != nil else { return }
        activityClock.start(at: now())
    }

    func heartbeat() {
        reportActivity(stopping: false)
    }

    func pause() {
        reportActivity(stopping: true)
    }

    func close() {
        reportActivity(stopping: true)
        entityID = nil
        activityClock = ConsumptionActivityClock()
    }

    func flush() async {
        await pendingReport?.value
    }

    private func reportActivity(stopping: Bool) {
        guard let entityID else { return }
        let seconds = stopping
            ? activityClock.stop(at: now())
            : activityClock.take(at: now())
        guard let seconds else { return }
        enqueue { service in
            try await service.recordConsumptionActivity(id: entityID, seconds: seconds)
        }
    }

    private func enqueue(
        _ operation: @escaping @Sendable (any EntityConsumptionServicing) async throws -> Void
    ) {
        guard let service else { return }
        let previous = pendingReport
        pendingReport = Task {
            await previous?.value
            try? await operation(service)
        }
    }
}
