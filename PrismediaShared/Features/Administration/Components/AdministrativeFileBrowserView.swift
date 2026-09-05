import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    struct AdministrativeFileBrowserView: View {
        @State private var listing = AdministrativeCollectionLoadState<AdministrativeFileEntry>()
        @State private var loadedLocation: AdministrativeFileLocation?
        @State private var isBusy = false
        @State private var message: String?
        @State private var notice: String?
        @State private var presentation: AdministrativeFilePresentation?
        @State private var deferredAction: (AdministrativeFileAction, AdministrativeFileEntry)?
        @State private var deleteEntry: AdministrativeFileEntry?
        @State private var exclusionEntry: AdministrativeFileEntry?
        @State private var showsImporter = false
        @State private var importsFolder = false
        @State private var transfer: AdministrativeFileTransferSession?
        @State private var showsTransfer = false

        let location: AdministrativeFileLocation
        let roots: [AdministrativeFileRoot]
        let service: any FileAdministrationServicing
        let openDirectory: @MainActor (AdministrativeFileLocation) -> Void

        var body: some View {
            List {
                if let notice {
                    Label(notice, systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let error = listing.errorMessage {
                    PrismediaRetryView(
                        title: "Couldn't Load Folder", message: error, isRetrying: listing.isLoading,
                        retry: { Task { await load() } })
                }
                ForEach(listing.items) { entry in
                    AdministrativeFileEntryRow(
                        entry: entry, isBusy: isBusy || transfer != nil,
                        open: {
                            if entry.isDirectory {
                                openDirectory(
                                    .init(rootID: entry.rootID, rootLabel: location.rootLabel, path: entry.path))
                            } else {
                                handleAction(.details, entry: entry)
                            }
                        },
                        perform: { handleAction($0, entry: entry) })
                }
            }
            .prismediaScreenBackground()
            .navigationTitle(
                location.path.isEmpty ? location.rootLabel : URL(fileURLWithPath: location.path).lastPathComponent
            )
            .toolbar { toolbarContent }
            .refreshable {
                await PrismediaRefreshAction.perform {
                    await load()
                }
            }
            .overlay {
                if listing.isLoading, listing.items.isEmpty {
                    PrismediaLoadingView("Loading folder…")
                } else if listing.items.isEmpty && listing.errorMessage == nil {
                    ContentUnavailableView(
                        "Empty Folder",
                        systemImage: "folder",
                        description: Text("Upload files or create a folder here."))
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                guard !isBusy, transfer == nil, !urls.isEmpty else { return false }
                beginUpload(urls)
                return true
            }
            .task(id: location) { await load() }
            .sheet(item: $presentation, onDismiss: performDeferredAction) { destination in
                switch destination {
                case .details(let entry):
                    AdministrativeFileDetailView(entry: entry, service: service) {
                        handleAction($0, entry: entry)
                    }
                case .name(let action):
                    AdministrativeFileNameEditor(action: action, location: location, service: service) {
                        Task { await load() }
                    }
                case .move(let entry):
                    AdministrativeFileMoveSheet(entry: entry, roots: roots, service: service) {
                        Task { await load() }
                    }
                }
            }
            .sheet(isPresented: $showsTransfer, onDismiss: finishTransfer) {
                if let transfer { AdministrativeFileTransferView(session: transfer) }
            }
            .fileImporter(
                isPresented: $showsImporter,
                allowedContentTypes: importsFolder ? [.folder] : [.item],
                allowsMultipleSelection: true,
                onCompletion: handleImport
            )
            .alert(
                deleteEntry.map { "Delete \($0.name)?" } ?? "Delete permanently?",
                isPresented: Binding(get: { deleteEntry != nil }, set: { if !$0 { deleteEntry = nil } })
            ) {
                Button("Delete Permanently", role: .destructive) { performDelete() }
                Button("Cancel", role: .cancel) { deleteEntry = nil }
            } message: {
                Text(deleteMessage)
            }
            .confirmationDialog(
                exclusionEntry?.excluded == true ? "Remove scan exclusion?" : "Exclude from library scans?",
                isPresented: Binding(get: { exclusionEntry != nil }, set: { if !$0 { exclusionEntry = nil } })
            ) {
                Button(exclusionEntry?.excluded == true ? "Remove Exclusion" : "Exclude") { performExclusionChange() }
                Button("Cancel", role: .cancel) { exclusionEntry = nil }
            } message: {
                Text("This changes library scan configuration only. It does not move or delete the server file.")
            }
            .alert(
                "Files",
                isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItemGroup(placement: .primaryAction) {
                PrismediaToolbarActionButton("Refresh Folder", systemImage: "arrow.clockwise") { Task { await load() } }
                    .disabled(isBusy || listing.isLoading || transfer != nil)
                fileActionsMenu
                    .prismediaToolbarActionLabelStyle()
            }
        }

        private var fileActionsMenu: some View {
            Menu("File Actions", systemImage: "ellipsis.circle") {
                Button("New Folder", systemImage: "folder.badge.plus") {
                    presentation = .name(.createFolder)
                }
                Button("Upload Files", systemImage: "square.and.arrow.up") {
                    importsFolder = false
                    showsImporter = true
                }
                Button("Upload Folder", systemImage: "folder.badge.plus") {
                    importsFolder = true
                    showsImporter = true
                }
                Divider()
                Button("Download Folder", systemImage: "arrow.down.circle") { beginArchiveDownload() }
                Button("Rescan", systemImage: "arrow.trianglehead.2.clockwise") { performRescan() }
            }
            .disabled(isBusy || transfer != nil || listing.errorMessage != nil)
        }

        private func handleAction(_ action: AdministrativeFileAction, entry: AdministrativeFileEntry) {
            guard !isBusy, transfer == nil else { return }
            if case .details = presentation {
                deferredAction = (action, entry)
                presentation = nil
                return
            }
            switch action {
            case .details: presentation = .details(entry)
            case .rename: presentation = .name(.rename(entry))
            case .move: presentation = .move(entry)
            case .download:
                if entry.isDirectory { beginArchiveDownload(entry) } else { beginFileDownload(entry) }
            case .toggleExclusion: exclusionEntry = entry
            case .delete: deleteEntry = entry
            }
        }

        private func performDeferredAction() {
            guard let (action, entry) = deferredAction else { return }
            deferredAction = nil
            handleAction(action, entry: entry)
        }

        private var deleteMessage: String {
            guard let deleteEntry else { return "This cannot be undone." }
            return deleteEntry.isDirectory
                ? "This permanently deletes \(deleteEntry.name) and everything inside it from the server filesystem. It cannot be recovered here."
                : "This permanently deletes \(deleteEntry.name) from the server filesystem. It cannot be recovered here."
        }

        private func load() async {
            let requestedLocation = location
            let request = listing.begin(clearingItems: loadedLocation != requestedLocation)
            loadedLocation = requestedLocation
            do {
                let response = try await service.children(
                    rootID: requestedLocation.rootID, path: requestedLocation.path)
                listing.succeed(response.entries, request: request, isCancelled: Task.isCancelled)
            } catch {
                listing.fail(error, request: request, isCancelled: Task.isCancelled)
            }
        }

        private func performDelete() {
            guard let entry = deleteEntry else { return }
            deleteEntry = nil
            Task { await runMutation { try await service.delete(rootID: entry.rootID, path: entry.path) } }
        }

        private func performExclusionChange() {
            guard let entry = exclusionEntry else { return }
            exclusionEntry = nil
            Task {
                await runMutation {
                    try await service.setExcluded(!entry.excluded, rootID: entry.rootID, path: entry.path)
                }
            }
        }

        private func performRescan() {
            Task {
                await runMutation {
                    try await service.rescan(rootID: location.rootID, path: location.path)
                }
            }
        }

        private func runMutation(
            _ operation: @escaping @MainActor () async throws -> AdministrativeFileOperationResponse
        ) async {
            guard !isBusy, transfer == nil else { return }
            isBusy = true
            notice = nil
            defer { isBusy = false }
            do {
                let result = try await operation()
                await load()
                notice =
                    result.scansQueued > 0
                    ? "Change complete. \(result.scansQueued) library scan job(s) queued." : "Change complete."
            } catch { message = error.localizedDescription }
        }

        private func handleImport(_ result: Result<[URL], Error>) {
            switch result {
            case .success(let urls): beginUpload(urls)
            case .failure(let error): message = error.localizedDescription
            }
        }

        private func beginUpload(_ urls: [URL]) {
            guard !urls.isEmpty else { return }
            beginTransfer(.upload(urls, location))
        }

        private func beginFileDownload(_ entry: AdministrativeFileEntry) {
            beginTransfer(.download(entry))
        }

        private func beginArchiveDownload(_ entry: AdministrativeFileEntry? = nil) {
            let path = entry?.path ?? location.path
            let name = entry?.name ?? (path.isEmpty ? location.rootLabel : URL(fileURLWithPath: path).lastPathComponent)
            beginTransfer(
                .archive(.init(rootID: location.rootID, rootLabel: location.rootLabel, path: path), name: name))
        }

        private func beginTransfer(_ request: AdministrativeFileTransferRequest) {
            guard !isBusy, transfer == nil else { return }
            notice = nil
            transfer = AdministrativeFileTransferSession(request: request, service: service)
            showsTransfer = true
        }

        private func finishTransfer() {
            guard let finished = transfer else { return }
            Task {
                await finished.close()
                if let cleanupError = finished.cleanupError {
                    message = "Couldn’t remove the temporary download: \(cleanupError)"
                }
                if finished.request.isUpload {
                    await load()
                }
                transfer = nil
            }
        }
    }

    #if DEBUG
        #Preview("File Browser") {
            NavigationStack {
                AdministrativeFileBrowserView(
                    location: .init(rootID: Step4AdministrationPreviewService.rootID, rootLabel: "Movies", path: ""),
                    roots: [
                        .init(
                            id: Step4AdministrationPreviewService.rootID, label: "Movies", path: "/media/movies",
                            enabled: true)
                    ],
                    service: Step4AdministrationPreviewService(),
                    openDirectory: { _ in }
                )
            }
        }
    #endif
#endif
