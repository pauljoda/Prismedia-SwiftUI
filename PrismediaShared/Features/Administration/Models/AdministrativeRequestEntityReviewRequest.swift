import Foundation

struct AdministrativeRequestEntityReviewRequest: Encodable, Sendable {
    let entityID: UUID
    let kind: String

    enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case kind
    }
}
