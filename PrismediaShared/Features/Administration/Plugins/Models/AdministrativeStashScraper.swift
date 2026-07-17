import Foundation

public struct AdministrativeStashScraper: Decodable, Identifiable, Hashable, Sendable {
    public let providerID: String
    public let name: String
    public let version: String
    public var id: String { providerID }

    enum CodingKeys: String, CodingKey {
        case providerID = "providerId"
        case name, version
    }
}
