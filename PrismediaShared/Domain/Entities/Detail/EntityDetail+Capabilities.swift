import Foundation

extension EntityDetail {
    public func capability<Value>(_ type: Value.Type = Value.self) -> Value? {
        capabilities.lazy.compactMap { $0.payload as? Value }.first
    }

    /// Book reader metadata exposed through the book-specific capability.
    public var bookType: String? {
        capability(EntityBookMetadataCapability.self)?.bookType
    }

    /// Book reader format exposed through the book-specific capability.
    public var bookFormat: BookFormat? {
        capability(EntityBookMetadataCapability.self)?.format
    }

    /// Explicit selected cover entity exposed through the cover-selection capability.
    public var selectedCoverEntityID: UUID? {
        capability(EntityCoverSelectionCapability.self)?.entityID
    }

    /// Relationship credit annotations exposed through the credits capability.
    public var creditMetadata: [EntityCreditMetadata] {
        capability(EntityCreditsCapability.self)?.items ?? []
    }
}
