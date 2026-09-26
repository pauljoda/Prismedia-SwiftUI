import Foundation

/// Backend-owned ebook or audiobook scope, preserving unknown future rendition codes.
public struct EntityBookRendition: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public extension EntityBookRendition {
    static let ebook = Self(rawValue: PrismediaContractCodes.BookRendition.ebook)
    static let audiobook = Self(rawValue: PrismediaContractCodes.BookRendition.audiobook)
}
