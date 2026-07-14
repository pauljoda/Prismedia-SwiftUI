import Foundation

public struct AdministrativeSettingsCatalog: Decodable, Sendable {
    public let groups: [AdministrativeSettingsGroup]
}
