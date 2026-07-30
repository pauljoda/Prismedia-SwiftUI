import Foundation

/// Discriminated capability envelope. Unknown kinds remain available as raw
/// JSON so a newer server does not make the entire detail document unreadable.
public enum EntityCapability: Decodable, Hashable, Sendable {
    case bookMetadata(EntityBookMetadataCapability)
    case classification(EntityClassificationCapability)
    case collectionConfiguration(EntityCollectionConfigurationCapability)
    case coverSelection(EntityCoverSelectionCapability)
    case credits(EntityCreditsCapability)
    case dates(EntityItemsCapability<EntityDate>)
    case description(EntityDescriptionCapability)
    case embeddedAudioMetadata(EntityEmbeddedAudioMetadataCapability)
    case fileManagement(EntityFileManagementCapability)
    case files(EntityItemsCapability<EntityFile>)
    case fingerprints(EntityItemsCapability<EntityFingerprint>)
    case flags(EntityFlagsCapability)
    case galleryMetadata(EntityGalleryMetadataCapability)
    case images(EntityImagesCapability)
    case lifetime(EntityLifetimeCapability)
    case links(EntityLinksCapability)
    case markers(EntityItemsCapability<EntityMarker>)
    case playback(EntityPlaybackCapability)
    case personProfile(EntityPersonProfileCapability)
    case position(EntityItemsCapability<EntityPosition>)
    case progress(EntityProgressCapability)
    case providerIdentity(EntityProviderIdentityCapability)
    case rating(EntityRatingCapability)
    case source(EntityItemsCapability<EntitySource>)
    case seriesMetadata(EntitySeriesMetadataCapability)
    case stats(EntityItemsCapability<EntityStat>)
    case subtitles(EntitySubtitlesCapability)
    case tagPolicy(EntityTagPolicyCapability)
    case technical(EntityTechnicalCapability)
    case unknown(UnknownEntityCapability)

    private struct KindEnvelope: Decodable {
        let kind: EntityCapabilityKind
    }

    public init(from decoder: Decoder) throws {
        let kind = try KindEnvelope(from: decoder).kind

        switch kind {
        case .bookMetadata: self = .bookMetadata(try EntityBookMetadataCapability(from: decoder))
        case .classification: self = .classification(try EntityClassificationCapability(from: decoder))
        case .collectionConfiguration: self = .collectionConfiguration(try EntityCollectionConfigurationCapability(from: decoder))
        case .coverSelection: self = .coverSelection(try EntityCoverSelectionCapability(from: decoder))
        case .credits: self = .credits(try EntityCreditsCapability(from: decoder))
        case .dates: self = .dates(try EntityItemsCapability(from: decoder))
        case .description: self = .description(try EntityDescriptionCapability(from: decoder))
        case .embeddedAudioMetadata: self = .embeddedAudioMetadata(try EntityEmbeddedAudioMetadataCapability(from: decoder))
        case .fileManagement: self = .fileManagement(try EntityFileManagementCapability(from: decoder))
        case .files: self = .files(try EntityItemsCapability(from: decoder))
        case .fingerprints: self = .fingerprints(try EntityItemsCapability(from: decoder))
        case .flags: self = .flags(try EntityFlagsCapability(from: decoder))
        case .galleryMetadata: self = .galleryMetadata(try EntityGalleryMetadataCapability(from: decoder))
        case .images: self = .images(try EntityImagesCapability(from: decoder))
        case .lifetime: self = .lifetime(try EntityLifetimeCapability(from: decoder))
        case .links: self = .links(try EntityLinksCapability(from: decoder))
        case .markers: self = .markers(try EntityItemsCapability(from: decoder))
        case .playback: self = .playback(try EntityPlaybackCapability(from: decoder))
        case .personProfile: self = .personProfile(try EntityPersonProfileCapability(from: decoder))
        case .position: self = .position(try EntityItemsCapability(from: decoder))
        case .progress: self = .progress(try EntityProgressCapability(from: decoder))
        case .providerIdentity: self = .providerIdentity(try EntityProviderIdentityCapability(from: decoder))
        case .rating: self = .rating(try EntityRatingCapability(from: decoder))
        case .source: self = .source(try EntityItemsCapability(from: decoder))
        case .seriesMetadata: self = .seriesMetadata(try EntitySeriesMetadataCapability(from: decoder))
        case .stats: self = .stats(try EntityItemsCapability(from: decoder))
        case .subtitles: self = .subtitles(try EntitySubtitlesCapability(from: decoder))
        case .tagPolicy: self = .tagPolicy(try EntityTagPolicyCapability(from: decoder))
        case .technical: self = .technical(try EntityTechnicalCapability(from: decoder))
        default: self = .unknown(try UnknownEntityCapability(from: decoder))
        }
    }
}

extension EntityDetail {
    func mergingUserMetadata(from response: EntityDetail) -> EntityDetail {
        var mergedCapabilities = capabilities
        for capability in response.capabilities where capability.isUserMetadata {
            if let index = mergedCapabilities.firstIndex(where: { $0.hasSameUserMetadataKind(as: capability) }) {
                mergedCapabilities[index] = capability
            } else {
                mergedCapabilities.append(capability)
            }
        }

        return EntityDetail(
            id: id,
            kind: kind,
            title: title,
            parentEntityID: parentEntityID,
            sortOrder: sortOrder,
            hasSourceMedia: hasSourceMedia,
            capabilities: mergedCapabilities,
            childrenByKind: childrenByKind,
            relationships: relationships
        )
    }
}

extension EntityCapability {
    fileprivate var isUserMetadata: Bool {
        switch self {
        case .flags, .rating: true
        default: false
        }
    }

    fileprivate func hasSameUserMetadataKind(as other: EntityCapability) -> Bool {
        switch (self, other) {
        case (.flags, .flags), (.rating, .rating): true
        default: false
        }
    }
}
