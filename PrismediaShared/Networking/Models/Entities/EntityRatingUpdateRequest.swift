import Foundation

struct EntityRatingUpdateRequest: Encodable {
    let value: Int?

    private enum CodingKeys: String, CodingKey { case value }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let value {
            try container.encode(value, forKey: .value)
        } else {
            try container.encodeNil(forKey: .value)
        }
    }
}
