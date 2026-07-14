import Foundation

public struct AdministrativeRequestProviderError: Decodable, Identifiable, Hashable, Sendable {
    public let serviceID: UUID
    public let kind: String
    public let displayName: String
    public let message: String
    public var id: UUID { serviceID }

    enum CodingKeys: String, CodingKey {
        case serviceID = "serviceId"
        case kind, displayName, message
    }
}
