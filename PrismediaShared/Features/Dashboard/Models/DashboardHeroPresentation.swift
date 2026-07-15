import Foundation

struct DashboardHeroPresentation: Identifiable, Sendable {
    let item: EntityThumbnail
    let thumbnailPath: String?
    let metadataChips: [String]

    var id: UUID { item.id }

    var primaryActionTitle: String {
        (item.resumeSeconds ?? 0) > 0 || (item.progress ?? 0) > 0
            ? "Resume"
            : "Play"
    }

    var playLink: EntityLink {
        EntityLink(thumbnail: item, intent: .playback)
    }

    var detailsLink: EntityLink {
        EntityLink(thumbnail: item, intent: .detail)
    }

    init(item: EntityThumbnail) {
        self.item = item
        thumbnailPath = item.bestCoverPath
        metadataChips = Self.metadataChips(for: item)
    }

    private static func metadataChips(for item: EntityThumbnail) -> [String] {
        let candidates =
            [item.kind.displayLabel]
            + Array(item.genres.prefix(1))
            + item.meta.map(\.label)
        var seen = Set<String>()
        return Array(
            candidates
                .filter { !$0.isEmpty && seen.insert($0).inserted }
                .prefix(3)
        )
    }
}
