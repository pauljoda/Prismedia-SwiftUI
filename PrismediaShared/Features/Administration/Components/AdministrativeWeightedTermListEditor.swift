import SwiftUI

struct AdministrativeWeightedTermListEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var values: [SubtitlePreferenceTerm]
    @State private var newTerm = ""
    @State private var newWeight = 100
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
        _values = State(initialValue: setting.value.weightedTermListValue ?? [])
    }

    var body: some View {
        List {
            Section {
                ForEach($values, id: \.term) { $value in
                    LabeledContent(value.term) {
                        TextField("Weight", value: $value.weight, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 72)
                            .monospacedDigit()
                    }
                }
                .onDelete(perform: removeValues)
                .onMove(perform: moveValues)
            } header: {
                Text("Preference Terms")
            } footer: {
                Text(
                    "Each term is matched separately against a track’s language and label, ignoring case. "
                        + "Matching weights add together, so English Forced can match Forced, English, and Eng."
                )
            }

            Section {
                TextField("Term", text: $newTerm)
                    .onSubmit(addValue)
                    .disabled(isSaving || hasReachedMaximum)
                TextField("Weight", value: $newWeight, format: .number)
                    .monospacedDigit()
                Button("Add Term", systemImage: "plus", action: addValue)
                    .disabled(!canAdd)
            } header: {
                Text("Add Term")
            } footer: {
                Text(
                    "The highest total score wins. When scores tie, the first matching track keeps priority."
                )
            }
        }
        .prismediaScreenBackground()
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
            Text(errorMessage ?? "The preference terms could not be saved.")
        }
    }

    private var normalizedNewTerm: String {
        newTerm.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var weightRange: ClosedRange<Int> {
        let minimum = Int(setting.constraints?.minimum ?? 1)
        return minimum...max(minimum, Int(setting.constraints?.maximum ?? 100))
    }

    private var hasReachedMaximum: Bool {
        guard let maximum = setting.constraints?.maxItems else { return false }
        return values.count >= maximum
    }

    private var canAdd: Bool {
        !isSaving
            && !hasReachedMaximum
            && !normalizedNewTerm.isEmpty
            && weightRange.contains(newWeight)
            && !values.contains {
                $0.term.localizedCaseInsensitiveCompare(normalizedNewTerm) == .orderedSame
            }
    }

    private var canSave: Bool {
        let minimum = setting.constraints?.minItems ?? 0
        return !isSaving
            && values.count >= minimum
            && values.allSatisfy { weightRange.contains($0.weight) }
            && values != setting.value.weightedTermListValue
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func addValue() {
        guard canAdd else { return }
        values.append(
            SubtitlePreferenceTerm(
                term: normalizedNewTerm,
                weight: min(max(newWeight, weightRange.lowerBound), weightRange.upperBound)
            )
        )
        newTerm = ""
        newWeight = min(100, weightRange.upperBound)
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
        if await onSave(.weightedTermList(values)) {
            dismiss()
        } else {
            errorMessage = "Prismedia could not save these preference terms."
        }
    }
}

#if DEBUG
    #Preview("Weighted Preference Terms") {
        NavigationStack {
            AdministrativeWeightedTermListEditor(
                setting: AdministrativePreviewService.weightedTermListSetting,
                onSave: { _ in true }
            )
        }
    }
#endif
