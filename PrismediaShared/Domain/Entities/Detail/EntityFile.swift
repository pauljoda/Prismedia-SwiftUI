import Foundation

public struct EntityFile: Decodable, Hashable, Sendable {
    public let role: String
    public let path: String
    public let mimeType: String?
}
