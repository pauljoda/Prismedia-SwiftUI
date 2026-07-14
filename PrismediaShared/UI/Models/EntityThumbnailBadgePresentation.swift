public struct EntityThumbnailBadgePresentation: Hashable, Sendable {
    public let kind: EntityThumbnailBadgeKind
    public let label: String?
    public let systemImage: String?
    public let tone: EntityThumbnailBadgeTone
}
