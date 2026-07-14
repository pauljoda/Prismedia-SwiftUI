import Foundation

public struct EntityPosition: Decodable, Hashable, Sendable {
    public let code: String
    public let value: Int
    public let label: String?

    private enum CodingKeys: String, CodingKey {
        case code, value, label
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        value = try container.decodeFlexibleInt(forKey: .value)
        label = try container.decodeIfPresent(String.self, forKey: .label)
    }
}
