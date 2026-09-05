import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFileNameEditor: View {
        @Environment(\.dismiss) private var dismiss
        @State private var name: String
        @State private var isSaving = false
        @State private var errorMessage: String?
        let action: AdministrativeFileNameAction
        let location: AdministrativeFileLocation
        let service: any FileAdministrationServicing
        let onSaved: @MainActor () -> Void

        init(
            action: AdministrativeFileNameAction, location: AdministrativeFileLocation,
            service: any FileAdministrationServicing, onSaved: @escaping @MainActor () -> Void
        ) {
            self.action = action
            self.location = location
            self.service = service
            self.onSaved = onSaved
            if case .rename(let entry) = action {
                _name = State(initialValue: entry.name)
            } else {
                _name = State(initialValue: "")
            }
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        TextField("Name", text: $name)
                            .autocorrectionDisabled()
                            #if os(iOS)
                                .textInputAutocapitalization(.never)
                            #endif
                            .disabled(isSaving)
                    } header: {
                        Text("Name")
                    } footer: {
                        if !name.isEmpty, validatedName == nil {
                            Text("Use a name without slashes, or a dot on its own.")
                        }
                    }
                    if case .rename(let entry) = action {
                        Section("Current Name") {
                            Text(entry.name).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if let errorMessage {
                        Section { Text(errorMessage).foregroundStyle(PrismediaColor.destructive) }
                    }
                    if isSaving { Section { ProgressView("Saving…") } }
                }
                .prismediaScreenBackground()
                .navigationTitle(action.title)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        PrismediaToolbarActionButton("Cancel", systemImage: "xmark") { dismiss() }
                            .disabled(isSaving)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        PrismediaToolbarActionButton(LocalizedStringKey(action.confirmLabel), systemImage: "checkmark")
                        {
                            Task { await save() }
                        }.disabled(isSaving || !canSave)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
            #if os(macOS)
                .frame(minWidth: 360, minHeight: 300)
            #endif
        }

        private var validatedName: String? { try? AdministrativeFilePathPolicy.validatedName(name) }

        private var canSave: Bool {
            guard let validatedName else { return false }
            if case .rename(let entry) = action { return validatedName != entry.name }
            return true
        }

        private func save() async {
            guard !isSaving, canSave, let submittedName = validatedName else { return }
            isSaving = true
            errorMessage = nil
            defer { isSaving = false }
            do {
                switch action {
                case .createFolder:
                    _ = try await service.createFolder(
                        rootID: location.rootID, parentPath: location.path, name: submittedName)
                case .rename(let entry):
                    _ = try await service.rename(rootID: entry.rootID, path: entry.path, name: submittedName)
                }
                onSaved()
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
    #if DEBUG
        #Preview {
            AdministrativeFileNameEditor(
                action: .createFolder,
                location: .init(rootID: Step4AdministrationPreviewService.rootID, rootLabel: "Movies", path: ""),
                service: Step4AdministrationPreviewService(), onSaved: {})
        }
        #Preview("Accessibility") {
            AdministrativeFileNameEditor(
                action: .createFolder,
                location: .init(rootID: Step4AdministrationPreviewService.rootID, rootLabel: "Movies", path: ""),
                service: Step4AdministrationPreviewService(), onSaved: {}
            )
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
