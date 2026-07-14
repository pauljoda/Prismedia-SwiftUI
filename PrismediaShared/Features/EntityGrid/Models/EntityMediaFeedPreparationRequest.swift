struct EntityMediaFeedPreparationRequest: Hashable, Sendable {
    let items: [EntityThumbnail]
    let requestedCount: Int
}
