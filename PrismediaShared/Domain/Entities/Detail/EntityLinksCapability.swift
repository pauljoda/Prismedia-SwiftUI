import Foundation

public struct EntityLinksCapability: Decodable, Hashable, Sendable {
    public let urls: [EntityURLLink]
    public let externalIDs: [EntityExternalID]

    private enum CodingKeys: String, CodingKey {
        case urls
        case externalIDs = "externalIds"
    }
}
