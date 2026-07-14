import Foundation

public struct EntityImagesCapability: Decodable, Hashable, Sendable {
    public let supportedKinds: [String]
    public let items: [EntityImageAsset]
    public let thumbnailURL: String?
    public let thumbnail2xURL: String?
    public let coverURL: String?

    private enum CodingKeys: String, CodingKey {
        case supportedKinds
        case items
        case thumbnailURL = "thumbnailUrl"
        case thumbnail2xURL = "thumbnail2xUrl"
        case coverURL = "coverUrl"
    }
}
