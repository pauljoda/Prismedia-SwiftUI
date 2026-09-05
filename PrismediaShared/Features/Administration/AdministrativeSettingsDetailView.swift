import SwiftUI

struct AdministrativeSettingsDetailView: View {
    @State private var section: AdministrativeSettingsSection
    let cacheStatus: AdministrativeTranscodeCacheStatus?
    @State private var isPerformingAction = false
    let plugins: [AdministrativePlugin]
    let canEditSettings: Bool
    let isRefreshingSettings: Bool
    let isSavingSetting: Bool
    let arePluginsAvailable: Bool
    let isCacheReady: Bool
    let hidesNsfw: Bool
    let blocklistService: (any AcquisitionBlocklistServicing)?
    let profileService: (any AdministrationServicing)?
    let onSave: (AdministrativeSetting, AdministrativeJSONValue) async -> AdministrativeSettingsSection?
    let onClearCache: () async -> AdministrativeTranscodeCacheStatus?
    let onCreateBackup: () async -> Bool

    init(
        section: AdministrativeSettingsSection,
        cacheStatus: AdministrativeTranscodeCacheStatus?,
        plugins: [AdministrativePlugin] = [],
        canEditSettings: Bool = true,
        isRefreshingSettings: Bool = false,
        isSavingSetting: Bool = false,
        arePluginsAvailable: Bool = true,
        isCacheReady: Bool = true,
        hidesNsfw: Bool = true,
        blocklistService: (any AcquisitionBlocklistServicing)? = nil,
        profileService: (any AdministrationServicing)? = nil,
        onSave: @escaping (AdministrativeSetting, AdministrativeJSONValue) async -> AdministrativeSettingsSection?,
        onClearCache: @escaping () async -> AdministrativeTranscodeCacheStatus?,
        onCreateBackup: @escaping () async -> Bool
    ) {
        _section = State(initialValue: section)
        self.cacheStatus = cacheStatus
        self.plugins = plugins
        self.canEditSettings = canEditSettings
        self.isRefreshingSettings = isRefreshingSettings
        self.isSavingSetting = isSavingSetting
        self.arePluginsAvailable = arePluginsAvailable
        self.isCacheReady = isCacheReady
        self.hidesNsfw = hidesNsfw
        self.blocklistService = blocklistService
        self.profileService = profileService
        self.onSave = onSave
        self.onClearCache = onClearCache
        self.onCreateBackup = onCreateBackup
    }

    var body: some View {
        Form {
            if isSavingSetting {
                Section { ProgressView("Saving setting…") }
            } else if isRefreshingSettings {
                Section { ProgressView("Refreshing settings…") }
            } else if !canEditSettings {
                Section {
                    Text("Reload server settings from Settings before editing.")
                        .foregroundStyle(.secondary)
                }
            }
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
                            ),
                            plugins: plugins,
                            hidesNsfw: hidesNsfw
                        ) { value in
                            guard let updated = await onSave(setting, value) else { return false }
                            section = updated
                            return true
                        }
                        .disabled(
                            !canEditSettings
                                || (!arePluginsAvailable
                                    && requiresProviders(setting))
                        )
                        .id(setting.value)
                        if !arePluginsAvailable
                            && requiresProviders(setting)
                        {
                            Text("Reload provider choices from Settings before changing this selection.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(group.label)
                } footer: {
                    Text(group.description)
                }
            }

            if section.includesTranscodeCacheActions {
                if !isCacheReady {
                    Section {
                        Text("Reload cache status from Settings before clearing prepared streams.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                AdministrativeTranscodeCacheSection(
                    status: cacheStatus,
                    isWorking: isPerformingAction || !isCacheReady
                ) {
                    await performCacheClear()
                }
            }

            if section.id == "acquisition", let blocklistService {
                AcquisitionBlocklistSettingsSection(service: blocklistService)
            }

            #if os(iOS) || os(macOS)
                if section.id == "acquisition", let profileService {
                    AdministrativeAcquisitionProfileTimingSection(service: profileService)
                }
            #endif

            if section.includesDatabaseBackupActions {
                AdministrativeDatabaseBackupSection(isWorking: isPerformingAction) {
                    await performBackup()
                }
            }
        }
        .prismediaSettingsForm()
        .prismediaScreenBackground()
        .navigationTitle(section.title)
        .overlay { if isPerformingAction { ProgressView() } }
        .accessibilityIdentifier("administration.settings.detail.\(section.id)")
    }

    private var settings: [AdministrativeSetting] {
        section.groups.flatMap(\.settings)
    }

    private func requiresProviders(_ setting: AdministrativeSetting) -> Bool {
        setting.key == PrismediaContractCodes.SettingKey.autoIdentifyProviders
            || setting.controlKind == .providerDefaults
    }

    private func performCacheClear() async {
        isPerformingAction = true
        defer { isPerformingAction = false }
        guard isCacheReady else { return }
        _ = await onClearCache()
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
