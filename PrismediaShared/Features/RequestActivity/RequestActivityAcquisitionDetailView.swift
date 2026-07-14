import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    struct RequestActivityAcquisitionDetailView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var detail: RequestActivityAcquisitionDetail?
        @State private var transfer: RequestActivityTransfer?
        @State private var files: RequestActivityFiles?
        @State private var blocklist: [RequestActivityBlocklistEntry] = []
        @State private var isLoading = true
        @State private var isActing = false
        @State private var errorMessage: String?
        @State private var isImportingTorrent = false

        let acquisitionID: UUID
        let service: any RequestActivityServicing

        var body: some View {
            NavigationStack {
                List {
                    if let summary = detail?.summary {
                        summarySection(summary)
                        transferSection
                        filesSection
                        blocklistSection
                        candidatesSection
                    }
                }
                .prismediaScreenBackground()
                .overlay { overlayContent }
                .navigationTitle(detail?.summary.title ?? "Acquisition")
                .toolbar { toolbarContent }
                .refreshable { await load() }
                .fileImporter(
                    isPresented: $isImportingTorrent,
                    allowedContentTypes: [UTType(filenameExtension: "torrent") ?? .data],
                    allowsMultipleSelection: false,
                    onCompletion: importTorrent
                )
                .task {
                    await load()
                    await pollWhileActive()
                }
                .alert(
                    "Acquisition Action Failed",
                    isPresented: errorPresented
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "Unknown error")
                }
            }
        }

        private func summarySection(_ summary: RequestActivityAcquisitionSummary) -> some View {
            Section("Status") {
                LabeledContent("State") {
                    Label(
                        RequestActivityStatusPolicy.label(for: summary.status),
                        systemImage: RequestActivityStatusPolicy.systemImage(for: summary.status)
                    )
                    .foregroundStyle(RequestActivityStatusPolicy.tone(for: summary.status).foregroundStyle)
                }
                if let message = summary.statusMessage { Text(message) }
                if let progress = summary.progress {
                    ProgressView(value: min(max(progress, 0), 1)) {
                        Text("Progress")
                    } currentValueLabel: {
                        Text(progress, format: .percent.precision(.fractionLength(0)))
                    }
                }
                if let description = summary.description { Text(description) }
            }
        }

        @ViewBuilder
        private var transferSection: some View {
            if let transfer {
                Section("Transfer") {
                    if let state = transfer.state { LabeledContent("State", value: state) }
                    LabeledContent(
                        "Downloaded",
                        value:
                            "\(RequestActivityFormatting.bytes(Int64(Double(transfer.totalSizeBytes) * transfer.progress))) / \(RequestActivityFormatting.bytes(transfer.totalSizeBytes))"
                    )
                    LabeledContent(
                        "Speed", value: RequestActivityFormatting.speed(transfer.downloadSpeedBytesPerSecond))
                    LabeledContent("ETA", value: RequestActivityFormatting.eta(transfer.etaSeconds))
                    LabeledContent("Peers", value: "\(transfer.seeds) seeds · \(transfer.peers) peers")
                    if let savePath = transfer.savePath {
                        LabeledContent("Path", value: savePath)
                    }
                }
            }
        }

        @ViewBuilder
        private var filesSection: some View {
            if let files {
                Section(files.imported ? "Imported Files" : "Files") {
                    if files.files.isEmpty {
                        Text("No files reported yet.")
                            .foregroundStyle(PrismediaColor.textSecondary)
                    } else {
                        ForEach(files.files, id: \.name) { file in
                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                                Text(file.name)
                                ProgressView(value: min(max(file.progress, 0), 1))
                                Text(RequestActivityFormatting.bytes(file.sizeBytes))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(PrismediaColor.textSecondary)
                            }
                        }
                    }
                }
            }
        }

        @ViewBuilder
        private var blocklistSection: some View {
            if !blocklist.isEmpty {
                Section("Blocklist") {
                    ForEach(blocklist) { entry in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(entry.title ?? entry.infoHash ?? "Blocked Release")
                                .font(.headline)
                            Text(entry.reason.rawValue.replacingOccurrences(of: "-", with: " ").capitalized)
                                .font(.caption)
                                .foregroundStyle(PrismediaColor.textSecondary)
                            if let message = entry.message {
                                Text(message)
                                    .font(.caption)
                                    .foregroundStyle(PrismediaColor.textMuted)
                            }
                            PrismediaButton(
                                "Allow This Release Again",
                                systemImage: "arrow.uturn.backward",
                                surface: .embedded
                            ) {
                                Task { await removeBlocklistEntry(entry) }
                            }
                            .controlSize(.small)
                            .disabled(isActing)
                        }
                    }
                }
            }
        }

        @ViewBuilder
        private var candidatesSection: some View {
            if let detail {
                Section("Release Candidates") {
                    if detail.candidates.isEmpty {
                        ContentUnavailableView(
                            "No Candidates",
                            systemImage: "magnifyingglass",
                            description: Text("Search again or import a torrent file manually.")
                        )
                    } else {
                        ForEach(detail.candidates) { candidate in
                            RequestActivityCandidateRow(
                                candidate: candidate,
                                isDisabled: isActing
                                    || RequestActivityStatusPolicy.isTransitionLocked(detail.summary.status),
                                onQueue: { target in Task { await queue(target) } },
                                onBlocklist: { target in Task { await blocklist(target) } }
                            )
                        }
                    }
                }
            }
        }

        @ViewBuilder
        private var overlayContent: some View {
            if isLoading && detail == nil {
                PrismediaLoadingView("Loading acquisition…")
            } else if detail == nil, let errorMessage {
                ContentUnavailableView(
                    "Unable to Load Acquisition",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            }
        }

        @ToolbarContentBuilder
        private var toolbarContent: some ToolbarContent {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done", action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .primaryAction) {
                Menu("Actions", systemImage: "ellipsis.circle") {
                    Button("Search Again", systemImage: "arrow.clockwise") {
                        Task { await research() }
                    }
                    Button("Import Torrent", systemImage: "doc.badge.plus") {
                        isImportingTorrent = true
                    }
                    Button("Retry Import", systemImage: "arrow.down.doc") {
                        Task { await retryImport(allowFormatChange: false) }
                    }
                    Button("Retry and Allow Format Change", systemImage: "arrow.trianglehead.2.clockwise") {
                        Task { await retryImport(allowFormatChange: true) }
                    }
                    Divider()
                    Button("Cancel Acquisition", systemImage: "xmark.circle", role: .destructive) {
                        Task { await cancel() }
                    }
                }
                .disabled(
                    isActing || detail.map { RequestActivityStatusPolicy.isTransitionLocked($0.summary.status) } == true
                )
            }
        }

        private var errorPresented: Binding<Bool> {
            Binding(
                get: { errorMessage != nil && detail != nil },
                set: { presented in if !presented { errorMessage = nil } }
            )
        }

        private func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                detail = try await service.fetchRequestActivityAcquisition(id: acquisitionID)
                transfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                files = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                errorMessage = nil
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private func pollWhileActive() async {
            while detail.map({ RequestActivityStatusPolicy.shouldPoll($0.summary.status) }) == true {
                do { try await Task.sleep(for: .seconds(4)) } catch { return }
                guard !Task.isCancelled else { return }
                await load()
            }
        }

        private func research() async {
            await mutate { try await service.researchRequestActivityAcquisition(id: acquisitionID) }
        }

        private func retryImport(allowFormatChange: Bool) async {
            await mutate {
                try await service.retryRequestActivityImport(
                    id: acquisitionID,
                    allowFormatChange: allowFormatChange
                )
            }
        }

        private func cancel() async {
            await mutate { try await service.cancelRequestActivityAcquisition(id: acquisitionID) }
        }

        private func queue(_ candidate: RequestActivityReleaseCandidate) async {
            await mutate {
                try await service.queueRequestActivityRelease(
                    acquisitionID: acquisitionID,
                    candidateID: candidate.id
                )
            }
        }

        private func blocklist(_ candidate: RequestActivityReleaseCandidate) async {
            await mutate {
                try await service.blocklistRequestActivityCandidate(
                    acquisitionID: acquisitionID,
                    candidateID: candidate.id
                )
            }
        }

        private func removeBlocklistEntry(_ entry: RequestActivityBlocklistEntry) async {
            guard !isActing else { return }
            isActing = true
            defer { isActing = false }
            do {
                try await service.removeRequestActivityBlocklistEntry(id: entry.id)
                blocklist.removeAll { $0.id == entry.id }
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private func importTorrent(_ result: Result<[URL], any Error>) {
            Task {
                do {
                    guard let url = try result.get().first else {
                        throw RequestActivityFileImportError.noFileSelected
                    }
                    let targetAcquisitionID = acquisitionID
                    let upload = try await Task.detached {
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                        return RequestActivityManualTorrentUpload(
                            acquisitionID: targetAcquisitionID,
                            fileName: url.lastPathComponent,
                            data: try Data(contentsOf: url)
                        )
                    }.value
                    await mutate { try await service.uploadRequestActivityTorrent(upload) }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }

        private func mutate(
            _ operation: () async throws -> RequestActivityAcquisitionDetail
        ) async {
            guard !isActing else { return }
            isActing = true
            defer { isActing = false }
            do {
                detail = try await operation()
                transfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                files = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    #if DEBUG
        #Preview("Request Activity Acquisition") {
            RequestActivityAcquisitionDetailView(
                acquisitionID: RequestActivityPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .content)
            )
        }
    #endif
#endif
