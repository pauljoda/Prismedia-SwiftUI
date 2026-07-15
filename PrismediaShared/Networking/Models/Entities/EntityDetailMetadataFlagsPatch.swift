import Foundation

public struct EntityDetailMetadataFlagsPatch: Encodable, Hashable, Sendable {
    public let isFavorite: Bool?
    public let isNsfw: Bool?
    public let isOrganized: Bool?

    public init(
        isFavorite: Bool?,
        isNsfw: Bool?,
        isOrganized: Bool?
    ) {
        self.isFavorite = isFavorite
        self.isNsfw = isNsfw
        self.isOrganized = isOrganized
    }
}
