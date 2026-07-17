import SwiftUI

struct AdministrativePluginCredentialEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var values: [String: String] = [:]
    @State private var clearedKeys = Set<String>()
    @State private var isSaving = false
    @State private var errorMessage: String?
    let plugin: AdministrativePlugin
    let service: any PluginAdministrationServicing
    let onSaved: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(
                        "Stored credentials are never read back. Leave a field blank to keep its saved value, enter a replacement, or explicitly clear it."
                    )
                    .foregroundStyle(.secondary)
                }
                ForEach(plugin.auth) { field in
                    Section {
                        SecureField(field.label, text: valueBinding(for: field.key))
                            .textContentType(.password)
                            .privacySensitive()
                            .disabled(clearedKeys.contains(field.key))
                        if !plugin.missingAuthKeys.contains(field.key) {
                            Toggle("Clear saved value", isOn: clearBinding(for: field.key))
                        }
                        if let value = field.url, let url = URL(string: value) {
                            Link("Open Credential Provider", destination: url)
                        }
                    } header: {
                        Text(field.required ? "\(field.label) · Required" : field.label)
                    }
                }
            }
            .navigationTitle("\(plugin.name) Credentials")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving || !hasChanges)
                }
            }
            .overlay { if isSaving { ProgressView("Saving securely…") } }
            .alert(
                "Credentials Not Saved",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .frame(minWidth: 380, minHeight: 420)
    }

    private var hasChanges: Bool {
        values.values.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } || !clearedKeys.isEmpty
    }

    private func valueBinding(for key: String) -> Binding<String> {
        Binding(get: { values[key, default: ""] }, set: { values[key] = $0 })
    }

    private func clearBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { clearedKeys.contains(key) },
            set: { clearing in
                if clearing {
                    clearedKeys.insert(key)
                    values[key] = ""
                } else {
                    clearedKeys.remove(key)
                }
            }
        )
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await PluginAdministrationUseCase(service: service).saveAuth(
                id: plugin.id,
                replacements: values,
                clearedKeys: clearedKeys
            )
            values.removeAll()
            clearedKeys.removeAll()
            onSaved()
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}

#if DEBUG
    #Preview("Credentials · Saved and Required") {
        AdministrativePluginCredentialEditor(
            plugin: AdministrativePlugin(
                id: "tmdb", name: "TMDB", version: "1.0.0", installed: true, enabled: true, isNsfw: false,
                supports: [],
                auth: [
                    .init(key: "api_key", label: "API Key", required: true, url: "https://example.invalid"),
                    .init(key: "client_secret", label: "Client Secret", required: false, url: nil),
                ],
                missingAuthKeys: ["api_key"], updateAvailable: false, availableVersion: nil
            ),
            service: Step4AdministrationPreviewService(),
            onSaved: {}
        )
    }
#endif
