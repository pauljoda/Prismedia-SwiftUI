import Foundation

struct AdministrativeRequestReviewRequest: Encodable, Sendable {
    let kind: String
    let pluginID: String
    let externalIdentity: AdministrativeExternalIdentity

    enum CodingKeys: String, CodingKey {
        case kind
        case pluginID = "pluginId"
        case externalIdentity
    }
}
