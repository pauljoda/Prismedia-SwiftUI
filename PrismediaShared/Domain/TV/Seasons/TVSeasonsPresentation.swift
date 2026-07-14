import Foundation

/// Pure hierarchy projection used by the tvOS series and season surfaces.
/// Keeping ordering and selection recovery outside SwiftUI makes focus order
/// deterministic even when the server returns children in a different order.
enum TVSeasonsPresentation {
    static func seasons(in series: EntityDetail) -> [EntityThumbnail] {
        guard series.kind == .videoSeries else { return [] }
        return orderedChildren(of: .videoSeason, in: series)
    }

    static func episodes(in season: EntityDetail) -> [EntityThumbnail] {
        guard season.kind == .videoSeason else { return [] }
        return orderedChildren(of: .video, in: season)
    }

    static func selectedSeasonID(
        preferredID: UUID?,
        seasons: [EntityThumbnail]
    ) -> UUID? {
        if let preferredID, seasons.contains(where: { $0.id == preferredID }) {
            return preferredID
        }
        return seasons.first?.id
    }

    static func adjacentSeasons(
        selectedID: UUID?,
        seasons: [EntityThumbnail]
    ) -> (previous: EntityThumbnail?, next: EntityThumbnail?) {
        guard let selectedID,
            let selectedIndex = seasons.firstIndex(where: { $0.id == selectedID })
        else { return (nil, nil) }

        let previous = selectedIndex > seasons.startIndex ? seasons[selectedIndex - 1] : nil
        let nextIndex = selectedIndex + 1
        let next = nextIndex < seasons.endIndex ? seasons[nextIndex] : nil
        return (previous, next)
    }

    static func routeEpisode(
        from link: EntityLink?,
        episodes: [EntityThumbnail]
    ) -> EntityThumbnail? {
        guard link?.intent == .playback,
            link?.kind == .videoSeason,
            let sourceID = link?.sourceThumbnail?.id
        else { return nil }
        return episodes.first { $0.id == sourceID }
    }

    static func episodeSelection(
        episodeID: UUID,
        intent: TVEpisodeSelectionIntent,
        isDetailCached: Bool
    ) -> TVEpisodeSelectionDecision {
        TVEpisodeSelectionDecision(
            episodeID: episodeID,
            shouldPrewarmDetail: !isDetailCached,
            shouldAutoPlay: intent == .activate
        )
    }

    private static func orderedChildren(
        of kind: EntityKind,
        in detail: EntityDetail
    ) -> [EntityThumbnail] {
        let children = detail.childrenByKind
            .filter { $0.kind == kind }
            .flatMap(\.entities)

        return children.enumerated().sorted { lhs, rhs in
            let lhsOrder = lhs.element.sortOrder ?? Int.max
            let rhsOrder = rhs.element.sortOrder ?? Int.max
            return lhsOrder == rhsOrder ? lhs.offset < rhs.offset : lhsOrder < rhsOrder
        }.map(\.element)
    }
}
