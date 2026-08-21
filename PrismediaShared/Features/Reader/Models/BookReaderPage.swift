import Foundation

/// One reader page whose bytes may come from a legacy page Entity or an ordinal manifest resource.
public struct BookReaderPage: Identifiable, Hashable, Sendable {
    public enum Source: Hashable, Sendable {
        case entity(UUID)
        case manifest(entityID: UUID, ordinal: Int)
    }

    public let id: UUID
    public let title: String
    public let source: Source
    public let isDoublePage: Bool

    public init(
        id: UUID,
        title: String,
        source: Source,
        isDoublePage: Bool
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.isDoublePage = isDoublePage
    }

    public init(thumbnail: EntityThumbnail) {
        id = thumbnail.id
        title = thumbnail.title
        source = .entity(thumbnail.id)
        isDoublePage = false
    }

    public init(entityID: UUID, page: EntityReaderManifestPage) {
        id = Self.manifestPageID(entityID: entityID, ordinal: page.ordinal)
        title = "Page \(page.ordinal + 1)"
        source = .manifest(entityID: entityID, ordinal: page.ordinal)
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
