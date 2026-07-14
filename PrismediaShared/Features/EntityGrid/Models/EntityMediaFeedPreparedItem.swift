import Foundation

struct EntityMediaFeedPreparedItem: Identifiable, Hashable, Sendable {
    let item: EntityThumbnail
    let projection: EntityImageMediaProjection?
    let aspectRatio: Double

    var id: UUID { item.id }
}
