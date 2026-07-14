import Foundation

public struct EntityGridPreset: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let preferences: EntityGridPreferences

    public init(
        id: UUID = UUID(),
        name: String,
        preferences: EntityGridPreferences
    ) {
        self.id = id
        self.name = name
        self.preferences = preferences
    }
}
