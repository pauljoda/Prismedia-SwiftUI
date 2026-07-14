import Foundation

public struct AdministrativeSettingsGroup: Decodable, Identifiable, Hashable, Sendable {
    public let key: String
    public let label: String
    public let description: String
    public let order: Int
    public let settings: [AdministrativeSetting]
    public var id: String { key }
}
