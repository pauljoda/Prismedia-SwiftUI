import Foundation

public struct AdministrativeJobCount: Decodable, Identifiable, Hashable, Sendable {
    public var id: String { "\(type):\(status)" }
    public let type: String
    public let status: String
    public let count: Int
}
