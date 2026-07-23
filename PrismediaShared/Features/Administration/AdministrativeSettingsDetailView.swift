import SwiftUI

struct AdministrativeSettingsDetailView: View {
    @State private var section: AdministrativeSettingsSection
    @State private var cacheStatus: AdministrativeTranscodeCacheStatus?
    @State private var isPerformingAction = false
    let plugins: [AdministrativePlugin]
    let hidesNsfw: Bool
    let blocklistService: (any AcquisitionBlocklistServicing)?
    let onSave: (AdministrativeSetting, AdministrativeJSONValue) async -> AdministrativeSettingsSection?
    let onClearCache: () async -> AdministrativeTranscodeCacheStatus?
    let onCreateBackup: () async -> Bool

    init(
        section: AdministrativeSettingsSection,
        cacheStatus: AdministrativeTranscodeCacheStatus?,
        plugins: [AdministrativePlugin] = [],
        hidesNsfw: Bool = true,
        blocklistService: (any AcquisitionBlocklistServicing)? = nil,
        onSave: @escaping (AdministrativeSetting, AdministrativeJSONValue) async -> AdministrativeSettingsSection?,
        onClearCache: @escaping () async -> AdministrativeTranscodeCacheStatus?,
        onCreateBackup: @escaping () async -> Bool
    ) {
        _section = State(initialValue: section)
        _cacheStatus = State(initialValue: cacheStatus)
        self.plugins = plugins
        self.hidesNsfw = hidesNsfw
        self.blocklistService = blocklistService
        self.onSave = onSave
        self.onClearCache = onClearCache
        self.onCreateBackup = onCreateBackup
    }

    var body: some View {
        Form {
            if section.id == "subtitles" {
                AdministrativeSubtitlePreview(settings: settings)
            }

            ForEach(section.groups.sorted { $0.order < $1.order }) { group in
                Section {
                    ForEach(group.settings.sorted { $0.order < $1.order }) { setting in
                        AdministrativeSettingControl(
                            setting: setting,
                            stringListOptions: AdministrativeStringListOptionCatalog.options(
                                for: setting,
                                plugins: plugins,
                                hidesNsfw: hidesNsfw
                            )
                        ) { value in
                            guard let updated = await onSave(setting, value) else { return false }
                            section = updated
                            return true
                        }
                        .id(setting.value)
                    }
                } header: {
                    Text(group.label)
                } footer: {
                    Text(group.description)
                }
            }

            if section.includesTranscodeCacheActions {
                AdministrativeTranscodeCacheSection(
                    status: cacheStatus,
                    isWorking: isPerformingAction
                ) {
                    await performCacheClear()
                }
            }

            if section.id == "acquisition", let blocklistService {
                AcquisitionBlocklistSettingsSection(service: blocklistService)
            }

            if section.includesDatabaseBackupActions {
                AdministrativeDatabaseBackupSection(isWorking: isPerformingAction) {
                    await performBackup()
                }
            }
        }
        .prismediaScreenBackground()
        .navigationTitle(section.title)
        .overlay { if isPerformingAction { ProgressView() } }
        .accessibilityIdentifier("administration.settings.detail.\(section.id)")
    }

    private var settings: [AdministrativeSetting] {
        section.groups.flatMap(\.settings)
    }

    private func performCacheClear() async {
        isPerformingAction = true
        defer { isPerformingAction = false }
        if let status = await onClearCache() { cacheStatus = status }
    }

    private func performBackup() async {
        isPerformingAction = true
        defer { isPerformingAction = false }
        _ = await onCreateBackup()
    }
}

#if DEBUG
    #Preview("Settings Detail") {
        let group = AdministrativeSettingsGroup(
            key: "library",
            label: "Library",
            description: "Scanning and organization settings.",
            order: 0,
            settings: [AdministrativePreviewService.setting]
        )
        NavigationStack {
            AdministrativeSettingsDetailView(
                section: AdministrativeSettingsSection(
                    id: "library",
                    title: "Library",
                    description: group.description,
                    systemImageName: "folder",
                    groups: [group],
                    includesTranscodeCacheActions: false,
                    includesDatabaseBackupActions: false
                ),
                cacheStatus: nil,
                plugins: [],
                onSave: { _, _ in nil },
                onClearCache: { nil },
                onCreateBackup: { true }
            )
        }
    }
#endif
