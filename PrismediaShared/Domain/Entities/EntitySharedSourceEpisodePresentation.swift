import Foundation

/// Shared-file episode display and grouping rules used by every native surface.
enum EntitySharedSourceEpisodePresentation {
    static func coalesced(_ items: [EntityThumbnail]) -> [EntityThumbnail] {
        let itemByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        var emittedGroups = Set<Set<UUID>>()
        var result: [EntityThumbnail] = []

        for item in items {
            let visibleMemberIDs = Set(
                item.sharedSourceEpisodes
                    .map(\.id)
                    .filter { itemByID[$0] != nil }
            )
            guard visibleMemberIDs.count > 1 else {
                result.append(item)
                continue
            }
            guard emittedGroups.insert(visibleMemberIDs).inserted else { continue }

            let representative = item.sharedSourceEpisodes
                .compactMap { itemByID[$0.id] }
                .first ?? item
            result.append(representative)
        }

        return result
    }
}

public extension EntityThumbnail {
    /// Provider titles joined in file playback order when one source carries multiple episodes.
    var displayTitle: String {
        var seen = Set<String>()
        let titles = sharedSourceEpisodes.compactMap { episode -> String? in
            let normalized = episode.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !normalized.isEmpty, seen.insert(normalized).inserted else { return nil }
            return normalized
        }
        return titles.count > 1 ? titles.joined(separator: " + ") : title
    }

    /// Compact `E2 + E3` label for a source that represents multiple provider episodes.
    var sharedEpisodePositionLabel: String? {
        var seen = Set<Int>()
        let numbers = sharedSourceEpisodes
            .compactMap(\.episodeNumber)
            .filter { seen.insert($0).inserted }
        guard numbers.count > 1 else { return nil }
        return numbers.map { "E\($0)" }.joined(separator: " + ")
    }

    /// Whether this visible file card represents the requested provider episode identity.
    func representsEpisode(id episodeID: UUID) -> Bool {
        id == episodeID || sharedSourceEpisodes.contains { $0.id == episodeID }
    }
}
