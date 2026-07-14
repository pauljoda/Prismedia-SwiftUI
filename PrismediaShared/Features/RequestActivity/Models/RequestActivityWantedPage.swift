import Foundation

public struct RequestActivityWantedPage: Decodable, Equatable, Sendable {
    public let items: [RequestActivityWantedItem]
    public let total: Int

    private enum CodingKeys: String, CodingKey {
        case items
        case total
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([RequestActivityWantedItem].self, forKey: .items)
        total = try RequestActivityDecoding.integer(from: container, forKey: .total)
    }
}
