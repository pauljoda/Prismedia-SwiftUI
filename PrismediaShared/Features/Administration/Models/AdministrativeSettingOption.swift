import Foundation

public struct AdministrativeSettingOption: Decodable, Identifiable, Hashable, Sendable {
    public let value: String
    public let label: String
    public let description: String?
    public var id: String { value }

    public init(value: String, label: String, description: String?) {
        self.value = value
        self.label = label
        self.description = description
    }
}
