import Foundation

public struct EntityThumbnailOverlayPolicy: Hashable, Sendable {
    public let topLeading: [EntityThumbnailBadgePresentation]
    public let topTrailing: [EntityThumbnailBadgePresentation]
    public let bottomTrailing: [EntityThumbnailBadgePresentation]

    public init(item: EntityThumbnail) {
        topLeading = Self.positionBadge(item).map { [$0] } ?? []

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
        guard let status else { return ("Wanted", "bookmark.fill", .accent) }

        switch status.rawValue {
        case "searching", "pending": return ("Searching", "magnifyingglass", .searching)
        case "awaiting-selection": return ("Review", "magnifyingglass.circle.fill", .attention)
        case "queued": return ("Queued", "hourglass", .queued)
        case "downloading", "downloaded", "importing":
            return ("Downloading", "arrow.down.circle.fill", .downloading)
        case "stopping": return ("Cleaning up", "arrow.triangle.2.circlepath", .cleanup)
        case "imported": return ("Imported", "checkmark.circle.fill", .success)
        case "failed": return ("Failed", "exclamationmark.circle.fill", .failed)
        case "manual-import-required": return ("Action", "exclamationmark.triangle.fill", .attention)
        case "cancelled": return ("Cancelled", "xmark.circle.fill", .muted)
        default: return ("Updating", "arrow.triangle.2.circlepath", .cleanup)
        }
    }
}
