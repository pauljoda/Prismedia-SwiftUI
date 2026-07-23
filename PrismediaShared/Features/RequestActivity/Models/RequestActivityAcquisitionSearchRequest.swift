import Foundation

struct RequestActivityAcquisitionSearchRequest: Encodable, Sendable {
    let query: String?

    init(query: String? = nil) {
        self.query = query
    }

    private enum CodingKeys: String, CodingKey {
        case query
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)
    }
}
