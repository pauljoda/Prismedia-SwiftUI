import Foundation

public struct AdministrativePluginSearchField: Decodable, Identifiable, Hashable, Sendable {
    public let key: String
    public let label: String
    public let type: String
    public let required: Bool
    public let placeholder: String?
    public let help: String?
    public var id: String { key }
}
