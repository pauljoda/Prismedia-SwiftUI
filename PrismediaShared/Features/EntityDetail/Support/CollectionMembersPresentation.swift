import Foundation

/// Shared collection presentation contract for every Apple platform. The API
/// owns membership ordering, so presentation must neither sort nor filter it.
enum CollectionMembersPresentation {
    static func members(from items: [EntityThumbnail]) -> [EntityThumbnail] {
        items
    }

    static func group(from members: [EntityThumbnail]) -> EntityGroup? {
        guard !members.isEmpty else { return nil }
        return EntityGroup(
            kind: .collection,
            label: "Items",
            entities: members,
            code: "collection-members"
        )
    }
}
