import Foundation

/// One compact readable chapter projected by the server for a Book.
public struct BookContentsEntry: Decodable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let location: String
    public let depth: Int
    public let order: Int
    public let sectionIndex: Int?
    public let startFraction: Double?
    public let endFraction: Double?
    public let pageCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case location
        case depth
        case order
        case sectionIndex
        case startFraction
        case endFraction
        case pageCount
    }

    public init(
        id: String,
        title: String,
        location: String,
        depth: Int,
        order: Int,
        sectionIndex: Int?,
        startFraction: Double?,
        endFraction: Double?,
        pageCount: Int?
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.depth = depth
        self.order = order
        self.sectionIndex = sectionIndex
        self.startFraction = startFraction
        self.endFraction = endFraction
        self.pageCount = pageCount
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        location = try container.decode(String.self, forKey: .location)
        depth = try container.decodeFlexibleInt(forKey: .depth)
        order = try container.decodeFlexibleInt(forKey: .order)
        sectionIndex = try container.decodeFlexibleIntIfPresent(forKey: .sectionIndex)
        startFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .startFraction)
        endFraction = try container.decodeFlexibleDoubleIfPresent(forKey: .endFraction)
        pageCount = try container.decodeFlexibleIntIfPresent(forKey: .pageCount)
    }
}
