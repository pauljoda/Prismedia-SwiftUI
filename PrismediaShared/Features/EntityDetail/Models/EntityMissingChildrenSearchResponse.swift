import Foundation

public struct EntityMissingChildrenSearchResponse: Decodable, Equatable, Sendable {
    public let covered: Int
    public let missing: Int

    public init(covered: Int, missing: Int) {
        self.covered = covered
        self.missing = missing
    }

    private enum CodingKeys: String, CodingKey {
        case covered
        case missing
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        covered = try PrismediaDecoding.integer(from: container, forKey: .covered)
        missing = try PrismediaDecoding.integer(from: container, forKey: .missing)
    }
}
