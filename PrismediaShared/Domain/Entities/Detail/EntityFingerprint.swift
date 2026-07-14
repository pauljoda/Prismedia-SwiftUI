import Foundation

public struct EntityFingerprint: Decodable, Hashable, Sendable {
    public let algorithm: String
    public let value: String
}
