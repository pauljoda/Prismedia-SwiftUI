import Foundation

/// Narrow client boundary for recording medium-neutral access and active-time consumption.
public protocol EntityConsumptionServicing: Sendable {
    /// Records one explicit open/view session for an Entity.
    func recordConsumptionAccess(id: UUID, sessionID: String) async throws

    /// Adds one bounded active-time heartbeat to an Entity and its local-day bucket.
    func recordConsumptionActivity(id: UUID, seconds: Double) async throws
}

extension PrismediaAPIClient: EntityConsumptionServicing {
    public func recordConsumptionAccess(id: UUID, sessionID: String) async throws {
        try await recordEntityConsumptionEvent(
            id: id,
            kind: .accessed,
            positionSeconds: nil,
            durationSeconds: nil,
            sessionID: sessionID
        )
    }

    public func recordConsumptionActivity(id: UUID, seconds: Double) async throws {
        try await updateEntityConsumption(
            id: id,
            positionSeconds: nil,
            activitySeconds: seconds,
            completed: nil
        )
    }
}
