import Foundation

struct AdministrativeSettingsSectionDefinition {
    let id: String
    let title: String
    let description: String
    let systemImageName: String
    let groupKeys: [String]
    var includesTranscodeCacheActions = false
    var includesDatabaseBackupActions = false
}
