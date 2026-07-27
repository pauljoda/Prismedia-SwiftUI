import Foundation

public struct AdministrativeWeightedTerm: Codable, Hashable, Sendable {
    public let term: String
    public let weight: Int

    private enum CodingKeys: String, CodingKey {
        case term
        case weight
    }

    public init(term: String, weight: Int) {
        self.term = term
        self.weight = weight
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        term = try container.decode(String.self, forKey: .term)
        weight = try PrismediaDecoding.integer(from: container, forKey: .weight)
    }
}
