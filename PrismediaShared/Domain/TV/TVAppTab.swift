import Foundation

public struct TVAppTab: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String
    public let query: EntityListQuery?

    public init(
        id: String,
        title: String,
        systemImage: String,
        query: EntityListQuery? = nil
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.query = query
    }
}
