import Foundation

public struct AdministrativePluginAuthField: Decodable, Identifiable, Hashable, Sendable {
    public let key: String
    public let label: String
    public let required: Bool
    public let url: String?
    public var id: String { key }
}
