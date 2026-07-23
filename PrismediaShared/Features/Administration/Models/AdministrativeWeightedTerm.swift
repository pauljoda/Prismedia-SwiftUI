import Foundation

public struct AdministrativeWeightedTerm: Decodable, Hashable, Sendable {
    public let term: String
    public let weight: Int

    private enum CodingKeys: String, CodingKey {
        case term
        case weight
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        term = try container.decode(String.self, forKey: .term)
        weight = try PrismediaDecoding.integer(from: container, forKey: .weight)
    }
}
