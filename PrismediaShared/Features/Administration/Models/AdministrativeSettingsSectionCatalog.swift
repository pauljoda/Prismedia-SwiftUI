import Foundation

public enum AdministrativeSettingsSectionCatalog {
    public static func sections(for catalog: AdministrativeSettingsCatalog) -> [AdministrativeSettingsSection] {
        let groupsByKey = Dictionary(uniqueKeysWithValues: catalog.groups.map { ($0.key, $0) })
        let claimedKeys = Set(definitions.flatMap(\.groupKeys))
        let unmatched = catalog.groups
            .filter { !claimedKeys.contains($0.key) }
            .sorted { $0.order < $1.order }
            .map { group in
                AdministrativeSettingsSection(
                    id: group.key,
                    title: group.label,
                    description: group.description,
                    systemImageName: "gearshape",
                    groups: [group],
                    includesTranscodeCacheActions: false,
                    includesDatabaseBackupActions: false
                )
            }
        let known = definitions.compactMap { definition -> AdministrativeSettingsSection? in
            let groups = definition.groupKeys.compactMap { groupsByKey[$0] }
            guard
                !groups.isEmpty || definition.includesTranscodeCacheActions || definition.includesDatabaseBackupActions
            else { return nil }
            return AdministrativeSettingsSection(
                id: definition.id,
                title: definition.title,
                description: definition.description,
                systemImageName: definition.systemImageName,
                groups: groups,
                includesTranscodeCacheActions: definition.includesTranscodeCacheActions,
                includesDatabaseBackupActions: definition.includesDatabaseBackupActions
            )
        }
        return unmatched + known
    }

    private static let definitions: [AdministrativeSettingsSectionDefinition] = [
        AdministrativeSettingsSectionDefinition(
            id: "acquisition",
            title: "Acquisition",
            description: "Configure monitoring, request, and download behavior.",
            systemImageName: "paperplane",
            groupKeys: ["monitoring", "requests"]
        ),
        AdministrativeSettingsSectionDefinition(
            id: "playback",
            title: "Playback",
            description: "Set player defaults and HLS behavior for video playback.",
            systemImageName: "film",
            groupKeys: ["playback", "hls"]
        ),
        AdministrativeSettingsSectionDefinition(
            id: "subtitles",
            title: "Subtitles",
            description: "Tune caption behavior, style, scale, opacity, and screen position.",
            systemImageName: "captions.bubble",
            groupKeys: ["subtitles"]
        ),
        AdministrativeSettingsSectionDefinition(
            id: "generation",
            title: "Generation Pipeline",
            description: "Control scan cadence, collections, taxonomy, previews, and background jobs.",
            systemImageName: "waveform.path.ecg",
            groupKeys: ["scan", "collections", "taxonomy", "generation", "jobs"]
        ),
        AdministrativeSettingsSectionDefinition(
            id: "auto-identify",
            title: "Auto Identify",
            description: "Choose trusted plugins and matching rules for scan-time identification.",
            systemImageName: "sparkles",
            groupKeys: ["autoIdentify"]
        ),
        AdministrativeSettingsSectionDefinition(
            id: "transcode-cache",
            title: "Transcode Cache",
            description: "Review prepared video cache usage and set the cache size limit.",
            systemImageName: "externaldrive",
            groupKeys: ["transcodeCache"],
            includesTranscodeCacheActions: true
        ),
    ]

}
