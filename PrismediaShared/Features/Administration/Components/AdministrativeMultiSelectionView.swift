import SwiftUI

struct AdministrativeMultiSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedValues: [String]
    @State private var isSaving = false
    @State private var errorMessage: String?

    let setting: AdministrativeSetting
    let options: [AdministrativeSettingOption]
    let onSave: (AdministrativeJSONValue) async -> Bool

    init(
        setting: AdministrativeSetting,
        options: [AdministrativeSettingOption],
        onSave: @escaping (AdministrativeJSONValue) async -> Bool
    ) {
        self.setting = setting
        self.options = options
        self.onSave = onSave
        _selectedValues = State(
            initialValue: AdministrativeStringListOptionCatalog.selectedValues(
                for: setting,
                options: options
            )
        )
    }

    var body: some View {
        List {
            if !selectedOptions.isEmpty {
                Section {
                    ForEach(selectedOptions) { option in
                        selectedRow(option)
                    }
                    .onDelete(perform: removeSelectedValues)
                    .onMove(perform: moveSelectedValues)
                } header: {
                    Text(setting.key == "autoIdentify.providers" ? "Selected · Tried in Order" : "Selected")
                } footer: {
                    if setting.key == "autoIdentify.providers" {
                        Text("Auto Identify tries selected plugins from top to bottom.")
                    }
                }
            }

            Section(availableSectionTitle) {
                ForEach(availableOptions) { option in
                    Button {
                        select(option)
                    } label: {
                        optionLabel(option, isSelected: false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving || hasReachedMaximum)
                }
            }
        }
        .navigationTitle(setting.label)
        .toolbar {
            #if os(iOS)
                if selectedValues.count > 1 {
                    ToolbarItem(placement: .secondaryAction) {
                        EditButton()
                    }
                }
            #endif
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(!canSave)
            }
        }
        .overlay {
            if isSaving { ProgressView("Saving…") }
        }
        .alert("Unable to Save", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "The selection could not be saved.")
        }
    }

    private var selectedOptions: [AdministrativeSettingOption] {
        selectedValues.map { value in
            options.first { $0.value == value }
                ?? AdministrativeSettingOption(value: value, label: value, description: "Unavailable")
        }
    }

    private var availableOptions: [AdministrativeSettingOption] {
        options.filter { !selectedValues.contains($0.value) }
    }

    private var availableSectionTitle: String {
        selectedOptions.isEmpty ? "Options" : "Available"
    }

    private var hasReachedMaximum: Bool {
        guard let maximum = setting.constraints?.maxItems else { return false }
        return selectedValues.count >= maximum
    }

    private var canSave: Bool {
        let minimum = setting.constraints?.minItems ?? 0
        return !isSaving
            && selectedValues.count >= minimum
            && selectedValues != setting.value.stringListValue
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func selectedRow(_ option: AdministrativeSettingOption) -> some View {
        Button {
            selectedValues.removeAll { $0 == option.value }
        } label: {
            optionLabel(option, isSelected: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isSaving || wouldViolateMinimum)
    }

    private func optionLabel(_ option: AdministrativeSettingOption, isSelected: Bool) -> some View {
        HStack(spacing: PrismediaSpacing.medium) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? PrismediaColor.accent : PrismediaColor.textSecondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                Text(option.label)
                if let description = option.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var wouldViolateMinimum: Bool {
        selectedValues.count <= (setting.constraints?.minItems ?? 0)
    }

    private func select(_ option: AdministrativeSettingOption) {
        guard !selectedValues.contains(option.value), !hasReachedMaximum else { return }
        selectedValues.append(option.value)
    }

    private func removeSelectedValues(at offsets: IndexSet) {
        guard selectedValues.count - offsets.count >= (setting.constraints?.minItems ?? 0) else { return }
        selectedValues.remove(atOffsets: offsets)
    }

    private func moveSelectedValues(from source: IndexSet, to destination: Int) {
        selectedValues.move(fromOffsets: source, toOffset: destination)
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        if await onSave(.stringList(selectedValues)) {
            dismiss()
        } else {
            errorMessage = "Prismedia could not save this selection."
        }
    }
}

#if DEBUG
    #Preview("Multi Selection") {
        NavigationStack {
            AdministrativeMultiSelectionView(
                setting: AdministrativePreviewService.autoIdentifyKindSetting,
                options: AdministrativeStringListOptionCatalog.options(
                    for: AdministrativePreviewService.autoIdentifyKindSetting,
                    plugins: []
                ),
                onSave: { _ in true }
            )
        }
    }
#endif
