import SwiftUI

struct AdministrativeUsersView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @State private var users = AdministrativeCollectionLoadState<UserAccount>()
    @State private var roots = AdministrativeCollectionLoadState<AdministrativeLibraryRoot>()
    @State private var searchText = ""
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
                    if let error = users.errorMessage {
                        PrismediaRetryView(
                            title: "Couldn't Load Users", message: error,
                            retry: { Task { await loadUsers() } })
                    }
                    if let error = roots.errorMessage {
                        PrismediaRetryView(
                            title: "Library Access Unavailable",
                            message: "Reload libraries before adding or editing users. \(error)",
                            retry: { Task { await loadRoots() } })
                    } else if roots.isLoading && !users.items.isEmpty {
                        ProgressView("Loading library access…")
                    }
                    ForEach(filteredUsers) { user in
                        AdministrativeUserRow(
                            user: user,
                            isCurrent: user.id == currentUser.id,
                            isWorking: workingID != nil || !users.isReady,
                            canEdit: roots.isReady,
                            libraryCount: roots.isReady ? roots.items.count : 0,
                            onEdit: { editor = AdministrativeUserEditorTarget(user: user) },
                            onPassword: { passwordTarget = user },
                            onToggleEnabled: { Task { await toggle(user) } },
                            onDelete: { deleteTarget = user }
                        )
                    }
                    if users.isReady && filteredUsers.isEmpty {
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            ContentUnavailableView("No Users", systemImage: "person.2.slash")
                        } else {
                            ContentUnavailableView.search(text: searchText)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search users")
                .overlay {
                    if users.isLoading && users.items.isEmpty && roots.errorMessage == nil {
                        PrismediaLoadingView("Loading users…")
                    }
                }
                .toolbar {
                    Button("Add User", systemImage: "person.badge.plus") { editor = AdministrativeUserEditorTarget() }
                        .disabled(!users.isReady || !roots.isReady || workingID != nil)
                }
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Users")
        .task { await load() }
        .refreshable {
            await PrismediaRefreshAction.perform {
                await load()
            }
        }
        .sheet(item: $editor) { target in
            AdministrativeUserEditor(
                target: target,
                currentUserID: currentUser.id,
                roots: roots.items,
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
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return users.items }
        return users.items.filter {
            $0.username.localizedStandardContains(query) || $0.displayName.localizedStandardContains(query)
        }
    }

    private func load() async {
        guard currentUser.isAdmin else { return }
        message = nil
        async let accounts: () = loadUsers()
        async let libraries: () = loadRoots()
        _ = await (accounts, libraries)
    }

    private func loadUsers() async {
        let request = users.begin()
        do {
            let loaded = try await service.users()
            users.succeed(loaded, request: request, isCancelled: Task.isCancelled)
        } catch {
            users.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func loadRoots() async {
        let request = roots.begin()
        do {
            let loaded = try await libraryService.roots()
            roots.succeed(loaded, request: request, isCancelled: Task.isCancelled)
        } catch {
            roots.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func toggle(_ user: UserAccount) async {
        guard user.id != currentUser.id, workingID == nil, users.isReady else { return }
        workingID = user.id
        defer { workingID = nil }
        do {
            _ = try await service.update(
                id: user.id, mutation: AdministrativeUserUpdateMutation(enabled: !user.enabled))
            await load()
        } catch { message = error.localizedDescription }
    }

    private func delete() async {
        guard let user = deleteTarget, user.id != currentUser.id, workingID == nil, users.isReady else { return }
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
    #Preview("Users · Library Access Unavailable") {
        NavigationStack {
            AdministrativeUsersView(
                currentUser: PrismediaPreviewData.user,
                service: Step3AdministrationPreviewService(),
                libraryService: Step3AdministrationPreviewService(rootsUnavailable: true)
            )
        }
        .environment(PrismediaPreviewData.model(signedIn: true))
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("Users · Empty") {
        NavigationStack {
            AdministrativeUsersView(
                currentUser: PrismediaPreviewData.user,
                service: Step3AdministrationPreviewService(emptyCollections: true),
                libraryService: Step3AdministrationPreviewService()
            )
        }
        .environment(PrismediaPreviewData.model(signedIn: true))
    }

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
