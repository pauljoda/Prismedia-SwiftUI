import Foundation

public struct UnknownEntityCapability: Decodable, Hashable, Sendable {
    public let kind: String
    public let fields: [String: JSONValue]

    public init(from decoder: Decoder) throws {
        let payload = try decoder.singleValueContainer().decode([String: JSONValue].self)
        guard case .string(let kind)? = payload["kind"] else {
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Entity capability kind must be a string."
            )
        }
        self.kind = kind
        fields = payload.filter { $0.key != "kind" }
    }
}
