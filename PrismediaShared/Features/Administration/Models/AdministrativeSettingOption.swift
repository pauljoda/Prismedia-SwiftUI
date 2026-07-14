import Foundation

public struct AdministrativeSettingOption: Decodable, Identifiable, Hashable, Sendable {
    public let value: String
    public let label: String
    public let description: String?
    public var id: String { value }
}
