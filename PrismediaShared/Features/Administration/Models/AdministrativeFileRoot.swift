import Foundation

public struct AdministrativeFileRoot: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public let label: String
    public let path: String
    public let enabled: Bool
}
