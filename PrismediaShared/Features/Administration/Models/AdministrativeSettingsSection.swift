import Foundation

public struct AdministrativeSettingsSection: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let systemImageName: String
    public let groups: [AdministrativeSettingsGroup]
    public let includesTranscodeCacheActions: Bool
    public let includesDatabaseBackupActions: Bool
}
