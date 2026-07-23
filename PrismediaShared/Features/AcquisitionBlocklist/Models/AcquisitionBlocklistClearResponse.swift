import Foundation

public struct AcquisitionBlocklistClearResponse: Decodable, Sendable {
    public let removed: Int

    private enum CodingKeys: String, CodingKey {
        case removed
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        removed = try PrismediaDecoding.integer(from: container, forKey: .removed)
    }
}
