import Foundation

/// One resource entry in an Entity reader manifest.
public struct EntityReaderManifestPage: Decodable, Hashable, Sendable {
    public let ordinal: Int
    public let mimeType: String
    public let width: Int?
    public let height: Int?
    public let pageType: PageType
    public let isDoublePage: Bool
    public let checksum: String?

    public init(
        ordinal: Int,
        mimeType: String,
        width: Int? = nil,
        height: Int? = nil,
        pageType: PageType = .story,
        isDoublePage: Bool = false,
        checksum: String? = nil
    ) {
        self.ordinal = ordinal
        self.mimeType = mimeType
        self.width = width
        self.height = height
        self.pageType = pageType
        self.isDoublePage = isDoublePage
        self.checksum = checksum
    }

    private enum CodingKeys: String, CodingKey {
        case ordinal
        case mimeType
        case width
        case height
        case pageType
        case isDoublePage
        case checksum
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ordinal = try container.decodeFlexibleInt(forKey: .ordinal)
        mimeType = try container.decode(String.self, forKey: .mimeType)
        width = try container.decodeFlexibleIntIfPresent(forKey: .width)
        height = try container.decodeFlexibleIntIfPresent(forKey: .height)
        pageType = try container.decode(PageType.self, forKey: .pageType)
        isDoublePage = try container.decode(Bool.self, forKey: .isDoublePage)
        checksum = try container.decodeIfPresent(String.self, forKey: .checksum)
    }
}
