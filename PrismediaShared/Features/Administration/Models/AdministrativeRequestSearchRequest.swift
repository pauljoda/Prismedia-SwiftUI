import Foundation

struct AdministrativeRequestSearchRequest: Encodable, Sendable {
    let kind: String
    let pluginID: String
    let fields: [String: String]
    let limit: Int?

    enum CodingKeys: String, CodingKey {
        case kind
        case pluginID = "pluginId"
        case fields, limit
    }
}
