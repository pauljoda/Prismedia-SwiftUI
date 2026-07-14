import Foundation

struct AdministrativeIdentifyEntityRequest: Encodable, Sendable {
    let provider: String
    let query: AdministrativeIdentifyQuery?
    let parentExternalIDs: [String: String]?

    enum CodingKeys: String, CodingKey {
        case provider, query
        case parentExternalIDs = "parentExternalIds"
    }
}
