import Foundation

public struct AdministrativeEntityMetadataFlagsPatch: Codable, Hashable, Sendable {
    public let isFavorite: Bool?
    public let isNsfw: Bool?
    public let isOrganized: Bool?
}
