import Foundation

public struct EntityThumbnailOverlayPolicy: Hashable, Sendable {
    public let topTrailing: [EntityThumbnailBadgePresentation]
    public let bottomLeading: [EntityThumbnailBadgePresentation]
    public let bottomTrailing: [EntityThumbnailBadgePresentation]

    public init(item: EntityThumbnail) {
        var topTrailing: [EntityThumbnailBadgePresentation] = []
        if item.isWanted {
            topTrailing.append(Self.wantedBadge(status: item.wantedStatus ?? item.latestAcquisitionStatus))
        }
        self.topTrailing = topTrailing

        bottomLeading = Self.positionBadge(item).map { [$0] } ?? []

        var bottomTrailing: [EntityThumbnailBadgePresentation] = []
        if item.isNsfw {
            bottomTrailing.append(
                EntityThumbnailBadgePresentation(
                    kind: .nsfw,
                    label: nil,
                    systemImage: "flame.fill",
                    tone: .danger
                )
            )
        }
        if let rating = item.rating, rating > 0 {
            bottomTrailing.append(
                EntityThumbnailBadgePresentation(
                    kind: .rating,
                    label: String(rating),
                    systemImage: "star.fill",
                    tone: .accent
                )
            )
        }
        self.bottomTrailing = bottomTrailing
    }

    private static func positionBadge(_ item: EntityThumbnail) -> EntityThumbnailBadgePresentation? {
        guard let sortOrder = item.sortOrder, sortOrder > 0 else { return nil }
        let prefix: String
        switch (item.kind, item.parentKind) {
        case (.video, .some(.videoSeason)), (.video, .some(.videoSeries)):
            prefix = "E"
        case (.videoSeason, .some(.videoSeries)):
            prefix = "S"
        default: return nil
        }
        return EntityThumbnailBadgePresentation(
            kind: .position,
            label: "\(prefix)\(sortOrder)",
            systemImage: nil,
            tone: .accent
        )
    }

    private static func wantedBadge(status: AcquisitionStatus?) -> EntityThumbnailBadgePresentation {
        let display = acquisitionDisplay(status)
        return EntityThumbnailBadgePresentation(
            kind: .wanted,
            label: display.label,
            systemImage: display.systemImage,
            tone: display.tone
        )
    }

    private static func acquisitionDisplay(
        _ status: AcquisitionStatus?
    ) -> (label: String, systemImage: String, tone: EntityThumbnailBadgeTone) {
        let presentation = AcquisitionStatusPresentationPolicy.compactPresentation(for: status)
        return (
            presentation.label,
            presentation.systemImage,
            thumbnailTone(for: presentation.tone)
        )
    }

    private static func thumbnailTone(
        for tone: AcquisitionStatusPresentationTone
    ) -> EntityThumbnailBadgeTone {
        switch tone {
        case .downloading: .downloading
        case .searching: .searching
        case .queued: .queued
        case .cleanup: .cleanup
        case .attention: .attention
        case .failed: .failed
        case .done: .success
        case .muted, .wanted: .muted
        }
    }
}
