import Foundation

public struct EntityStat: Decodable, Hashable, Sendable {
    public let code: String
    public let value: String

    private enum CodingKeys: String, CodingKey {
        case code, value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        value = try container.decodeFlexibleString(forKey: .value)
    }
}
