import Foundation

public struct AdministrativeTranscodeCacheStatus: Decodable, Sendable {
    public let usedBytes: Int64
    public let maxBytes: Int64
}
