import Foundation

public struct EntityThumbnailPreviewOption: Hashable, Identifiable, Sendable {
    public let entityID: UUID?
    public let title: String
    public let path: String

    public var id: String {
        "\(entityID?.uuidString ?? "unknown")|\(path)"
    }

    public init(entityID: UUID?, title: String, path: String) {
        self.entityID = entityID
        self.title = title
        self.path = path
    }
}
