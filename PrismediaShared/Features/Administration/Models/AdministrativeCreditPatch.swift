import Foundation

public struct AdministrativeCreditPatch: Codable, Hashable, Sendable {
    public let name: String
    public let role: String
    public let character: String?
    public let sortOrder: Int?
}
