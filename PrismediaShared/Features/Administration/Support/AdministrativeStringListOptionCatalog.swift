import Foundation

enum AdministrativeStringListOptionCatalog {
    static func options(
        for setting: AdministrativeSetting,
        plugins: [AdministrativePlugin]
    ) -> [AdministrativeSettingOption] {
        if !setting.options.isEmpty { return setting.options }

        switch setting.key {
        case "autoIdentify.entityKinds":
            return entityKindOptions
        case "autoIdentify.providers":
            return pluginOptions(from: plugins)
        default:
            return []
        }
    }

    private static let entityKindOptions = [
        AdministrativeSettingOption(value: "movie", label: "Movies", description: nil),
        AdministrativeSettingOption(value: "video", label: "Videos", description: nil),
        AdministrativeSettingOption(value: "gallery", label: "Galleries", description: nil),
        AdministrativeSettingOption(value: "image", label: "Images", description: nil),
        AdministrativeSettingOption(value: "audio", label: "Audio", description: nil),
        AdministrativeSettingOption(value: "book", label: "Books", description: nil),
    ]

    private static func pluginOptions(from plugins: [AdministrativePlugin]) -> [AdministrativeSettingOption] {
        plugins
            .filter { $0.installed && $0.enabled }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { plugin in
                let kinds = Array(Set(plugin.supports.map(\.entityKind)))
                    .sorted()
                    .joined(separator: ", ")
                return AdministrativeSettingOption(
                    value: plugin.id,
                    label: plugin.name,
                    description: kinds.isEmpty ? "Version \(plugin.version)" : "Supports \(kinds)"
                )
            }
    }
}
