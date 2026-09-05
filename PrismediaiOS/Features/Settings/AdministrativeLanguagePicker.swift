#if os(iOS)
import SwiftUI

/// Searchable language suggestions that append one exact code to the parent's ordered draft.
struct AdministrativeLanguagePicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var customCode = ""
    @State private var options = AdministrativeLanguageCatalog.options()

    let selectedCodes: [String]
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DisclosureGroup("Use a Specific Language Code") {
                        TextField("Language or regional code", text: $customCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit { chooseCustomCode() }
                        Button("Add Code", systemImage: "plus") { chooseCustomCode() }
                            .disabled(!canAddCustomCode)
                        Text("For regional variants or codes supplied by your media provider. Existing codes are kept unchanged.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Languages") {
                    ForEach(matchingOptions) { option in
                        Button {
                            onSelect(option.value)
                            dismiss()
                        } label: {
                            HStack(spacing: PrismediaSpacing.medium) {
                                VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                                    Text(option.label)
                                    Text(option.value).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if selectedCodes.contains(option.value) {
                                    Image(systemName: "checkmark").accessibilityLabel("Already added")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedCodes.contains(option.value))
                    }
                    if matchingOptions.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                }
            }
            .searchable(text: $query, prompt: "Language name or code")
            .prismediaScreenBackground()
            .navigationTitle("Add Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    PrismediaToolbarActionButton("Cancel", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }

    private var matchingOptions: [AdministrativeSettingOption] {
        AdministrativeLanguageCatalog.matching(query, in: options)
    }

    private var normalizedCustomCode: String {
        customCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddCustomCode: Bool {
        !normalizedCustomCode.isEmpty && !selectedCodes.contains(normalizedCustomCode)
    }

    private func chooseCustomCode() {
        guard canAddCustomCode else { return }
        onSelect(normalizedCustomCode)
        dismiss()
    }
}

#Preview {
    AdministrativeLanguagePicker(selectedCodes: [], onSelect: { _ in })
}
#endif
