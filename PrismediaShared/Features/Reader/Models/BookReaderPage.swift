import Foundation

/// One ordinal page resource in an Entity reader manifest. A page is never an Entity.
public struct BookReaderPage: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let title: String
    public let entityID: UUID
    public let ordinal: Int
    public let pageType: PageType
    public let isDoublePage: Bool

    public init(
        id: UUID,
        title: String,
        entityID: UUID,
        ordinal: Int,
        pageType: PageType = .story,
        isDoublePage: Bool
    ) {
        self.id = id
        self.title = title
        self.entityID = entityID
        self.ordinal = ordinal
        self.pageType = pageType
        self.isDoublePage = isDoublePage
    }

    public init(entityID: UUID, page: EntityReaderManifestPage) {
        id = Self.manifestPageID(entityID: entityID, ordinal: page.ordinal)
        title = "Page \(page.ordinal + 1)"
        self.entityID = entityID
        ordinal = page.ordinal
        pageType = page.pageType
        isDoublePage = page.isDoublePage
    }

    private static func manifestPageID(entityID: UUID, ordinal: Int) -> UUID {
        var bytes = entityID.uuid
        bytes.0 ^= 0x80
        let value = UInt32(clamping: ordinal)
        bytes.12 ^= UInt8(truncatingIfNeeded: value >> 24)
        bytes.13 ^= UInt8(truncatingIfNeeded: value >> 16)
        bytes.14 ^= UInt8(truncatingIfNeeded: value >> 8)
        bytes.15 ^= UInt8(truncatingIfNeeded: value)
        return UUID(uuid: bytes)
    }
}
