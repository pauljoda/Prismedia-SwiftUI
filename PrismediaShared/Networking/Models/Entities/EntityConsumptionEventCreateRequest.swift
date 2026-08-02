import Foundation

struct EntityConsumptionEventCreateRequest: Encodable, Sendable {
    let kind: ConsumptionEventKind
    let occurredAt: Date?
    let positionSeconds: Double?
    let durationSeconds: Double?
    let sessionID: String?

    private enum CodingKeys: String, CodingKey {
        case kind, occurredAt, positionSeconds, durationSeconds
        case sessionID = "sessionId"
    }
}
