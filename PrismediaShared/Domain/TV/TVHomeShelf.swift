import Foundation

public struct TVHomeShelf: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let query: EntityListQuery
    public let limit: Int
    public let destinationTabID: String?

    /// Activity is library-wide on the server. Keep the television activity
    /// shelves scoped to video-family entities.
    public func accepts(_ item: EntityThumbnail) -> Bool {
        guard id == "in-progress" || id == "recently-watched" else { return true }
        return [.movie, .video, .videoSeries, .videoSeason].contains(item.kind)
    }

    public init(
        id: String,
        title: String,
        systemImage: String,
        query: EntityListQuery,
        limit: Int,
        destinationTabID: String? = nil
    ) {
        precondition(limit > 0, "A TV home shelf limit must be positive.")
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.query = query
        self.limit = limit
        self.destinationTabID = destinationTabID
    }
}
