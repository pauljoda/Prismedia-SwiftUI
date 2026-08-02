import Foundation

struct EntityConsumptionUpdateRequest: Encodable, Sendable {
    let positionSeconds: Double?
    let activitySeconds: Double?
    let completed: Bool?
    let utcOffsetMinutes: Int
}
