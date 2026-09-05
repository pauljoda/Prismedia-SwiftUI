import SwiftUI

struct AdministrativeStringListControl: View {
    let setting: AdministrativeSetting
    let options: [AdministrativeSettingOption]
    let onSave: (AdministrativeJSONValue) async -> Bool

    var body: some View {
        NavigationLink {
            if AdministrativeStringListOptionCatalog.usesFixedOptions(for: setting) {
                AdministrativeMultiSelectionView(
                    setting: setting,
                    options: options,
                    onSave: onSave
                )
            } else {
                AdministrativeOrderedStringListEditor(setting: setting, onSave: onSave)
            }
        } label: {
            LabeledContent {
                Text(summary)
                    .foregroundStyle(.secondary)
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(setting.label)
                    Text(setting.applyHint.map { "\(description) \($0)" } ?? description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityValue(summary)
    }

    private var values: [String] {
        AdministrativeStringListOptionCatalog.selectedValues(for: setting, options: options)
    }

    private var description: String {
        #if os(iOS)
            if AdministrativeLanguageCatalog.supports(key: setting.key) {
                return "Choose languages and arrange them in your preferred order."
            }
        #endif
        return setting.description
    }

    private var summary: String {
        guard !values.isEmpty else { return "None" }
        #if os(iOS)
            if AdministrativeLanguageCatalog.supports(key: setting.key) {
                return "\(values.count) language\(values.count == 1 ? "" : "s")"
            }
        #endif
        if AdministrativeStringListOptionCatalog.usesFixedOptions(for: setting) {
            return "\(values.count) selected"
        }
        return "\(values.count) value\(values.count == 1 ? "" : "s")"
    }
}

#if DEBUG
    #Preview("String List Control") {
        NavigationStack {
            Form {
                AdministrativeStringListControl(
                    setting: AdministrativePreviewService.stringListSetting,
                    options: [],
                    onSave: { _ in true }
                )
            }
        }
    }
#endif
