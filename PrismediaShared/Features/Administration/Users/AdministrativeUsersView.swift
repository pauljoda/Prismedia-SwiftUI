import SwiftUI

struct AdministrativeUsersView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @State private var users: [UserAccount] = []
    @State private var roots: [AdministrativeLibraryRoot] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var editor: AdministrativeUserEditorTarget?
    @State private var passwordTarget: UserAccount?
    @State private var deleteTarget: UserAccount?
    @State private var workingID: UUID?
    @State private var message: String?
    let currentUser: UserAccount
    let service: any UserAdministrationServicing
    let libraryService: any LibraryAdministrationServicing

    var body: some View {
        Group {
            if !currentUser.isAdmin {
                ContentUnavailableView("Administrator Access Required", systemImage: "lock.shield")
            } else {
                List {
                    if let message { Section { Text(message) } }
                    ForEach(filteredUsers) { user in
                        AdministrativeUserRow(
                            user: user,
                            isCurrent: user.id == currentUser.id,
                            isWorking: workingID != nil,
                            libraryCount: roots.count,
                            onEdit: { editor = AdministrativeUserEditorTarget(user: user) },
                            onPassword: { passwordTarget = user },
                            onToggleEnabled: { Task { await toggle(user) } },
                            onDelete: { deleteTarget = user }
                        )
                    }
                }
                .searchable(text: $searchText, prompt: "Search users")
                .overlay {
                    if isLoading && users.isEmpty {
                        PrismediaLoadingView("Loading users…")
                    } else if users.isEmpty {
                        ContentUnavailableView("No Users", systemImage: "person.2.slash")
                    }
                }
                .toolbar {
                    Button("Add User", systemImage: "person.badge.plus") { editor = AdministrativeUserEditorTarget() }
                }
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Users")
        .task { await load() }
        .refreshable { await load() }
        .sheet(item: $editor) { target in
            AdministrativeUserEditor(
                target: target,
                currentUserID: currentUser.id,
                roots: roots,
                service: service,
                onSaved: { saved in
                    if saved.id == currentUser.id { Task { await environment.verifyCurrentSession() } }
                    Task { await load() }
                }
            )
        }
        .sheet(item: $passwordTarget) { user in
            AdministrativeUserPasswordSheet(user: user, service: service) {
                message = "Password reset. The user was signed out everywhere."
                if user.id == currentUser.id { Task { await environment.signOut() } }
            }
        }
        .confirmationDialog(
            "Delete \(deleteTarget?.username ?? "user")?",
            isPresented: Binding(get: { deleteTarget != nil }, set: { if !$0 { deleteTarget = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete User", role: .destructive) { Task { await delete() } }
        } message: {
            Text(
                "Their sessions, watch history, favorites, and library access are removed. The server prevents deletion of the last enabled administrator."
            )
        }
        .accessibilityIdentifier("administration.settings.users")
    }

    private var filteredUsers: [UserAccount] {
        guard !searchText.isEmpty else { return users }
        return users.filter {
            $0.username.localizedStandardContains(searchText) || $0.displayName.localizedStandardContains(searchText)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let loadedUsers = service.users()
            async let loadedRoots = libraryService.roots()
            (users, roots) = try await (loadedUsers, loadedRoots)
            message = nil
        } catch { message = error.localizedDescription }
    }

    private func toggle(_ user: UserAccount) async {
        guard user.id != currentUser.id else { return }
        workingID = user.id
        defer { workingID = nil }
        do {
            _ = try await service.update(
                id: user.id, mutation: AdministrativeUserUpdateMutation(enabled: !user.enabled))
            await load()
        } catch { message = error.localizedDescription }
    }

    private func delete() async {
        guard let user = deleteTarget, user.id != currentUser.id else { return }
        workingID = user.id
        defer {
            workingID = nil
            deleteTarget = nil
        }
        do {
            try await service.delete(id: user.id)
            await load()
        } catch { message = error.localizedDescription }
    }
}

#if DEBUG
    #Preview("Users · Content") {
        NavigationStack {
            AdministrativeUsersView(
                currentUser: PrismediaPreviewData.user,
                service: Step3AdministrationPreviewService(),
                libraryService: Step3AdministrationPreviewService()
            )
        }
        .environment(PrismediaPreviewData.model(signedIn: true))
    }
#endif
