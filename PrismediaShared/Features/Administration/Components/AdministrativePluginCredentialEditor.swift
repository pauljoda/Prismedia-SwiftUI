import SwiftUI

struct AdministrativePluginCredentialEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft = PluginCredentialDraft()
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var confirmsDiscard = false
    let plugin: AdministrativePlugin
    let service: any PluginAdministrationServicing
    let onSaved: @MainActor () -> Void

    var body: some View {
        NavigationStack {
            Form {
                ForEach(plugin.auth) { field in
                    Section {
                        SecureField("Enter a replacement", text: $draft[field.key])
                            .accessibilityLabel(field.label)
                            .autocorrectionDisabled()
                            #if os(iOS) || os(tvOS)
                                .textInputAutocapitalization(.never)
                            #endif
                            .privacySensitive()
                            .disabled(draft.clearedKeys.contains(field.key))
                        if !plugin.missingAuthKeys.contains(field.key) {
                            Toggle("Remove existing value", isOn: clearBinding(for: field.key))
                        }
                        if let value = field.url, let url = URL(string: value) {
                            Link("Get Credentials", destination: url)
                        }
                    } header: {
                        Text(field.label)
                    } footer: {
                        if draft.clearedKeys.contains(field.key) {
                            Text("This value will be removed when you save.")
                        } else if field.required, plugin.missingAuthKeys.contains(field.key) {
                            Text("Required to use \(plugin.name).")
                        } else {
                            Text("Saved values aren't shown. Leave blank to keep the existing value.")
                        }
                    }
                }
            }
            .disabled(isSaving)
            .prismediaScreenBackground()
            .navigationTitle("Credentials")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    PrismediaToolbarActionButton("Cancel", systemImage: "xmark") {
                        if draft.hasChanges { confirmsDiscard = true } else { dismiss() }
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Save", systemImage: "checkmark") {
                        Task { await save() }
                    }
                    .disabled(isSaving || !draft.hasChanges)
                }
            }
            .interactiveDismissDisabled(isSaving || draft.hasChanges)
            .confirmationDialog("Discard credential changes?", isPresented: $confirmsDiscard, titleVisibility: .visible)
            {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
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
        #if os(macOS)
            .frame(minWidth: 380, minHeight: 420)
        #endif
    }

    private func clearBinding(for key: String) -> Binding<Bool> {
        Binding(
            get: { draft.clearedKeys.contains(key) },
            set: { draft.setCleared($0, for: key) }
        )
    }

    private func save() async {
        guard !isSaving, draft.hasChanges else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await PluginAdministrationUseCase(service: service).saveAuth(
                id: plugin.id,
                replacements: draft.values,
                clearedKeys: draft.clearedKeys
            )
            draft = .init()
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
