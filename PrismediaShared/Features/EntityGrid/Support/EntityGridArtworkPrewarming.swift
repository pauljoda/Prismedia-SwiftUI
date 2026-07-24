import Foundation

public enum EntityGridArtworkPrewarming {
    public static func items(
        after itemID: UUID,
        in items: [EntityThumbnail],
        limit: Int = 8
    ) -> [EntityThumbnail] {
        guard limit > 0, let index = items.firstIndex(where: { $0.id == itemID }) else {
            return []
        }
        return Array(items.dropFirst(index + 1).prefix(limit))
    }

    public static func paths(
        after itemID: UUID,
        in items: [EntityThumbnail],
        limit: Int = 8
    ) -> [String] {
        var seen = Set<String>()
        return
            Self.items(after: itemID, in: items, limit: limit)
            .compactMap(\.bestCoverPath)
            .filter { seen.insert($0).inserted }
            .map { $0 }
    }
}
