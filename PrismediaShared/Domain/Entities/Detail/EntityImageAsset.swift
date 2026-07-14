import Foundation

public struct EntityImageAsset: Decodable, Hashable, Sendable {
    public let kind: String
    public let path: String
    public let mimeType: String?
}
