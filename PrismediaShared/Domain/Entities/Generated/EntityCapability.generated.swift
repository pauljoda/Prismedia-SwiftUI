// AUTO-GENERATED from Prismedia's backend capability manifest.
// Do not edit by hand. Run `python3 Scripts/generate-entity-capabilities.py`.

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
    case personProfile(EntityPersonProfileCapability)
    case playableVideo(EntityPlayableVideoCapability)
    case playback(EntityPlaybackCapability)
    case position(EntityItemsCapability<EntityPosition>)
    case progress(EntityProgressCapability)
    case providerIdentity(EntityProviderIdentityCapability)
    case rating(EntityRatingCapability)
    case seriesMetadata(EntitySeriesMetadataCapability)
    case source(EntityItemsCapability<EntitySource>)
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
        case .dates: self = .dates(try EntityItemsCapability<EntityDate>(from: decoder))
        case .description: self = .description(try EntityDescriptionCapability(from: decoder))
        case .embeddedAudioMetadata: self = .embeddedAudioMetadata(try EntityEmbeddedAudioMetadataCapability(from: decoder))
        case .fileManagement: self = .fileManagement(try EntityFileManagementCapability(from: decoder))
        case .files: self = .files(try EntityItemsCapability<EntityFile>(from: decoder))
        case .fingerprints: self = .fingerprints(try EntityItemsCapability<EntityFingerprint>(from: decoder))
        case .flags: self = .flags(try EntityFlagsCapability(from: decoder))
        case .galleryMetadata: self = .galleryMetadata(try EntityGalleryMetadataCapability(from: decoder))
        case .images: self = .images(try EntityImagesCapability(from: decoder))
        case .lifetime: self = .lifetime(try EntityLifetimeCapability(from: decoder))
        case .links: self = .links(try EntityLinksCapability(from: decoder))
        case .markers: self = .markers(try EntityItemsCapability<EntityMarker>(from: decoder))
        case .personProfile: self = .personProfile(try EntityPersonProfileCapability(from: decoder))
        case .playableVideo: self = .playableVideo(try EntityPlayableVideoCapability(from: decoder))
        case .playback: self = .playback(try EntityPlaybackCapability(from: decoder))
        case .position: self = .position(try EntityItemsCapability<EntityPosition>(from: decoder))
        case .progress: self = .progress(try EntityProgressCapability(from: decoder))
        case .providerIdentity: self = .providerIdentity(try EntityProviderIdentityCapability(from: decoder))
        case .rating: self = .rating(try EntityRatingCapability(from: decoder))
        case .seriesMetadata: self = .seriesMetadata(try EntitySeriesMetadataCapability(from: decoder))
        case .source: self = .source(try EntityItemsCapability<EntitySource>(from: decoder))
        case .stats: self = .stats(try EntityItemsCapability<EntityStat>(from: decoder))
        case .subtitles: self = .subtitles(try EntitySubtitlesCapability(from: decoder))
        case .tagPolicy: self = .tagPolicy(try EntityTagPolicyCapability(from: decoder))
        case .technical: self = .technical(try EntityTechnicalCapability(from: decoder))
        default: self = .unknown(try UnknownEntityCapability(from: decoder))
        }
    }

    /// Manifest-backed discriminator for matching and mutation ownership.
    public var kind: EntityCapabilityKind {
        switch self {
        case .bookMetadata: .bookMetadata
        case .classification: .classification
        case .collectionConfiguration: .collectionConfiguration
        case .coverSelection: .coverSelection
        case .credits: .credits
        case .dates: .dates
        case .description: .description
        case .embeddedAudioMetadata: .embeddedAudioMetadata
        case .fileManagement: .fileManagement
        case .files: .files
        case .fingerprints: .fingerprints
        case .flags: .flags
        case .galleryMetadata: .galleryMetadata
        case .images: .images
        case .lifetime: .lifetime
        case .links: .links
        case .markers: .markers
        case .personProfile: .personProfile
        case .playableVideo: .playableVideo
        case .playback: .playback
        case .position: .position
        case .progress: .progress
        case .providerIdentity: .providerIdentity
        case .rating: .rating
        case .seriesMetadata: .seriesMetadata
        case .source: .source
        case .stats: .stats
        case .subtitles: .subtitles
        case .tagPolicy: .tagPolicy
        case .technical: .technical
        case .unknown(let value): EntityCapabilityKind(rawValue: value.kind)
        }
    }

    /// Concrete payload used by EntityDetail's generic typed accessor.
    public var payload: Any {
        switch self {
        case .bookMetadata(let value): value
        case .classification(let value): value
        case .collectionConfiguration(let value): value
        case .coverSelection(let value): value
        case .credits(let value): value
        case .dates(let value): value
        case .description(let value): value
        case .embeddedAudioMetadata(let value): value
        case .fileManagement(let value): value
        case .files(let value): value
        case .fingerprints(let value): value
        case .flags(let value): value
        case .galleryMetadata(let value): value
        case .images(let value): value
        case .lifetime(let value): value
        case .links(let value): value
        case .markers(let value): value
        case .personProfile(let value): value
        case .playableVideo(let value): value
        case .playback(let value): value
        case .position(let value): value
        case .progress(let value): value
        case .providerIdentity(let value): value
        case .rating(let value): value
        case .seriesMetadata(let value): value
        case .source(let value): value
        case .stats(let value): value
        case .subtitles(let value): value
        case .tagPolicy(let value): value
        case .technical(let value): value
        case .unknown(let value): value
        }
    }
}
