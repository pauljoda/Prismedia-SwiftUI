import Foundation

public struct EntityExternalID: Decodable, Hashable, Sendable {
    public let provider: String
    public let value: String
    public let url: String?
}
