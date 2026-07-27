import Foundation

public struct EntityThumbnailOverlayPolicy: Hashable, Sendable {
    public let topLeading: [EntityThumbnailBadgePresentation]
    public let topTrailing: [EntityThumbnailBadgePresentation]
    public let bottomTrailing: [EntityThumbnailBadgePresentation]

    public init(item: EntityThumbnail) {
        topLeading = Self.contextBadge(item).map { [$0] } ?? []

        var topTrailing: [EntityThumbnailBadgePresentation] = []
        if item.isWanted {
            topTrailing.append(Self.wantedBadge(status: item.wantedStatus ?? item.latestAcquisitionStatus))
        }
        if item.isNsfw {
            topTrailing.append(
                EntityThumbnailBadgePresentation(
                    kind: .nsfw,
                    label: nil,
                    systemImage: "flame.fill",
                    tone: .danger
                )
            )
        }
        self.topTrailing = topTrailing

        bottomTrailing =
            item.rating.flatMap { rating in
                guard rating > 0 else { return nil }
                return [
                    EntityThumbnailBadgePresentation(
                        kind: .rating,
                        label: String(rating),
                        systemImage: "star.fill",
                        tone: .accent
                    )
                ]
            } ?? []
    }

    private static func contextBadge(_ item: EntityThumbnail) -> EntityThumbnailBadgePresentation? {
        if let positionBadge = positionBadge(item) {
            return positionBadge
        }
        guard item.thumbnailArtworkPresentation.isWide else { return nil }
        return EntityThumbnailBadgePresentation(
            kind: .position,
            label: item.kind.displayLabel,
            systemImage: item.kind.thumbnailFallbackSystemImage,
            tone: .muted
        )
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
