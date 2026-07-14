import Foundation

public struct AdministrativeImageCandidate: Codable, Hashable, Sendable {
    public let kind: String
    public let url: String
    public let source: String
    public let rank: Decimal?
    public let language: String?
    public let width: Int?
    public let height: Int?
}
