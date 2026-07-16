import SwiftUI

struct AdministrativeUserEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var displayName: String
    @State private var password = ""
    @State private var role: UserRole
    @State private var allowNsfw: Bool
    @State private var canCreateLibraries: Bool
    @State private var enabled: Bool
    @State private var rootIDs: Set<UUID>
    @State private var isSaving = false
    @State private var error: String?
    let target: AdministrativeUserEditorTarget
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
        self.target = target
        self.currentUserID = currentUserID
        self.roots = roots
        self.service = service
        self.onSaved = onSaved
        let user = target.user
        _username = State(initialValue: user?.username ?? "")
        _displayName = State(initialValue: user?.displayName ?? "")
        _role = State(initialValue: user?.role ?? .member)
        _allowNsfw = State(initialValue: user?.allowNsfw ?? false)
        _canCreateLibraries = State(initialValue: user?.canCreateLibraries ?? false)
        _enabled = State(initialValue: user?.enabled ?? true)
        _rootIDs = State(initialValue: Set(user?.libraryRootIDs ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Username", text: $username).prismediaPlainTextInput()
                    TextField("Display name", text: $displayName)
                    if target.user == nil {
                        SecureField("Password", text: $password).textContentType(.newPassword)
                        if !password.isEmpty && password.count < 8 {
                            Text("Use at least 8 characters.").font(.footnote).foregroundStyle(
                                PrismediaColor.destructive)
                        }
                    }
                    Picker("Role", selection: $role) {
                        Text("Member").tag(UserRole.member)
                        Text("Administrator").tag(UserRole.admin)
                    }
                    .disabled(isSelf)
                }
                Section("Permissions") {
                    Toggle("Allow NSFW content", isOn: Binding(get: { allowNsfw }, set: setAllowNsfw))
                    Toggle("Can create libraries", isOn: $canCreateLibraries)
                    Toggle("Account enabled", isOn: $enabled).disabled(isSelf)
                }
                if role == .admin {
                    Section { Text("Administrators always have access to every library.").foregroundStyle(.secondary) }
                } else {
                    Section("Library Access") {
                        ForEach(grantableRoots) { root in
                            Toggle(
                                root.label,
                                isOn: Binding(
                                    get: { rootIDs.contains(root.id) },
                                    set: { selected in
                                        if selected { rootIDs.insert(root.id) } else { rootIDs.remove(root.id) }
                                    }
                                )
                            )
                        }
                    }
                }
                if let error { Section { Text(error).foregroundStyle(PrismediaColor.destructive) } }
            }
            .navigationTitle(target.user == nil ? "Add User" : "Edit User")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }.disabled(!isValid || isSaving)
                }
            }
        }
    }

    private var isSelf: Bool { target.user?.id == currentUserID }
    private var isValid: Bool {
        let usernameCount = username.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (1...64).contains(usernameCount) && (target.user != nil || password.count >= 8)
    }
    private var grantableRoots: [AdministrativeLibraryRoot] { allowNsfw ? roots : roots.filter { !$0.isNsfw } }

    private func setAllowNsfw(_ allowed: Bool) {
        allowNsfw = allowed
        if !allowed { rootIDs.subtract(roots.filter(\.isNsfw).map(\.id)) }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let saved: UserAccount
            if let user = target.user {
                saved = try await service.update(
                    id: user.id,
                    mutation: AdministrativeUserUpdateMutation(
                        username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                        displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                        role: isSelf ? nil : role,
                        allowSfw: true,
                        allowNsfw: allowNsfw,
                        canCreateLibraries: canCreateLibraries,
                        enabled: isSelf ? nil : enabled
                    )
                )
            } else {
                saved = try await service.create(
                    AdministrativeUserCreateMutation(
                        username: username.trimmingCharacters(in: .whitespacesAndNewlines),
                        password: password,
                        displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? nil : displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                        role: role,
                        allowNsfw: allowNsfw,
                        canCreateLibraries: canCreateLibraries,
                        enabled: enabled
                    )
                )
            }
            if role != .admin { try await service.replaceLibraryAccess(id: saved.id, rootIDs: Array(rootIDs)) }
            onSaved(saved)
            dismiss()
        } catch let caught { error = caught.localizedDescription }
    }
}

#if DEBUG
    #Preview("User Editor") {
        AdministrativeUserEditor(
            target: AdministrativeUserEditorTarget(),
            currentUserID: PrismediaPreviewData.user.id,
            roots: [],
            service: Step3AdministrationPreviewService(),
            onSaved: { _ in }
        )
    }
#endif
