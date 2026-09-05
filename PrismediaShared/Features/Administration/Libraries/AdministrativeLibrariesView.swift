import SwiftUI

struct AdministrativeLibrariesView: View {
    @State private var roots = AdministrativeCollectionLoadState<AdministrativeLibraryRoot>()
    @State private var users = AdministrativeCollectionLoadState<UserAccount>()
    @State private var workingID: UUID?
    @State private var editor: AdministrativeLibraryEditorTarget?
    @State private var deletion: AdministrativeLibraryRoot?
    @State private var message: String?
    let user: UserAccount
    let service: any LibraryAdministrationServicing
    let userService: (any UserAdministrationServicing)?

    var body: some View {
        List {
            if let message {
                Section {
                    Text(message).foregroundStyle(message.hasPrefix("Queued") ? .secondary : PrismediaColor.destructive)
                }
            }
            if let error = roots.errorMessage {
                PrismediaRetryView(
                    title: "Couldn't Load Watched Libraries", message: error,
                    retry: { Task { await loadRoots() } })
            }
            if let error = users.errorMessage {
                PrismediaRetryView(
                    title: "Member Access Unavailable",
                    message: "Reload users before adding or editing libraries. \(error)",
                    retry: { Task { await loadUsers() } })
            } else if user.isAdmin && users.isLoading && !roots.items.isEmpty {
                ProgressView("Loading member access…")
            }
            ForEach(roots.items) { root in
                AdministrativeLibraryRootRow(
                    root: root,
                    isWorking: workingID != nil || !roots.isReady,
                    canEdit: canEdit,
                    onEdit: { editor = AdministrativeLibraryEditorTarget(root: root) },
                    onToggle: { Task { await toggle(root) } },
                    onRescan: { Task { await rescan(root) } },
                    onDelete: { deletion = root }
                )
            }
            if roots.isReady && roots.items.isEmpty {
                ContentUnavailableView(
                    "No Watched Libraries", systemImage: "folder.badge.plus",
                    description: Text("Add a mounted server folder to begin scanning media."))
            }
        }
        .overlay {
            if roots.isLoading && roots.items.isEmpty && users.errorMessage == nil {
                PrismediaLoadingView("Loading watched libraries…")
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Watched Libraries")
        .toolbar {
            Button("Add Library", systemImage: "plus") { editor = AdministrativeLibraryEditorTarget() }
                .disabled(!canEdit || workingID != nil)
        }
        .refreshable {
            await PrismediaRefreshAction.perform {
                await load()
            }
        }
        .task { await load() }
        .sheet(item: $editor) { target in
            AdministrativeLibraryRootEditor(
                target: target,
                availableUsers: users.items,
                allowsNsfw: user.allowNsfw,
                isAdministrator: user.isAdmin,
                service: service,
                onSaved: { _ in Task { await load() } }
            )
        }
        .confirmationDialog(
            "Remove watched library?",
            isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }),
            titleVisibility: .visible
        ) {
            Button("Remove Configuration", role: .destructive) { Task { await remove() } }
        } message: {
            Text(
                "Prismedia removes this root and its indexed database entities. Media files and folders on disk are not deleted."
            )
        }
        .accessibilityIdentifier("administration.settings.libraries")
    }

    private var canEdit: Bool {
        roots.isReady && (!user.isAdmin || users.isReady)
    }

    private func load() async {
        message = nil
        async let libraries: () = loadRoots()
        async let members: () = loadUsers()
        _ = await (libraries, members)
    }

    private func loadRoots() async {
        let request = roots.begin()
        do {
            let loaded = try await service.roots()
            roots.succeed(loaded, request: request, isCancelled: Task.isCancelled)
        } catch {
            roots.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func loadUsers() async {
        let request = users.begin()
        guard let userService, user.isAdmin else {
            users.succeed([], request: request, isCancelled: Task.isCancelled)
            return
        }
        do {
            let loaded = try await userService.users()
            users.succeed(loaded, request: request, isCancelled: Task.isCancelled)
        } catch {
            users.fail(error, request: request, isCancelled: Task.isCancelled)
        }
    }

    private func toggle(_ root: AdministrativeLibraryRoot) async {
        await mutate(root) {
            AdministrativeLibraryRootMutation(
                path: root.path, label: root.label, enabled: !root.enabled, recursive: root.recursive,
                scanVideos: root.scanVideos, scanImages: root.scanImages, scanAudio: root.scanAudio,
                scanBooks: root.scanBooks, isNsfw: root.isNsfw, autoIdentify: root.autoIdentify
            )
        }
    }

    private func mutate(_ root: AdministrativeLibraryRoot, mutation: () -> AdministrativeLibraryRootMutation) async {
        guard workingID == nil, roots.isReady else { return }
        workingID = root.id
        defer { workingID = nil }
        do {
            _ = try await service.update(id: root.id, mutation: mutation())
            await load()
        } catch { message = error.localizedDescription }
    }

    private func rescan(_ root: AdministrativeLibraryRoot) async {
        guard workingID == nil, roots.isReady else { return }
        workingID = root.id
        defer { workingID = nil }
        do {
            let count = try await service.rescan(id: root.id)
            message = "Queued \(count) scan\(count == 1 ? "" : "s")."
        } catch { message = error.localizedDescription }
    }

    private func remove() async {
        guard let target = deletion, workingID == nil, roots.isReady else { return }
        workingID = target.id
        defer {
            workingID = nil
            deletion = nil
        }
        do {
            try await service.delete(id: target.id)
            await load()
        } catch { message = error.localizedDescription }
    }
}

#if DEBUG
    #Preview("Libraries · Member Access Unavailable") {
        NavigationStack {
            AdministrativeLibrariesView(
                user: PrismediaPreviewData.user,
                service: Step3AdministrationPreviewService(),
                userService: Step3AdministrationPreviewService(usersUnavailable: true)
            )
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("Libraries · Empty") {
        NavigationStack {
            AdministrativeLibrariesView(
                user: PrismediaPreviewData.user,
                service: Step3AdministrationPreviewService(emptyCollections: true),
                userService: Step3AdministrationPreviewService()
            )
        }
    }

    #Preview("Libraries · Content") {
        NavigationStack {
            AdministrativeLibrariesView(
                user: PrismediaPreviewData.user,
                service: Step3AdministrationPreviewService(),
                userService: Step3AdministrationPreviewService()
            )
        }
    }
#endif
