import Foundation

public struct EntityThumbnail: Identifiable, Decodable, Hashable, Sendable {
    public let id: UUID
    public let kind: EntityKind
    public let title: String
    public let summary: String?
    public let parentEntityID: UUID?
    public let parentKind: EntityKind?
    public let sortOrder: Int?
    public let coverURL: String?
    public let coverThumbURL: String?
    public let coverThumb2xURL: String?
    public let hoverKind: EntityThumbnailHoverKind
    public let hoverURL: String?
    public let hoverImages: [EntityThumbnailHoverImage]
    public let meta: [EntityThumbnailMeta]
    public let rating: Int?
    public let isFavorite: Bool
    public let isNsfw: Bool
    public let isOrganized: Bool
    public let isWanted: Bool
    public let hasSourceMedia: Bool
    public let latestAcquisitionStatus: AcquisitionStatus?
    public let acquisitionStatuses: [AcquisitionStatus]
    public let wantedStatus: AcquisitionStatus?
    public let progress: Double?
    public let resumeSeconds: Double?
    public let playCount: Int?
    public let genres: [String]
    public let referenceCounts: [EntityKindCount]

    public var bestCoverPath: String? {
        coverThumb2xURL ?? coverThumbURL ?? coverURL
    }

    /// Hero artwork must remain an image. `hoverURL` is a preview descriptor
    /// such as an M3U8 or VTT playlist and must never enter an image pipeline.
    public var bestHeroPath: String? {
        hoverImages.first?.path ?? bestCoverPath
    }

    public var trickplayPlaylistPath: String? {
        guard hoverKind == .sprite || hoverKind == .trickplay,
            let hoverURL,
            !hoverURL.isEmpty
        else { return nil }
        return hoverURL
    }

    /// Movie playback can be represented by its owned video entity. Present
    /// that playable child with movie poster geometry everywhere a thumbnail
    /// is rendered, while standalone and episodic videos remain landscape.
    public var thumbnailPresentationKind: EntityKind {
        kind == .video && parentKind == .movie ? .movie : kind
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case summary
        case description
        case overview
        case parentEntityID = "parentEntityId"
        case parentKind
        case sortOrder
        case coverURL = "coverUrl"
        case coverThumbURL = "coverThumbUrl"
        case coverThumb2xURL = "coverThumb2xUrl"
        case hoverKind
        case hoverURL = "hoverUrl"
        case hoverImages
        case meta
        case rating
        case isFavorite
        case isNsfw
        case isOrganized
        case isWanted
        case hasSourceMedia
        case latestAcquisitionStatus
        case acquisitionStatuses
        case wantedStatus
        case progress
        case resumeSeconds
        case playCount
        case genres
        case referenceCounts
    }

    public init(
        id: UUID,
        kind: EntityKind,
        title: String,
        summary: String? = nil,
        parentEntityID: UUID? = nil,
        parentKind: EntityKind? = nil,
        sortOrder: Int? = nil,
        coverURL: String? = nil,
        coverThumbURL: String? = nil,
        coverThumb2xURL: String? = nil,
        hoverKind: EntityThumbnailHoverKind = .none,
        hoverURL: String? = nil,
        hoverImages: [EntityThumbnailHoverImage] = [],
        meta: [EntityThumbnailMeta] = [],
        rating: Int? = nil,
        isFavorite: Bool = false,
        isNsfw: Bool = false,
        isOrganized: Bool = false,
        isWanted: Bool = false,
        hasSourceMedia: Bool = false,
        latestAcquisitionStatus: AcquisitionStatus? = nil,
        acquisitionStatuses: [AcquisitionStatus] = [],
        wantedStatus: AcquisitionStatus? = nil,
        progress: Double? = nil,
        resumeSeconds: Double? = nil,
        playCount: Int? = nil,
        genres: [String] = [],
        referenceCounts: [EntityKindCount] = []
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.summary = summary
        self.parentEntityID = parentEntityID
        self.parentKind = parentKind
        self.sortOrder = sortOrder
        self.coverURL = coverURL
        self.coverThumbURL = coverThumbURL
        self.coverThumb2xURL = coverThumb2xURL
        self.hoverKind = hoverKind
        self.hoverURL = hoverURL
        self.hoverImages = hoverImages
        self.meta = meta
        self.rating = rating
        self.isFavorite = isFavorite
        self.isNsfw = isNsfw
        self.isOrganized = isOrganized
        self.isWanted = isWanted
        self.hasSourceMedia = hasSourceMedia
        self.latestAcquisitionStatus = latestAcquisitionStatus
        self.acquisitionStatuses = acquisitionStatuses
        self.wantedStatus = wantedStatus
        self.progress = progress
        self.resumeSeconds = resumeSeconds
        self.playCount = playCount
        self.genres = genres
        self.referenceCounts = referenceCounts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(EntityKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        summary =
            try container.decodeIfPresent(String.self, forKey: .summary)
            ?? container.decodeIfPresent(String.self, forKey: .description)
            ?? container.decodeIfPresent(String.self, forKey: .overview)
        parentEntityID = try container.decodeIfPresent(UUID.self, forKey: .parentEntityID)
        parentKind = try container.decodeIfPresent(EntityKind.self, forKey: .parentKind)
        sortOrder = try container.decodeFlexibleIntIfPresent(forKey: .sortOrder)
        coverURL = try container.decodeIfPresent(String.self, forKey: .coverURL)
        coverThumbURL = try container.decodeIfPresent(String.self, forKey: .coverThumbURL)
        coverThumb2xURL = try container.decodeIfPresent(String.self, forKey: .coverThumb2xURL)
        hoverKind =
            try container.decodeIfPresent(EntityThumbnailHoverKind.self, forKey: .hoverKind)
            ?? .none
        hoverURL = try container.decodeIfPresent(String.self, forKey: .hoverURL)
        hoverImages = try container.decodeIfPresent([EntityThumbnailHoverImage].self, forKey: .hoverImages) ?? []
        meta = try container.decodeIfPresent([EntityThumbnailMeta].self, forKey: .meta) ?? []
        rating = try container.decodeFlexibleIntIfPresent(forKey: .rating)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isNsfw = try container.decodeIfPresent(Bool.self, forKey: .isNsfw) ?? false
        isOrganized = try container.decodeIfPresent(Bool.self, forKey: .isOrganized) ?? false
        isWanted = try container.decodeIfPresent(Bool.self, forKey: .isWanted) ?? false
        hasSourceMedia = try container.decodeIfPresent(Bool.self, forKey: .hasSourceMedia) ?? false
        latestAcquisitionStatus = try container.decodeIfPresent(
            AcquisitionStatus.self, forKey: .latestAcquisitionStatus)
        acquisitionStatuses =
            try container.decodeIfPresent([AcquisitionStatus].self, forKey: .acquisitionStatuses) ?? []
        wantedStatus = try container.decodeIfPresent(AcquisitionStatus.self, forKey: .wantedStatus)
        progress = try container.decodeFlexibleDoubleIfPresent(forKey: .progress)
        resumeSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .resumeSeconds)
        playCount = try container.decodeFlexibleIntIfPresent(forKey: .playCount)
        genres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        referenceCounts = try container.decodeIfPresent([EntityKindCount].self, forKey: .referenceCounts) ?? []
    }
}
