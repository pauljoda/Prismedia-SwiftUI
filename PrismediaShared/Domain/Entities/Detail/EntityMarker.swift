import Foundation

public struct EntityMarker: Decodable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let seconds: Double
    public let endSeconds: Double?

    private enum CodingKeys: String, CodingKey {
        case id, title, seconds, endSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        seconds = try container.decodeFlexibleDouble(forKey: .seconds)
        endSeconds = try container.decodeFlexibleDoubleIfPresent(forKey: .endSeconds)
    }
}
