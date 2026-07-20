import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    /// The acquisition-specific management surface: status, live transfer, files,
    /// release review, torrent upload, retry-import, and cancel. One state machine with
    /// two render styles — the request-activity sheet's original `List` chrome and the
    /// web-parity stacked layout embedded in the entity detail acquisition panel.
    /// Entity monitoring stays in the owning panel so a stable entity monitor is never
    /// duplicated by an acquisition-scoped control.
    struct RequestActivityAcquisitionManagementSections: View {
        @State private var detail: RequestActivityAcquisitionDetail?
        @State private var transfer: RequestActivityTransfer?
        @State private var files: RequestActivityFiles?
        @State private var blocklist: [RequestActivityBlocklistEntry] = []
        @State private var isLoading = true
        @State private var isActing = false
        @State private var errorMessage: String?
        @State private var isImportingTorrent = false
        @State private var confirmsStartOver = false
        @State private var lastObservedStatus: AcquisitionStatus?
        @State private var importedNotificationSent = false

        let acquisitionID: UUID
        let service: any RequestActivityServicing
        let style: RequestActivityAcquisitionManagementStyle
        let onCancelled: (@MainActor () async -> Void)?
        let onImported: (@MainActor () async -> Void)?
        let onReset: (@MainActor () async -> Void)?

        init(
            acquisitionID: UUID,
            service: any RequestActivityServicing,
            style: RequestActivityAcquisitionManagementStyle,
            onCancelled: (@MainActor () async -> Void)? = nil,
            onImported: (@MainActor () async -> Void)? = nil,
            onReset: (@MainActor () async -> Void)? = nil
        ) {
            self.acquisitionID = acquisitionID
            self.service = service
            self.style = style
            self.onCancelled = onCancelled
            self.onImported = onImported
            self.onReset = onReset
        }

        var body: some View {
            Group {
                switch style {
                case .list:
                    listStyleContent
                case .embedded:
                    embeddedContent
                }
            }
            .fileImporter(
                isPresented: $isImportingTorrent,
                allowedContentTypes: [UTType(filenameExtension: "torrent") ?? .data],
                allowsMultipleSelection: false,
                onCompletion: importTorrent
            )
            .task(id: acquisitionID) {
                await load()
                await pollWhileActive()
            }
            .confirmationDialog(
                "Start this acquisition over?",
                isPresented: $confirmsStartOver,
                titleVisibility: .visible
            ) {
                Button("Start over", role: .destructive) {
                    Task { await startOver() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This permanently deletes every file owned by the interrupted import, removes any remaining download data it can reach, clears the partial state, and starts a clean search for the still-wanted item."
                )
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

        // MARK: - Sheet (list) style

        private var listStyleContent: some View {
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
            .toolbar { listToolbarContent }
            .refreshable { await load() }
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
                                systemImage: "arrow.uturn.backward"
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
        private var listToolbarContent: some ToolbarContent {
            ToolbarItem(placement: .primaryAction) {
                Menu {
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
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Acquisition Actions")
                .disabled(
                    isActing || detail.map { RequestActivityStatusPolicy.isTransitionLocked($0.summary.status) } == true
                )
            }
        }

        // MARK: - Embedded (web-parity) style

        @ViewBuilder
        private var embeddedContent: some View {
            if let detail {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    embeddedStatusHeader(detail)
                    embeddedBody(detail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if isLoading {
                HStack(spacing: PrismediaSpacing.medium) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading acquisition…")
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let errorMessage {
                RequestActivityStatePlaceholder(
                    title: "Unable to load acquisition",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle"
                )
            }
        }

        private func embeddedStatusHeader(_ detail: RequestActivityAcquisitionDetail) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
                    Label(
                        RequestActivityStatusPolicy.label(for: detail.summary.status),
                        systemImage: RequestActivityStatusPolicy.systemImage(for: detail.summary.status)
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        RequestActivityStatusPolicy.tone(for: detail.summary.status).foregroundStyle
                    )
                    if let message = detail.summary.statusMessage, !message.isEmpty {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                    }
                }

                if hasEmbeddedActions(detail) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PrismediaSpacing.medium) { embeddedActions(detail) }
                        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                            embeddedActions(detail)
                        }
                    }
                    .controlSize(.small)
                }
            }
        }

        private func hasEmbeddedActions(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            let status = detail.summary.status
            return canRetryImport(detail) || canStartOver(detail) || canReSearch(detail)
                || canCancel(status) || status.rawValue == "awaiting-selection"
        }

        @ViewBuilder
        private func embeddedActions(_ detail: RequestActivityAcquisitionDetail) -> some View {
            let status = detail.summary.status
            if canRetryImport(detail) {
                PrismediaButton(
                    status.rawValue == "manual-import-required" ? "Import anyway" : "Retry import",
                    systemImage: "arrow.down.doc",
                    variant: .prominent
                ) {
                    Task {
                        await retryImport(allowFormatChange: status.rawValue == "manual-import-required")
                    }
                }
                .disabled(isActing)
            }
            if canStartOver(detail) {
                PrismediaButton(
                    "Start over",
                    systemImage: "arrow.counterclockwise",
                    variant: .destructive
                ) {
                    confirmsStartOver = true
                }
                .disabled(isActing)
            }
            if canReSearch(detail) {
                PrismediaButton("Search again", systemImage: "arrow.clockwise") {
                    Task { await research() }
                }
                .disabled(isActing)
            }
            if canCancel(status) || status.rawValue == "awaiting-selection" {
                PrismediaButton("Cancel", systemImage: "xmark", variant: .destructive) {
                    Task { await cancel() }
                }
                .disabled(isActing)
            }
        }

        @ViewBuilder
        private func embeddedBody(_ detail: RequestActivityAcquisitionDetail) -> some View {
            let status = detail.summary.status
            if RequestActivityStatusPolicy.isTransitionLocked(status) {
                RequestActivityStatePlaceholder(
                    title: status.rawValue == "stopping"
                        ? "Cleaning up acquisition"
                        : "Updating acquisition",
                    message: status.rawValue == "stopping"
                        ? "Removing the download and managed files. Actions will return when cleanup finishes."
                        : "Prismedia is finishing a newer lifecycle transition. Actions are temporarily unavailable.",
                    systemImage: "arrow.trianglehead.2.clockwise.rotate.90",
                    isBusy: true
                )
            } else if status.rawValue == "searching" || status.rawValue == "pending" {
                RequestActivityStatePlaceholder(
                    title: "Searching indexers",
                    message: "Querying your configured indexers for matching releases. This can take a moment.",
                    systemImage: "magnifyingglass",
                    isBusy: true
                )
            } else if isDownloading(status) {
                RequestActivityDownloadSection(transfer: transfer)
            } else if isDone(status) {
                RequestActivityFilesSection(
                    files: files,
                    isActive: RequestActivityStatusPolicy.shouldPoll(status)
                )
            } else {
                RequestActivityReleasesSection(
                    candidates: detail.candidates,
                    canPickRelease: canPickRelease(detail),
                    isBusy: isActing,
                    onQueue: { target in Task { await queue(target) } },
                    onBlocklist: { target in Task { await blocklist(target) } },
                    onUploadTorrent: { isImportingTorrent = true }
                )
            }
        }

        // MARK: - Status gates (web parity)

        private func canRetryImport(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            let status = detail.summary.status.rawValue
            return status == "manual-import-required"
                || (status == "failed" && detail.summary.hasResumableImport)
        }

        private func canStartOver(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            detail.summary.hasResumableImport && detail.summary.status.rawValue != "stopping"
        }

        private func canReSearch(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            let status = detail.summary.status.rawValue
            return status == "awaiting-selection"
                || (status == "failed" && !detail.summary.hasResumableImport)
                || status == "manual-import-required"
        }

        private func canCancel(_ status: AcquisitionStatus) -> Bool {
            RequestActivityStatusPolicy.shouldPoll(status)
                && !RequestActivityStatusPolicy.isTransitionLocked(status)
        }

        private func canPickRelease(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            let status = detail.summary.status.rawValue
            return status == "awaiting-selection"
                || (status == "failed" && !detail.summary.hasResumableImport)
                || status == "cancelled"
                || status == "manual-import-required"
        }

        private func isDownloading(_ status: AcquisitionStatus) -> Bool {
            status.rawValue == "queued" || status.rawValue == "downloading"
        }

        private func isDone(_ status: AcquisitionStatus) -> Bool {
            ["downloaded", "importing", "imported"].contains(status.rawValue)
        }

        // MARK: - Loading and actions

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
                let nextDetail = try await service.fetchRequestActivityAcquisition(id: acquisitionID)
                detail = nextDetail
                transfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                files = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                errorMessage = nil
                await observeStatusTransition(nextDetail.summary.status)
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

        /// Calls the owner once when live status observes this acquisition cross from an
        /// active status into Imported, so an entity page can refresh in place.
        private func observeStatusTransition(_ nextStatus: AcquisitionStatus) async {
            let previousStatus = lastObservedStatus
            lastObservedStatus = nextStatus
            guard !importedNotificationSent, nextStatus.rawValue == "imported" else { return }
            guard let previousStatus, RequestActivityStatusPolicy.shouldPoll(previousStatus),
                RequestActivityStatusPolicy.isKnown(previousStatus)
            else { return }
            importedNotificationSent = true
            await onImported?()
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
            if errorMessage == nil {
                await onCancelled?()
            }
        }

        private func startOver() async {
            guard !isActing else { return }
            isActing = true
            defer { isActing = false }
            do {
                try await service.removeRequestActivityAcquisition(id: acquisitionID)
                detail = nil
                transfer = nil
                files = nil
                errorMessage = nil
                await onReset?()
            } catch {
                errorMessage = error.localizedDescription
            }
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
                let nextDetail = try await operation()
                detail = nextDetail
                transfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                files = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                errorMessage = nil
                await observeStatusTransition(nextDetail.summary.status)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    #if DEBUG
        #Preview("Management Sections · Embedded") {
            ScrollView {
                RequestActivityAcquisitionManagementSections(
                    acquisitionID: RequestActivityPreviewFixtures.acquisitionID,
                    service: PreviewRequestActivityService(scenario: .releases),
                    style: .embedded
                )
                .padding()
            }
        }
    #endif
#endif
