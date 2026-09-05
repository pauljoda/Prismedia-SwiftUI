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
        @State private var showsFileImporter = false
        @State private var showsFolderImporter = false
        @State private var transferTitle = ""
        @State private var transferDetail = ""
        @State private var transferProgress: Double?
        @State private var showsTransfer = false
        @State private var transferTask: Task<Void, Never>?
        @State private var exportDocument: AdministrativeFileExportDocument?
        @State private var exportFileName = "download"
        @State private var showsExporter = false

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
                        entry: entry, isBusy: isBusy || transferTask != nil,
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
                guard !isBusy, transferTask == nil, !urls.isEmpty else { return false }
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
            .sheet(isPresented: $showsTransfer) {
                AdministrativeFileTransferStatusView(
                    title: transferTitle,
                    detail: transferDetail,
                    progress: transferProgress,
                    cancel: { transferTask?.cancel() }
                )
                .interactiveDismissDisabled(transferTask != nil)
            }
            .fileImporter(
                isPresented: $showsFileImporter,
                allowedContentTypes: [.data, .item],
                allowsMultipleSelection: true,
                onCompletion: handleImport
            )
            .fileImporter(
                isPresented: $showsFolderImporter,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: true,
                onCompletion: handleImport
            )
            .fileExporter(
                isPresented: $showsExporter,
                document: exportDocument,
                contentType: .data,
                defaultFilename: exportFileName
            ) { result in
                if case .failure(let error) = result { message = error.localizedDescription }
                exportDocument = nil
            }
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
                    .disabled(isBusy || listing.isLoading || transferTask != nil)
                fileActionsMenu
                    .prismediaToolbarActionLabelStyle()
            }
        }

        private var fileActionsMenu: some View {
            Menu("File Actions", systemImage: "ellipsis.circle") {
                Button("New Folder", systemImage: "folder.badge.plus") {
                    presentation = .name(.createFolder)
                }
                Button("Upload Files", systemImage: "square.and.arrow.up") { showsFileImporter = true }
                Button("Upload Folder", systemImage: "folder.badge.plus") { showsFolderImporter = true }
                Divider()
                Button("Download Folder", systemImage: "arrow.down.circle") { beginArchiveDownload() }
                Button("Rescan", systemImage: "arrow.trianglehead.2.clockwise") { performRescan() }
            }
            .disabled(isBusy || transferTask != nil || listing.errorMessage != nil)
        }

        private func handleAction(_ action: AdministrativeFileAction, entry: AdministrativeFileEntry) {
            guard !isBusy, transferTask == nil else { return }
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
            guard !isBusy, transferTask == nil else { return }
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
            guard !urls.isEmpty, !isBusy, transferTask == nil else { return }
            showsTransfer = true
            transferTitle = "Preparing Upload"
            transferDetail = "Reading selected files…"
            transferProgress = nil
            transferTask = Task {
                do {
                    let collector = AdministrativeUploadItemCollector()
                    let items = try await Task.detached { try collector.collect(urls) }.value
                    let result = await FileUploadUseCase(service: service).upload(
                        items,
                        rootID: location.rootID,
                        targetPath: location.path
                    ) { progress in
                        transferTitle = "Uploading Files"
                        transferDetail = progress.currentPath ?? "Finishing upload…"
                        transferProgress = progress.fraction
                    }
                    transferTask = nil
                    showsTransfer = false
                    await load()
                    let success = "Uploaded \(result.successfulPaths.count) of \(items.count) files."
                    if result.failures.isEmpty {
                        message = success
                    } else {
                        message =
                            "\(success) \(result.failures.count) failed; successful files were preserved. \(result.failures.first?.message ?? "")"
                    }
                } catch is CancellationError {
                    transferTask = nil
                    showsTransfer = false
                    await load()
                    message = "Upload cancelled. Files already uploaded remain on the server."
                } catch {
                    transferTask = nil
                    showsTransfer = false
                    message = error.localizedDescription
                }
            }
        }

        private func beginFileDownload(_ entry: AdministrativeFileEntry) {
            guard !isBusy, transferTask == nil else { return }
            showsTransfer = true
            transferTitle = "Downloading \(entry.name)"
            transferDetail = "Receiving an authenticated server transfer…"
            transferProgress = nil
            transferTask = Task {
                do {
                    let downloaded = try await service.downloadFile(rootID: entry.rootID, path: entry.path)
                    try presentExport(downloaded)
                } catch is CancellationError {
                    message = "Download cancelled."
                } catch { message = error.localizedDescription }
                transferTask = nil
                showsTransfer = false
            }
        }

        private func beginArchiveDownload(_ entry: AdministrativeFileEntry? = nil) {
            guard !isBusy, transferTask == nil else { return }
            let path = entry?.path ?? location.path
            let name =
                entry?.name
                ?? (location.path.isEmpty ? location.rootLabel : URL(fileURLWithPath: path).lastPathComponent)
            showsTransfer = true
            transferTitle = "Preparing \(name).zip"
            transferDetail = "Collecting visible files…"
            transferProgress = nil
            transferTask = Task {
                do {
                    let downloaded = try await FileArchiveDownloadUseCase(service: service).prepareAndDownload(
                        rootID: location.rootID,
                        path: path
                    ) { preparation in
                        transferTitle = preparation.ready ? "Archive Ready" : "Compressing Folder"
                        transferDetail = "\(preparation.processedFiles) of \(preparation.totalFiles) files"
                        transferProgress = Double(preparation.progressPercent) / 100
                    }
                    try presentExport(downloaded)
                } catch is CancellationError {
                    message = "Archive preparation cancelled. Its temporary server result will expire automatically."
                } catch { message = error.localizedDescription }
                transferTask = nil
                showsTransfer = false
            }
        }

        private func presentExport(_ downloaded: AdministrativeDownloadedFile) throws {
            exportDocument = try AdministrativeFileExportDocument(sourceURL: downloaded.localURL)
            exportFileName = downloaded.suggestedFileName
            showsExporter = true
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
