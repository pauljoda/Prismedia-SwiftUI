import Foundation

struct AdministrativeIdentifyBulkStartRequest: Encodable, Sendable {
    let provider: String?
    let entityIDs: [UUID]
    let query: AdministrativeIdentifyQuery?

    enum CodingKeys: String, CodingKey {
        case provider
        case entityIDs = "entityIds"
        case query
    }
}
