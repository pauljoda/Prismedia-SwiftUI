import Foundation

extension EntityDetail {
    public func capability<Value>(_ type: Value.Type = Value.self) -> Value? {
        capabilities.lazy.compactMap { capability in
            switch capability {
            case .bookMetadata(let value): value as? Value
            case .classification(let value): value as? Value
            case .collectionConfiguration(let value): value as? Value
            case .coverSelection(let value): value as? Value
            case .credits(let value): value as? Value
            case .dates(let value): value as? Value
            case .description(let value): value as? Value
            case .embeddedAudioMetadata(let value): value as? Value
            case .fileManagement(let value): value as? Value
            case .files(let value): value as? Value
            case .fingerprints(let value): value as? Value
            case .flags(let value): value as? Value
            case .galleryMetadata(let value): value as? Value
            case .images(let value): value as? Value
            case .lifetime(let value): value as? Value
            case .links(let value): value as? Value
            case .markers(let value): value as? Value
            case .playback(let value): value as? Value
            case .personProfile(let value): value as? Value
            case .position(let value): value as? Value
            case .progress(let value): value as? Value
            case .providerIdentity(let value): value as? Value
            case .rating(let value): value as? Value
            case .source(let value): value as? Value
            case .seriesMetadata(let value): value as? Value
            case .stats(let value): value as? Value
            case .subtitles(let value): value as? Value
            case .tagPolicy(let value): value as? Value
            case .technical(let value): value as? Value
            case .unknown(let value): value as? Value
            }
        }.first
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
