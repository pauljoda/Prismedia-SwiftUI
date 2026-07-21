import SwiftUI

struct StaticEntityGridLoader: EntityGridLoading {
    let items: [EntityThumbnail]
    let allowsNsfwContent: Bool

    init(
        items: [EntityThumbnail],
        allowsNsfwContent: Bool = false
    ) {
        self.items = items
        self.allowsNsfwContent = allowsNsfwContent
    }

    func load(
        query: EntityListQuery,
        limit: Int,
        search: String?,
        cursor: String?
    ) async throws -> EntityListResponse {
        let matchingItems = sorted(filtered(items, query: query, search: search), query: query)
        let offset = cursor.flatMap(Int.init) ?? 0
        let page = Array(matchingItems.dropFirst(offset).prefix(limit))
        let nextOffset = offset + page.count
        let nextCursor = nextOffset < matchingItems.count ? String(nextOffset) : nil
        return EntityListResponse(
            items: page,
            nextCursor: nextCursor,
            totalCount: matchingItems.count
        )
    }

    private func filtered(
        _ candidates: [EntityThumbnail],
        query: EntityListQuery,
        search: String?
    ) -> [EntityThumbnail] {
        let kinds = query.kind.map { [$0] } ?? query.kinds
        let normalizedSearch = EntityGridSnapshot.normalizedSearch(search ?? "")

        return candidates.filter { item in
            (kinds.isEmpty || kinds.contains(item.kind))
                && normalizedSearch.map(item.title.localizedCaseInsensitiveContains) != false
                && (query.favorite == nil || item.isFavorite == query.favorite)
                && (query.organized == nil || item.isOrganized == query.organized)
                && (query.hasFile == nil || item.hasSourceMedia == query.hasFile)
                && (query.wanted == nil || item.isWanted == query.wanted)
                && (query.nsfw == nil || item.isNsfw == query.nsfw)
                && matchesRating(item, query: query)
                && matchesProgress(item, query: query)
                && matchesTaxonomy(item, query: query)
                && matchesAcquisition(item, query: query)
        }
    }

    private func matchesRating(_ item: EntityThumbnail, query: EntityListQuery) -> Bool {
        if query.unrated == true, item.rating != nil { return false }
        if let minimum = query.ratingMin, (item.rating ?? Int.min) < minimum { return false }
        if let maximum = query.ratingMax, (item.rating ?? Int.max) > maximum { return false }
        return true
    }

    private func matchesProgress(_ item: EntityThumbnail, query: EntityListQuery) -> Bool {
        let hasPlayed = (item.playCount ?? 0) > 0
        if let played = query.played, hasPlayed != played { return false }
        guard let status = query.status else { return true }

        return switch status {
        case "watched": hasPlayed || (item.progress ?? 0) >= 1
        case "unwatched": !hasPlayed && (item.progress ?? 0) == 0
        case "in-progress": (item.progress ?? 0) > 0 && (item.progress ?? 0) < 1
        default: true
        }
    }

    private func matchesTaxonomy(_ item: EntityThumbnail, query: EntityListQuery) -> Bool {
        guard let orphaned = query.orphaned else { return true }
        return (item.parentEntityID == nil) == orphaned
    }

    private func matchesAcquisition(_ item: EntityThumbnail, query: EntityListQuery) -> Bool {
        guard let status = query.acquisitionStatus else { return true }
        return item.latestAcquisitionStatus == status || item.acquisitionStatuses.contains(status)
    }

    private func sorted(
        _ candidates: [EntityThumbnail],
        query: EntityListQuery
    ) -> [EntityThumbnail] {
        guard let sort = query.sort.flatMap(EntityGridSort.init(rawValue:)) else { return candidates }

        let sorted = candidates.sorted { lhs, rhs in
            let order = comparison(lhs, rhs, sort: sort, seed: query.seed)
            if order == .orderedSame {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return order == .orderedAscending
        }
        return query.sortDescending ? Array(sorted.reversed()) : sorted
    }

    private func comparison(
        _ lhs: EntityThumbnail,
        _ rhs: EntityThumbnail,
        sort: EntityGridSort,
        seed: Int?
    ) -> ComparisonResult {
        switch sort {
        case .title:
            lhs.title.localizedStandardCompare(rhs.title)
        case .added:
            compare(lhs.sortOrder ?? Int.max, rhs.sortOrder ?? Int.max)
        case .lastAccessed:
            compare(lhs.createdAt ?? .distantPast, rhs.createdAt ?? .distantPast)
        case .rating:
            compare(lhs.rating ?? -1, rhs.rating ?? -1)
        case .references:
            compare(referenceCount(lhs), referenceCount(rhs))
        case .random:
            compare(randomOrder(lhs, seed: seed), randomOrder(rhs, seed: seed))
        }
    }

    private func referenceCount(_ item: EntityThumbnail) -> Int {
        item.referenceCounts.reduce(0) { $0 + $1.count }
    }

    private func randomOrder(_ item: EntityThumbnail, seed: Int?) -> UInt64 {
        item.id.uuidString.utf8.reduce(UInt64(bitPattern: Int64(seed ?? 0))) {
            ($0 &* 1_099_511_628_211) ^ UInt64($1)
        }
    }

    private func compare<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        if lhs < rhs { return .orderedAscending }
        if lhs > rhs { return .orderedDescending }
        return .orderedSame
    }
}
