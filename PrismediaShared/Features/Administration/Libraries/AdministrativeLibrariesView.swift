import SwiftUI

struct AdministrativeLibrariesView: View {
    @State private var roots: [AdministrativeLibraryRoot] = []
    @State private var users: [UserAccount] = []
    @State private var isLoading = true
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
            ForEach(roots) { root in
                AdministrativeLibraryRootRow(
                    root: root,
                    isWorking: workingID != nil,
                    onEdit: { editor = AdministrativeLibraryEditorTarget(root: root) },
                    onToggle: { Task { await toggle(root) } },
                    onRescan: { Task { await rescan(root) } },
                    onDelete: { deletion = root }
                )
            }
        }
        .overlay {
            if isLoading && roots.isEmpty {
                PrismediaLoadingView("Loading watched libraries…")
            } else if roots.isEmpty {
                ContentUnavailableView(
                    "No Watched Libraries", systemImage: "folder.badge.plus",
                    description: Text("Add a mounted server folder to begin scanning media."))
            }
        }
        .prismediaScreenBackground()
        .navigationTitle("Watched Libraries")
        .toolbar { Button("Add Library", systemImage: "plus") { editor = AdministrativeLibraryEditorTarget() } }
        .refreshable { await load() }
        .task { await load() }
        .sheet(item: $editor) { target in
            AdministrativeLibraryRootEditor(
                target: target,
                availableUsers: users,
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

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let loadedRoots = service.roots()
            if let userService, user.isAdmin { users = try await userService.users() }
            roots = try await loadedRoots
            message = nil
        } catch { message = error.localizedDescription }
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
        workingID = root.id
        defer { workingID = nil }
        do {
            _ = try await service.update(id: root.id, mutation: mutation())
            await load()
        } catch { message = error.localizedDescription }
    }

    private func rescan(_ root: AdministrativeLibraryRoot) async {
        workingID = root.id
        defer { workingID = nil }
        do {
            let count = try await service.rescan(id: root.id)
            message = "Queued \(count) scan\(count == 1 ? "" : "s")."
        } catch { message = error.localizedDescription }
    }

    private func remove() async {
        guard let target = deletion else { return }
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
