import Foundation

/// Optional profile metadata that applies only to people.
public struct EntityPersonProfileCapability: Decodable, Hashable, Sendable {
    public let disambiguation: String?
    public let gender: String?
    public let country: String?
    public let ethnicity: String?
    public let eyeColor: String?
    public let hairColor: String?
    public let height: Int?
    public let weight: Int?
    public let measurements: String?
    public let tattoos: String?
    public let piercings: String?
}
