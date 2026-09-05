import SwiftUI

/// Native per-kind provider choices backed by one explicit, non-destructive settings draft.
struct AdministrativeProviderDefaultsControl: View {
    @State private var defaults: [String: String]
    @State private var isSaving = false
    @State private var saveFailed = false
    let setting: AdministrativeSetting
    let plugins: [AdministrativePlugin]
    let hidesNsfw: Bool
    let onSave: (AdministrativeJSONValue) async -> Bool

    init(
        setting: AdministrativeSetting, plugins: [AdministrativePlugin], hidesNsfw: Bool,
        onSave: @escaping (AdministrativeJSONValue) async -> Bool
    ) {
        self.setting = setting
        self.plugins = plugins
        self.hidesNsfw = hidesNsfw
        self.onSave = onSave
        _defaults = State(initialValue: setting.value.stringMapValue ?? [:])
    }

    var body: some View {
        Group {
            if hasChanges || isSaving {
                AdministrativeSettingTextActions(
                    settingLabel: setting.label, isSaving: isSaving, canSave: hasChanges && !isSaving,
                    onCancel: {
                        defaults = setting.value.stringMapValue ?? [:]
                        saveFailed = false
                    },
                    onSave: { Task { await save() } })
            }
            if kinds.isEmpty {
                ContentUnavailableView(
                    "No Compatible Providers", systemImage: "puzzlepiece.extension",
                    description: Text("Install and enable a metadata provider in Plugins to choose a default."))
            } else {
                Text(
                    "Automatic uses the first compatible enabled provider. Unavailable preferences are kept until you replace them."
                )
                .font(.footnote).foregroundStyle(.secondary)
                ForEach(kinds) { kind in
                    AdministrativeProviderDefaultPicker(
                        kind: kind, providers: providers(for: kind), selection: selection(for: kind))
                }
            }
            if saveFailed {
                Text("Couldn't save provider preferences. Your changes are still here; try Save again.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .disabled(isSaving)
    }

    private var hasChanges: Bool { defaults != (setting.value.stringMapValue ?? [:]) }

    private var kinds: [EntityKind] {
        RequestIdentifyProviderPreferencePolicy.editableKinds(
            providers: plugins, defaults: setting.value.stringMapValue ?? [:], hidesNsfw: hidesNsfw)
    }

    private func providers(for kind: EntityKind) -> [AdministrativePlugin] {
        RequestIdentifyProviderPreferencePolicy.identifyProviders(
            plugins, entityKind: kind.rawValue, defaultProviderIDs: [:], hidesNsfw: hidesNsfw)
    }

    private func selection(for kind: EntityKind) -> Binding<String?> {
        Binding(
            get: {
                let stored = RequestIdentifyProviderPreferencePolicy.defaultProviderID(for: kind.rawValue, in: defaults)
                return providers(for: kind).first { $0.id.caseInsensitiveCompare(stored ?? "") == .orderedSame }?.id
                    ?? stored
            },
            set: { providerID in
                defaults = RequestIdentifyProviderPreferencePolicy.updatingDefaults(
                    defaults, kind: kind, providerID: providerID)
                saveFailed = false
            })
    }

    private func save() async {
        guard hasChanges, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        saveFailed = !(await onSave(.stringMap(defaults)))
    }
}

#if DEBUG
    #Preview("Provider Defaults · Unavailable") {
        NavigationStack {
            Form {
                AdministrativeProviderDefaultsControl(
                    setting: AdministrativePreviewService.providerDefaultsSetting,
                    plugins: [], hidesNsfw: true, onSave: { _ in false })
            }
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
