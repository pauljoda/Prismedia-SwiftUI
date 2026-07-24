import SwiftUI

struct AdministrativeWeightedTermListControl: View {
    let setting: AdministrativeSetting
    let onSave: (AdministrativeJSONValue) async -> Bool

    var body: some View {
        NavigationLink {
            AdministrativeWeightedTermListEditor(
                setting: setting,
                onSave: onSave
            )
        } label: {
            LabeledContent {
                Text(summary)
                    .foregroundStyle(.secondary)
            } label: {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                    Text(setting.label)
                    Text(setting.applyHint.map { "\(setting.description) \($0)" } ?? setting.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityValue(summary)
    }

    private var summary: String {
        let count = setting.value.weightedTermListValue?.count ?? 0
        return count == 0 ? "None" : "\(count) term\(count == 1 ? "" : "s")"
    }
}

#if DEBUG
    #Preview("Weighted Term List Control") {
        NavigationStack {
            Form {
                AdministrativeWeightedTermListControl(
                    setting: AdministrativePreviewService.weightedTermListSetting,
                    onSave: { _ in true }
                )
            }
        }
    }
#endif
