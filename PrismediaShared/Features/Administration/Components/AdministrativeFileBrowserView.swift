import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    struct AdministrativeFileBrowserView: View {
        @State private var entries: [AdministrativeFileEntry] = []
        @State private var isLoading = true
        @State private var isBusy = false
        @State private var message: String?
        @State private var nameAction: AdministrativeFileNameAction?
        @State private var pendingName = ""
        @State private var moveEntry: AdministrativeFileEntry?
        @State private var deleteEntry: AdministrativeFileEntry?
        @State private var exclusionEntry: AdministrativeFileEntry?
        @State private var selectedEntry: AdministrativeFileEntry?
        @State private var showsInspector = false
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
        let navigatesInPlace: Bool
        let openDirectory: @MainActor (AdministrativeFileLocation) -> Void

        var body: some View {
            List {
                if navigatesInPlace {
                    HStack {
                        if !location.path.isEmpty {
                            Button("Up", systemImage: "chevron.up") { openDirectory(parentLocation) }
                        }
                        Spacer()
                        Button("Refresh", systemImage: "arrow.clockwise") { Task { await load() } }
                            .disabled(isBusy)
                        fileActionsMenu
                    }
                }
                ForEach(entries) { entry in
                    if entry.isDirectory {
                        Button {
                            openDirectory(
                                AdministrativeFileLocation(
                                    rootID: entry.rootID,
                                    rootLabel: location.rootLabel,
                                    path: entry.path
                                ))
                        } label: {
                            rowLabel(entry)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { contextActions(entry) }
                        .accessibilityHint("Opens folder")
                        .accessibilityIdentifier("administration.files.row.\(entry.path)")
                    } else {
                        Button {
                            selectedEntry = entry
                            showsInspector = true
                        } label: {
                            rowLabel(entry)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { contextActions(entry) }
                        .accessibilityHint("Shows file details and actions")
                        .accessibilityIdentifier("administration.files.row.\(entry.path)")
                    }
                }
            }
            .navigationTitle(
                location.path.isEmpty ? location.rootLabel : URL(fileURLWithPath: location.path).lastPathComponent
            )
            .navigationSubtitle(location.path.isEmpty ? "Library root" : location.path)
            .toolbar { toolbarContent }
            .refreshable { await load() }
            .overlay {
                if isLoading, entries.isEmpty {
                    PrismediaLoadingView("Loading folder…")
                } else if entries.isEmpty {
                    ContentUnavailableView(
                        "Empty Folder",
                        systemImage: "folder",
                        description: Text("Upload files or create a folder here."))
                }
            }
            .dropDestination(for: URL.self) { urls, _ in
                beginUpload(urls)
                return !urls.isEmpty
            }
            .task(id: location) { await load() }
            .inspector(isPresented: $showsInspector) {
                if let selectedEntry {
                    AdministrativeFileDetailView(entry: selectedEntry, service: service)
                        .inspectorColumnWidth(min: 260, ideal: 320, max: 440)
                }
            }
            .sheet(item: $moveEntry) { entry in
                AdministrativeFileMoveSheet(entry: entry, roots: roots, service: service) {
                    Task { await load() }
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
                nameAction?.title ?? "File Name",
                isPresented: Binding(get: { nameAction != nil }, set: { if !$0 { nameAction = nil } })
            ) {
                TextField("Name", text: $pendingName)
                Button(nameAction?.confirmLabel ?? "Save") { applyNameAction() }
                Button("Cancel", role: .cancel) { nameAction = nil }
            } message: {
                Text("Names cannot contain slashes and must stay inside the selected library root.")
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

        private func rowLabel(_ entry: AdministrativeFileEntry) -> some View {
            Label {
                HStack {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text(entry.name)
                        HStack(spacing: PrismediaSpacing.small) {
                            if let size = entry.sizeBytes {
                                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            }
                            if let modifiedAt = entry.modifiedAt {
                                Text(modifiedAt, style: .date)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if entry.excluded {
                        Label("Excluded", systemImage: "eye.slash")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(PrismediaColor.warning)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            } icon: {
                Image(systemName: entry.isDirectory ? "folder.fill" : "doc")
            }
            .accessibilityValue(entry.excluded ? "Excluded from scans" : "Included in scans")
        }

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") { Task { await load() } }
                    .disabled(isBusy)
                fileActionsMenu
            }
        }

        private var fileActionsMenu: some View {
            Menu("File Actions", systemImage: "ellipsis.circle") {
                Button("New Folder", systemImage: "folder.badge.plus") {
                    nameAction = .createFolder
                    pendingName = ""
                }
                Button("Upload Files", systemImage: "square.and.arrow.up") { showsFileImporter = true }
                Button("Upload Folder", systemImage: "folder.badge.plus") { showsFolderImporter = true }
                Divider()
                Button("Download Folder", systemImage: "arrow.down.circle") { beginArchiveDownload() }
                Button("Rescan", systemImage: "arrow.trianglehead.2.clockwise") { performRescan() }
            }
            .disabled(isBusy)
        }

        private var parentLocation: AdministrativeFileLocation {
            let parentPath = location.path.split(separator: "/").dropLast().joined(separator: "/")
            return AdministrativeFileLocation(
                rootID: location.rootID,
                rootLabel: location.rootLabel,
                path: parentPath
            )
        }

        @ViewBuilder
        private func contextActions(_ entry: AdministrativeFileEntry) -> some View {
            if entry.isDirectory {
                Button("Download", systemImage: "arrow.down.circle") { beginArchiveDownload(entry) }
            } else {
                Button("Download", systemImage: "arrow.down.circle") { beginFileDownload(entry) }
            }
            Button("Rename", systemImage: "pencil") {
                nameAction = .rename(entry)
                pendingName = entry.name
            }
            Button("Move", systemImage: "folder") { moveEntry = entry }
            Button(entry.excluded ? "Remove Exclusion" : "Exclude", systemImage: entry.excluded ? "eye" : "eye.slash") {
                exclusionEntry = entry
            }
            Divider()
            Button("Delete Permanently", systemImage: "trash", role: .destructive) { deleteEntry = entry }
        }

        private var deleteMessage: String {
            guard let deleteEntry else { return "This cannot be undone." }
            return deleteEntry.isDirectory
                ? "This permanently deletes \(deleteEntry.name) and everything inside it from the server filesystem. It cannot be recovered here."
                : "This permanently deletes \(deleteEntry.name) from the server filesystem. It cannot be recovered here."
        }

        private func load() async {
            isLoading = true
            defer { isLoading = false }
            do { entries = try await service.children(rootID: location.rootID, path: location.path).entries } catch {
                message = error.localizedDescription
            }
        }

        private func applyNameAction() {
            guard let action = nameAction else { return }
            nameAction = nil
            Task {
                await runMutation {
                    switch action {
                    case .createFolder:
                        return try await service.createFolder(
                            rootID: location.rootID,
                            parentPath: location.path,
                            name: pendingName
                        )
                    case .rename(let entry):
                        return try await service.rename(rootID: entry.rootID, path: entry.path, name: pendingName)
                    }
                }
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
            isBusy = true
            defer { isBusy = false }
            do {
                let result = try await operation()
                await load()
                message =
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
                    navigatesInPlace: false,
                    openDirectory: { _ in }
                )
            }
        }
    #endif
#endif
