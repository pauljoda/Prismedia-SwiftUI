import SwiftUI

struct AdministrativeUserEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AdministrativeUserDraft
    @State private var saveSession: AdministrativeUserSaveSession
    let currentUserID: UUID
    let roots: [AdministrativeLibraryRoot]
    let service: any UserAdministrationServicing
    let onSaved: (UserAccount) -> Void

    init(
        target: AdministrativeUserEditorTarget,
        currentUserID: UUID,
        roots: [AdministrativeLibraryRoot],
        service: any UserAdministrationServicing,
        onSaved: @escaping (UserAccount) -> Void
    ) {
        self.currentUserID = currentUserID
        self.roots = roots
        self.service = service
        self.onSaved = onSaved
        _draft = State(initialValue: AdministrativeUserDraft(user: target.user))
        _saveSession = State(initialValue: AdministrativeUserSaveSession(user: target.user))
    }

    var body: some View {
        NavigationStack {
            Form {
                if saveSession.libraryAccessNeedsRetry && !saveSession.isSaving {
                    Section {
                        Text("Account saved. Library access still needs to be saved.")
                        Button("Retry Save", systemImage: "arrow.clockwise") { Task { await save() } }
                            .disabled(!isValid)
                    }
                }
                if saveSession.isSaving { Section { ProgressView("Saving user…") } }
                AdministrativeUserAccountFields(draft: $draft, requiresPassword: saveSession.account == nil)
                Section {
                    Picker("Role", selection: $draft.role) {
                        Text("Member").tag(UserRole.member)
                        Text("Administrator").tag(UserRole.admin)
                    }
                    .disabled(isSelf)
                    Toggle("Account enabled", isOn: $draft.enabled).disabled(isSelf)
                } header: {
                    Text("Account Access")
                } footer: {
                    if isSelf { Text("You cannot disable your own account or change your own role.") }
                }
                Section("Permissions") {
                    Toggle("Allow NSFW content", isOn: Binding(
                        get: { draft.allowNsfw },
                        set: { draft.setAllowNsfw($0, roots: roots) }
                    ))
                    Toggle("Create libraries", isOn: $draft.canCreateLibraries)
                    Toggle("Request content", isOn: $draft.canRequestContent)
                }
                Section {
                    if draft.role == .admin {
                        Label("All libraries", systemImage: "checkmark.shield")
                    } else if grantableRoots.isEmpty {
                        Text("No libraries available.").foregroundStyle(.secondary)
                    } else {
                        ForEach(grantableRoots) { root in
                            Toggle(root.label, isOn: Binding(
                                get: { draft.rootIDs.contains(root.id) },
                                set: { selected in
                                    if selected { draft.rootIDs.insert(root.id) }
                                    else { draft.rootIDs.remove(root.id) }
                                }
                            ))
                        }
                    }
                } header: {
                    Text("Library Access")
                } footer: {
                    if draft.role == .admin { Text("Administrators have access to every library.") }
                    else { Text("Select the libraries this member can use.") }
                }
            }
            .disabled(saveSession.isSaving)
            .prismediaScreenBackground()
            .navigationTitle(saveSession.account == nil ? "Add User" : "Edit User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    PrismediaToolbarActionButton("Close", systemImage: "xmark") { dismiss() }
                        .disabled(saveSession.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Save", systemImage: "checkmark") { Task { await save() } }
                        .disabled(!isValid || saveSession.isSaving)
                }
            }
        }
        .interactiveDismissDisabled(saveSession.isSaving)
        .alert(
            saveSession.libraryAccessNeedsRetry ? "Library Access Not Saved" : "Unable to Save User",
            isPresented: Binding(
                get: { saveSession.error != nil },
                set: { if !$0 { saveSession.dismissError() } }
            )
        ) {
            Button("Retry Save") { Task { await save() } }
                .disabled(!isValid)
            Button("Keep Editing", role: .cancel) { }
        } message: {
            if saveSession.libraryAccessNeedsRetry {
                Text("The account was saved. Retry to finish saving its library access. \(saveSession.error ?? "")")
            } else {
                Text(saveSession.error ?? "")
            }
        }
    }

    private var isSelf: Bool { saveSession.account?.id == currentUserID }
    private var isValid: Bool { draft.isValid(requiresPassword: saveSession.account == nil) }
    private var grantableRoots: [AdministrativeLibraryRoot] { draft.allowNsfw ? roots : roots.filter { !$0.isNsfw } }

    private func save() async {
        guard !saveSession.isSaving, isValid else { return }
        let result = await saveSession.save(draft, currentUserID: currentUserID, service: service)
        if saveSession.hasSavedAccount, let account = saveSession.account {
            draft.password = ""
            onSaved(account)
        }
        if result != nil { dismiss() }
    }
}

#if DEBUG
    #Preview("User Editor") {
        AdministrativeUserEditor(
            target: AdministrativeUserEditorTarget(),
            currentUserID: PrismediaPreviewData.user.id,
            roots: [], service: Step3AdministrationPreviewService(), onSaved: { _ in }
        )
    }
#endif
