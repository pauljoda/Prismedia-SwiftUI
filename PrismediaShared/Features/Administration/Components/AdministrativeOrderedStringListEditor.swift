import SwiftUI

struct AdministrativeOrderedStringListEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var values: [String]
    @State private var newValue = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let setting: AdministrativeSetting
    let onSave: (AdministrativeJSONValue) async -> Bool

    init(
        setting: AdministrativeSetting,
        onSave: @escaping (AdministrativeJSONValue) async -> Bool
    ) {
        self.setting = setting
        self.onSave = onSave
        _values = State(initialValue: setting.value.stringListValue ?? [])
    }

    var body: some View {
        List {
            Section {
                ForEach(values, id: \.self) { value in
                    Text(value)
                }
                .onDelete(perform: removeValues)
                .onMove(perform: moveValues)
            } header: {
                Text("Values · Priority Order")
            } footer: {
                Text("Add one value at a time. Drag to change priority; the first value is preferred.")
            }

            Section("Add Value") {
                TextField("New value", text: $newValue)
                    .onSubmit(addValue)
                    .disabled(isSaving || hasReachedMaximum)
                Button("Add", systemImage: "plus", action: addValue)
                    .disabled(!canAdd)
            }
        }
        .navigationTitle(setting.label)
        .toolbar {
            #if os(iOS)
                if values.count > 1 {
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
            Text(errorMessage ?? "The values could not be saved.")
        }
    }

    private var normalizedNewValue: String {
        newValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasReachedMaximum: Bool {
        guard let maximum = setting.constraints?.maxItems else { return false }
        return values.count >= maximum
    }

    private var canAdd: Bool {
        !isSaving
            && !hasReachedMaximum
            && !normalizedNewValue.isEmpty
            && !values.contains(normalizedNewValue)
    }

    private var canSave: Bool {
        let minimum = setting.constraints?.minItems ?? 0
        return !isSaving
            && values.count >= minimum
            && values != setting.value.stringListValue
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func addValue() {
        guard canAdd else { return }
        values.append(normalizedNewValue)
        newValue = ""
    }

    private func removeValues(at offsets: IndexSet) {
        guard values.count - offsets.count >= (setting.constraints?.minItems ?? 0) else { return }
        values.remove(atOffsets: offsets)
    }

    private func moveValues(from source: IndexSet, to destination: Int) {
        values.move(fromOffsets: source, toOffset: destination)
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }
        if await onSave(.stringList(values)) {
            dismiss()
        } else {
            errorMessage = "Prismedia could not save these values."
        }
    }
}

#if DEBUG
    #Preview("Ordered Values") {
        NavigationStack {
            AdministrativeOrderedStringListEditor(
                setting: AdministrativePreviewService.stringListSetting,
                onSave: { _ in true }
            )
        }
    }
#endif
