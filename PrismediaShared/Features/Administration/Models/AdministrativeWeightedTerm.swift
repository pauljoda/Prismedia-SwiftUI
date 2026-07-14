import Foundation

public struct AdministrativeWeightedTerm: Decodable, Hashable, Sendable {
    public let term: String
    public let weight: Int
}
