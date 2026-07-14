import Foundation

enum VideoPlaybackSequence {
    static func nextEpisode(after videoID: UUID, in group: EntityGroup) -> EntityThumbnail? {
        guard group.kind == .video else { return nil }

        let episodes = group.entities.enumerated().sorted { lhs, rhs in
            let lhsOrder = lhs.element.sortOrder ?? Int.max
            let rhsOrder = rhs.element.sortOrder ?? Int.max
            return lhsOrder == rhsOrder ? lhs.offset < rhs.offset : lhsOrder < rhsOrder
        }.map(\.element)

        guard let currentIndex = episodes.firstIndex(where: { $0.id == videoID }) else { return nil }
        let nextIndex = episodes.index(after: currentIndex)
        guard episodes.indices.contains(nextIndex) else { return nil }
        return episodes[nextIndex]
    }
}
