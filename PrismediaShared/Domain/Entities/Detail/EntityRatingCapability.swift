import Foundation

public struct EntityRatingCapability: Decodable, Hashable, Sendable {
    public let value: Int?

    private enum CodingKeys: String, CodingKey {
        case value
    }

    public init(from decoder: Decoder) throws {
        value = try decoder.container(keyedBy: CodingKeys.self)
            .decodeFlexibleIntIfPresent(forKey: .value)
    }
}
