import Foundation

/// Pure catalog and ranking rules shared by the search landing and results UI.
public enum SearchHubCatalog {
    private static let artworkKindsByModeID: [String: [EntityKind]] = [
        "overview": [.movie, .videoSeries, .gallery, .audioLibrary, .book],
        "video": [.video, .movie, .videoSeries],
        "images": [.image, .gallery],
        "audio": [.audioLibrary, .musicArtist, .audioTrack],
        "books": [.book, .bookAuthor],
        "browse": [.collection, .person, .studio, .tag],
    ]

    public static let previewKinds: [EntityKind] = [
        .video, .image, .audioLibrary, .book, .collection,
    ]

    private static let parentKindPriority: [EntityKind] = [
        .videoSeries, .movie, .audioLibrary, .musicArtist, .book, .bookAuthor,
        .gallery, .collection, .videoSeason,
    ]

    private static let leafKindPriority: [EntityKind] = [
        .video, .audioTrack, .image, .bookChapter, .bookPage,
    ]

    public static func cards(for modes: [AppMode]) -> [SearchHubModeCard] {
        modes.map(card(for:))
    }

    public static func card(for mode: AppMode) -> SearchHubModeCard {
        SearchHubModeCard(
            mode: mode,
            preferredArtworkKinds: preferredArtworkKinds(for: mode)
        )
    }

    public static func preferredArtworkKinds(for mode: AppMode) -> [EntityKind] {
        artworkKindsByModeID[mode.id] ?? []
    }

    public static func navigationMatches(for query: String) -> [SearchHubNavigationTarget] {
        let candidates = ModeCatalog.all.flatMap { mode in
            mode.destinations.map { SearchHubNavigationTarget(mode: mode, destination: $0) }
        }
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return candidates }

        return rankedResultsWithRanks(
            candidates,
            normalizedQuery: normalizedQuery,
            title: { $0.destination.title }
        )
        .filter { $0.rank < 3 }
        .map(\.element)
    }

    public static func navigationTarget(for entityKind: EntityKind) -> SearchHubNavigationTarget? {
        guard let target = ModeCatalog.canonicalDestination(for: entityKind) else { return nil }
        return SearchHubNavigationTarget(mode: target.mode, destination: target.destination)
    }

    public static func rankedResults<Item>(
        _ results: [Item],
        query: String,
        title: (Item) -> String
    ) -> [Item] {
        let normalizedQuery = normalized(query)
        guard !normalizedQuery.isEmpty else { return results }

        return rankedResultsWithRanks(
            results,
            normalizedQuery: normalizedQuery,
            title: title
        )
        .map(\.element)
    }

    public static func groupedResults(
        _ results: [EntityThumbnail],
        query: String
    ) -> [SearchHubResultSection] {
        let groups = Dictionary(grouping: results, by: \.kind)
        return groups.map { kind, items in
            SearchHubResultSection(
                kind: kind,
                items: rankedResults(items, query: query, title: \.title)
            )
        }
        .sorted { lhs, rhs in
            let lhsPriority = sectionPriority(kind: lhs.kind, items: lhs.items, query: query)
            let rhsPriority = sectionPriority(kind: rhs.kind, items: rhs.items, query: query)
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    public static func sectionTitle(for kind: EntityKind) -> String {
        switch kind {
        case .videoSeason: return "Seasons"
        case .bookChapter: return "Chapters"
        case .bookPage: return "Pages"
        default:
            return ModeCatalog.canonicalDestination(for: kind)?.destination.title ?? kind.displayLabel
        }
    }

    private static func matchRank(for title: String, query: String) -> Int {
        matchRank(
            normalizedTitle: normalized(title),
            normalizedQuery: normalized(query)
        )
    }

    private static func matchRank(normalizedTitle: String, normalizedQuery: String) -> Int {
        if normalizedTitle == normalizedQuery { return 0 }
        if normalizedTitle.hasPrefix(normalizedQuery) { return 1 }
        if normalizedTitle.contains(normalizedQuery) { return 2 }
        return 3
    }

    private static func rankedResultsWithRanks<Item>(
        _ results: [Item],
        normalizedQuery: String,
        title: (Item) -> String
    ) -> [(element: Item, rank: Int)] {
        var decorated: [(offset: Int, element: Item, rank: Int)] = []
        decorated.reserveCapacity(results.count)
        for (offset, element) in results.enumerated() {
            let normalizedTitle = normalized(title(element))
            let rank = matchRank(
                normalizedTitle: normalizedTitle,
                normalizedQuery: normalizedQuery
            )
            decorated.append((offset: offset, element: element, rank: rank))
        }
        decorated.sort { lhs, rhs in
            lhs.rank == rhs.rank ? lhs.offset < rhs.offset : lhs.rank < rhs.rank
        }
        return decorated.map { (element: $0.element, rank: $0.rank) }
    }

    private static func sectionPriority(
        kind: EntityKind,
        items: [EntityThumbnail],
        query: String
    ) -> Int {
        let hasExactLeafMatch =
            leafKindPriority.contains(kind)
            && items.contains { matchRank(for: $0.title, query: query) == 0 }
        if hasExactLeafMatch { return leafKindPriority.firstIndex(of: kind) ?? 0 }
        if let index = parentKindPriority.firstIndex(of: kind) { return 100 + index }
        if let index = leafKindPriority.firstIndex(of: kind) { return 200 + index }
        return 300
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
    }
}
