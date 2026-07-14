import Foundation

public enum EntityGridArtworkPrewarming {
    public static func paths(
        after itemID: UUID,
        in items: [EntityThumbnail],
        limit: Int = 8
    ) -> [String] {
        guard limit > 0, let index = items.firstIndex(where: { $0.id == itemID }) else {
            return []
        }

        var seen = Set<String>()
        return
            items
            .dropFirst(index + 1)
            .compactMap(\.bestCoverPath)
            .filter { seen.insert($0).inserted }
            .prefix(limit)
            .map { $0 }
    }
}
