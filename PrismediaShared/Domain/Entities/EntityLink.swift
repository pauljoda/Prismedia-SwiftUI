import Foundation

public struct EntityLink: Hashable, Sendable {
    public let entityID: UUID
    public let kind: EntityKind
    public let parentEntityID: UUID?
    public let parentKind: EntityKind?
    public let intent: EntityNavigationIntent
    public let sourceThumbnail: EntityThumbnail?
    public let thumbnailPreview: EntityLinkPreview?
    public let mediaSequence: EntityMediaSequence?
    public var previewSubtitle: String? { thumbnailPreview?.subtitle }

    public init(
        entityID: UUID,
        kind: EntityKind,
        parentEntityID: UUID? = nil,
        parentKind: EntityKind? = nil,
        intent: EntityNavigationIntent = .detail,
        sourceThumbnail: EntityThumbnail? = nil,
        thumbnailPreview: EntityLinkPreview? = nil,
        mediaSequence: EntityMediaSequence? = nil
    ) {
        self.entityID = entityID
        self.kind = kind
        self.parentEntityID = parentEntityID
        self.parentKind = parentKind
        self.intent = intent
        self.sourceThumbnail = sourceThumbnail
        self.thumbnailPreview = thumbnailPreview
        self.mediaSequence = mediaSequence
    }

    public init(
        thumbnail: EntityThumbnail,
        previewSubtitle: String? = nil,
        intent: EntityNavigationIntent = .detail,
        mediaSequence: EntityMediaSequence? = nil
    ) {
        let canonicalParentKind: EntityKind?
        if thumbnail.kind == .audioTrack, thumbnail.parentEntityID != nil {
            canonicalParentKind = .audioLibrary
        } else if thumbnail.kind == .video, thumbnail.parentKind == .movie {
            canonicalParentKind = .movie
        } else if thumbnail.kind == .video,
            thumbnail.parentKind == .videoSeason,
            intent == .playback
        {
            canonicalParentKind = .videoSeason
        } else {
            canonicalParentKind = nil
        }

        if let canonicalParentKind, let parentID = thumbnail.parentEntityID {
            self.init(
                entityID: parentID,
                kind: canonicalParentKind,
                intent: intent,
                sourceThumbnail: thumbnail,
                thumbnailPreview: EntityLinkPreview(
                    title: thumbnail.title,
                    subtitle: previewSubtitle,
                    artworkPath: thumbnail.bestCoverPath,
                    progress: thumbnail.progress,
                    resumeSeconds: thumbnail.resumeSeconds
                ),
                mediaSequence: mediaSequence
            )
            return
        }

        self.init(
            entityID: thumbnail.id,
            kind: thumbnail.kind,
            parentEntityID: thumbnail.parentEntityID,
            parentKind: thumbnail.parentKind,
            intent: intent,
            sourceThumbnail: thumbnail,
            thumbnailPreview: EntityLinkPreview(
                title: thumbnail.title,
                subtitle: previewSubtitle,
                artworkPath: thumbnail.bestCoverPath,
                progress: thumbnail.progress,
                resumeSeconds: thumbnail.resumeSeconds
            ),
            mediaSequence: mediaSequence
        )
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.entityID == rhs.entityID && lhs.kind == rhs.kind && lhs.parentEntityID == rhs.parentEntityID
            && lhs.parentKind == rhs.parentKind && lhs.intent == rhs.intent
            && lhs.playbackSourceID == rhs.playbackSourceID
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(entityID)
        hasher.combine(kind)
        hasher.combine(parentEntityID)
        hasher.combine(parentKind)
        hasher.combine(intent)
        hasher.combine(playbackSourceID)
    }

    private var playbackSourceID: UUID? {
        intent == .playback ? sourceThumbnail?.id : nil
    }
}
