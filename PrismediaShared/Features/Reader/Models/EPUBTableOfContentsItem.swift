import Foundation

public struct EPUBTableOfContentsItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let location: String?
    public let children: [EPUBTableOfContentsItem]

    public var outlineChildren: [Self]? {
        children.isEmpty ? nil : children
    }

    public init(
        id: UUID = UUID(),
        title: String,
        location: String?,
        children: [EPUBTableOfContentsItem] = []
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.children = children
    }
}
