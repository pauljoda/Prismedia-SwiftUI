import Foundation

public struct AdministrativeSetting: Decodable, Identifiable, Hashable, Sendable {
    public let key: String
    public let groupKey: String
    public let label: String
    public let description: String
    public let type: String
    public let value: AdministrativeJSONValue
    public let defaultValue: AdministrativeJSONValue
    public let isDefault: Bool
    public let order: Int
    public let constraints: AdministrativeSettingConstraints?
    public let options: [AdministrativeSettingOption]
    public let inputKind: String?
    public let applyHint: String?
    public var id: String { key }

    public var controlKind: AdministrativeSettingControlKind {
        switch type {
        case "boolean": .boolean
        case "integer": .integer
        case "decimal": .decimal
        case "select": .select
        case "string": .text
        case "stringList": .stringList
        default: .unsupported
        }
    }
}
