import SwiftUI
import UniformTypeIdentifiers

#if canImport(Accessibility)
    import Accessibility
#endif

#if os(iOS) || os(macOS)
    /// The acquisition-specific management surface: status, live transfer, files,
    /// release review, torrent upload, retry-import, and cancel. One state machine with
    /// two render styles — the request-activity sheet's original `List` chrome and the
    /// web-parity stacked layout embedded in the entity detail acquisition panel.
    /// Entity monitoring stays in the owning panel so a stable entity monitor is never
    /// duplicated by an acquisition-scoped control.
    struct RequestActivityAcquisitionManagementSections: View {
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @State private var detail: RequestActivityAcquisitionDetail?
        @State private var transfer: RequestActivityTransfer?
        @State private var transferLoadState: RequestActivityTransferLoadState = .preparing
        @State private var filesLoadState = RequestActivityFilesLoadState.initialLoading
        @State private var blocklist: [RequestActivityBlocklistEntry] = []
        @State private var isLoading = true
        @State private var isActing = false
        @State private var loadErrorMessage: String?
        @State private var actionErrorMessage: String?
        @State private var refreshState = RequestActivityAcquisitionRefreshState()
        @State private var activeLifecycleAction: RequestActivityAcquisitionAction?
        @State private var failedLifecycleAction: RequestActivityAcquisitionAction?
        @State private var activeCandidateAction: RequestActivityCandidateAction?
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
        #if DEBUG
            private var disablesLiveLoadingForPreview = false
        #endif

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

        #if DEBUG
            init(
                acquisitionID: UUID,
                service: any RequestActivityServicing,
                style: RequestActivityAcquisitionManagementStyle = .embedded,
                previewDetail: RequestActivityAcquisitionDetail? = nil,
                previewTransfer: RequestActivityTransfer? = nil,
                previewTransferLoadState: RequestActivityTransferLoadState? = nil,
                previewFiles: RequestActivityFiles? = nil,
                previewFilesLoadState: RequestActivityFilesLoadState? = nil,
                isLoading: Bool = false,
                loadErrorMessage: String? = nil,
                isActing: Bool = false,
                actionErrorMessage: String? = nil,
                refreshMessage: String? = nil,
                activeLifecycleAction: RequestActivityAcquisitionAction? = nil,
                failedLifecycleAction: RequestActivityAcquisitionAction? = nil,
                activeCandidateAction: RequestActivityCandidateAction? = nil,
                confirmsStartOver: Bool = false
            ) {
                self.init(
                    acquisitionID: acquisitionID,
                    service: service,
                    style: style
                )
                _detail = State(initialValue: previewDetail)
                _transfer = State(initialValue: previewTransfer)
                _transferLoadState = State(
                    initialValue: previewTransferLoadState
                        ?? (previewTransfer == nil ? .preparing : .current)
                )
                _filesLoadState = State(
                    initialValue: previewFilesLoadState
                        ?? previewFiles.map(RequestActivityFilesLoadState.loaded)
                        ?? .initialLoading
                )
                _isLoading = State(initialValue: isLoading)
                _loadErrorMessage = State(initialValue: loadErrorMessage)
                _isActing = State(initialValue: isActing)
                _actionErrorMessage = State(initialValue: actionErrorMessage)
                _refreshState = State(
                    initialValue: RequestActivityAcquisitionRefreshState(
                        previewMessage: refreshMessage
                    )
                )
                _activeLifecycleAction = State(initialValue: activeLifecycleAction)
                _failedLifecycleAction = State(initialValue: failedLifecycleAction)
                _activeCandidateAction = State(initialValue: activeCandidateAction)
                _confirmsStartOver = State(initialValue: confirmsStartOver)
                disablesLiveLoadingForPreview = true
            }
        #endif

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
            .task(id: liveRefreshTaskIdentity) {
                #if DEBUG
                    guard !disablesLiveLoadingForPreview else { return }
                #endif
                guard liveRefreshIsActive else { return }
                await load(showSpinner: detail == nil)
                await pollWhileVisible()
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
                    "Interrupted files and remaining download data will be removed, then Prismedia will begin a clean search."
                )
            }
        }

        // MARK: - Sheet (list) style

        private var listStyleContent: some View {
            List {
                if let detail {
                    summarySection(detail.summary)
                    if hasLifecycleMessage {
                        Section { lifecycleMessages }
                    }
                    listDownstreamSections(detail)
                }
            }
            .prismediaScreenBackground()
            .overlay { overlayContent }
            .navigationTitle(detail?.summary.title ?? "Acquisition")
            .toolbar { listToolbarContent }
            .refreshable { await load(showSpinner: detail == nil) }
        }

        private func summarySection(_ summary: RequestActivityAcquisitionSummary) -> some View {
            Section("Status") {
                LabeledContent("State") {
                    Label(
                        RequestActivityAcquisitionLifecyclePolicy.label(for: summary.status),
                        systemImage: RequestActivityStatusPolicy.systemImage(for: summary.status)
                    )
                    .foregroundStyle(RequestActivityStatusPolicy.tone(for: summary.status).foregroundStyle)
                }
                if let description = RequestActivityAcquisitionLifecyclePolicy.description(
                    for: summary.status,
                    message: summary.statusMessage
                ) {
                    Text(description)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                LabeledContent("Updated") {
                    Text(summary.updatedAt, style: .relative)
                        .monospacedDigit()
                }
                if [.preparingSearch, .searching].contains(
                    RequestActivityAcquisitionLifecyclePolicy.content(for: summary.status)
                ) {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(
                            RequestActivityAcquisitionLifecyclePolicy.label(for: summary.status)
                        )
                }
            }
        }

        @ViewBuilder
        private func listDownstreamSections(_ detail: RequestActivityAcquisitionDetail) -> some View {
            if canPickRelease(detail) {
                blocklistSection
                candidatesSection(detail)
            } else {
                switch RequestActivityAcquisitionLifecyclePolicy.content(for: detail.summary.status) {
                case .download:
                    transferSection
                    filesSection
                case .files:
                    filesSection
                case .releases, .preparingSearch, .searching, .lifecycleOnly, .locked:
                    EmptyView()
                }
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
            Section {
                RequestActivityFilesSection(
                    loadState: filesLoadState,
                    retry: {
                        Task {
                            guard let status = detail?.summary.status else { return }
                            await refreshFiles(for: status, isInitial: filesLoadState.files == nil)
                        }
                    }
                )
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
                            .prismediaCompactActionControlSize()
                            .disabled(isActing)
                        }
                    }
                }
            }
        }

        private func candidatesSection(_ detail: RequestActivityAcquisitionDetail) -> some View {
            Section {
                RequestActivityReleasesSection(
                    candidates: detail.candidates,
                    canPickRelease: canPickRelease(detail),
                    isBusy: isActing,
                    activeAction: activeCandidateAction,
                    showsTorrentFallback: false,
                    onDownload: { target in Task { await queue(target) } },
                    onBlocklist: { target in Task { await blocklist(target) } },
                    onUploadTorrent: {}
                )
            }
        }

        @ViewBuilder
        private var overlayContent: some View {
            if isLoading && detail == nil {
                PrismediaLoadingView("Loading acquisition…")
            } else if detail == nil, let loadErrorMessage {
                RequestActivityLifecycleMessage(
                    title: "Unable to Load Acquisition",
                    message: loadErrorMessage,
                    retryTitle: "Try Again",
                    onRetry: { Task { await load(showSpinner: true) } }
                )
                .padding()
            }
        }

        @ToolbarContentBuilder
        private var listToolbarContent: some ToolbarContent {
            ToolbarItem(placement: .primaryAction) {
                if let detail, hasLifecycleActions(detail) || canPickRelease(detail) {
                    Menu {
                        ForEach(allLifecycleActions(for: detail), id: \.self) { action in
                            lifecycleMenuButton(action)
                        }
                        if canPickRelease(detail) {
                            if hasLifecycleActions(detail) { Divider() }
                            Button("Import Torrent", systemImage: "doc.badge.plus") {
                                isImportingTorrent = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .accessibilityLabel("Acquisition Actions")
                    .disabled(isActing)
                }
            }
        }

        @ViewBuilder
        private func lifecycleMenuButton(_ action: RequestActivityAcquisitionAction) -> some View {
            if action == .startOver {
                Button(action.title, systemImage: action.systemImage, role: .destructive) {
                    confirmsStartOver = true
                }
            } else if action == .cancel {
                Button(action.title, systemImage: action.systemImage, role: .destructive) {
                    Task { await performLifecycleAction(action) }
                }
            } else {
                Button(action.title, systemImage: action.systemImage) {
                    Task { await performLifecycleAction(action) }
                }
            }
        }

        // MARK: - Embedded (web-parity) style

        @ViewBuilder
        private var embeddedContent: some View {
            if let detail {
                VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                    embeddedStatusHeader(detail)
                    lifecycleMessages
                    embeddedBody(detail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if isLoading {
                PrismediaLoadingView("Loading acquisition…")
            } else if let loadErrorMessage {
                RequestActivityLifecycleMessage(
                    title: "Unable to Load Acquisition",
                    message: loadErrorMessage,
                    retryTitle: "Try Again",
                    onRetry: { Task { await load(showSpinner: true) } }
                )
            }
        }

        private func embeddedStatusHeader(_ detail: RequestActivityAcquisitionDetail) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                embeddedStatusSummary(detail)
                if hasLifecycleActions(detail) {
                    GlassEffectContainer(spacing: PrismediaSpacing.small) {
                        VStack(spacing: PrismediaSpacing.small) {
                            lifecycleActions(detail)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .prismediaCompactActionControlSize()
                }
            }
        }

        private func embeddedStatusSummary(_ detail: RequestActivityAcquisitionDetail) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Label(
                    RequestActivityAcquisitionLifecyclePolicy.label(for: detail.summary.status),
                    systemImage: RequestActivityStatusPolicy.systemImage(for: detail.summary.status)
                )
                .font(.headline)
                .foregroundStyle(
                    RequestActivityStatusPolicy.tone(for: detail.summary.status).foregroundStyle
                )

                if let description = RequestActivityAcquisitionLifecyclePolicy.description(
                    for: detail.summary.status,
                    message: detail.summary.statusMessage
                ) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                Text("Updated \(detail.summary.updatedAt, style: .relative)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .accessibilityElement(children: .combine)
        }

        private var hasLifecycleMessage: Bool {
            actionErrorMessage != nil || refreshState.message != nil
        }

        @ViewBuilder
        private var lifecycleMessages: some View {
            if let actionErrorMessage {
                if failedLifecycleAction != nil {
                    RequestActivityLifecycleMessage(
                        title: "Acquisition Action Failed",
                        message: actionErrorMessage,
                        retryTitle: "Retry",
                        onRetry: retryFailedLifecycleAction,
                        onDismiss: dismissActionError
                    )
                } else {
                    RequestActivityLifecycleMessage(
                        title: "Acquisition Action Failed",
                        message: actionErrorMessage,
                        onDismiss: dismissActionError
                    )
                }
            }

            if let refreshMessage = refreshState.message {
                RequestActivityLifecycleMessage(
                    title: "Live Updates Delayed",
                    message: refreshMessage,
                    isWarning: true,
                    retryTitle: "Retry Now",
                    onRetry: { Task { await load(showSpinner: false) } },
                    onDismiss: { refreshState.dismiss() }
                )
            }
        }

        private func hasLifecycleActions(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            !allLifecycleActions(for: detail).isEmpty
        }

        private func allLifecycleActions(
            for detail: RequestActivityAcquisitionDetail
        ) -> [RequestActivityAcquisitionAction] {
            var actions: [RequestActivityAcquisitionAction] = []
            if let primary = primaryLifecycleAction(for: detail) {
                actions.append(primary)
            }
            actions.append(contentsOf: secondaryLifecycleActions(for: detail))
            return actions
        }

        private func primaryLifecycleAction(
            for detail: RequestActivityAcquisitionDetail
        ) -> RequestActivityAcquisitionAction? {
            RequestActivityAcquisitionLifecyclePolicy.primaryAction(
                for: detail.summary.status,
                hasResumableImport: detail.summary.hasResumableImport
            )
        }

        private func secondaryLifecycleActions(
            for detail: RequestActivityAcquisitionDetail
        ) -> [RequestActivityAcquisitionAction] {
            RequestActivityAcquisitionLifecyclePolicy.secondaryActions(
                for: detail.summary.status,
                hasResumableImport: detail.summary.hasResumableImport
            )
        }

        @ViewBuilder
        private func lifecycleActions(_ detail: RequestActivityAcquisitionDetail) -> some View {
            ForEach(allLifecycleActions(for: detail), id: \.self) { action in
                lifecycleButton(action, primaryAction: primaryLifecycleAction(for: detail))
            }
        }

        private func lifecycleButton(
            _ action: RequestActivityAcquisitionAction,
            primaryAction: RequestActivityAcquisitionAction?
        ) -> some View {
            PrismediaButton(
                action.title,
                systemImage: action.systemImage,
                variant: action == primaryAction
                    ? .prominent
                    : action == .cancel || action == .startOver ? .destructive : .standard,
                form: .fill,
                primaryTint: action == primaryAction ? artworkPrimaryAccent : nil,
                isLoading: activeLifecycleAction == action,
                loadingTitle: action.progressTitle
            ) {
                if action == .startOver {
                    confirmsStartOver = true
                } else {
                    Task { await performLifecycleAction(action) }
                }
            }
            .disabled(isActing)
            .frame(maxWidth: .infinity)
        }

        @ViewBuilder
        private func embeddedBody(_ detail: RequestActivityAcquisitionDetail) -> some View {
            let status = detail.summary.status
            if canPickRelease(detail) {
                releasePicker(detail)
            } else {
                switch RequestActivityAcquisitionLifecyclePolicy.content(for: status) {
                case .locked:
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
                case .preparingSearch:
                    PrismediaLoadingView("Preparing search…")
                case .searching:
                    PrismediaLoadingView("Searching indexers…")
                case .download:
                    RequestActivityDownloadSection(
                        transfer: transfer,
                        loadState: transferLoadState
                    )
                case .files:
                    RequestActivityFilesSection(
                        loadState: filesLoadState,
                        retry: { Task { await refreshFiles(for: status, isInitial: filesLoadState.files == nil) } }
                    )
                case .releases, .lifecycleOnly:
                    EmptyView()
                }
            }
        }

        private func releasePicker(_ detail: RequestActivityAcquisitionDetail) -> some View {
            RequestActivityReleasesSection(
                candidates: detail.candidates,
                canPickRelease: canPickRelease(detail),
                isBusy: isActing,
                activeAction: activeCandidateAction,
                onDownload: { target in Task { await queue(target) } },
                onBlocklist: { target in Task { await blocklist(target) } },
                onUploadTorrent: { isImportingTorrent = true }
            )
        }

        private func canPickRelease(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            RequestActivityAcquisitionLifecyclePolicy.showsReleasePicker(
                for: detail.summary.status,
                hasResumableImport: detail.summary.hasResumableImport,
                hasCandidates: !detail.candidates.isEmpty
            )
        }

        // MARK: - Loading and actions

        private func load(showSpinner: Bool) async {
            if showSpinner { isLoading = true }
            defer { if showSpinner { isLoading = false } }
            do {
                let nextDetail = try await service.fetchRequestActivityAcquisition(id: acquisitionID)
                if detail != nextDetail { detail = nextDetail }
                let transferRefreshed = try await refreshTransfer(for: nextDetail.summary.status)
                await refreshFiles(for: nextDetail.summary.status, isInitial: filesLoadState.files == nil)
                let nextBlocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                if blocklist != nextBlocklist { blocklist = nextBlocklist }
                loadErrorMessage = nil
                if transferRefreshed {
                    refreshState.recordSuccess()
                } else {
                    refreshState.recordFailure()
                }
                await observeStatusTransition(nextDetail.summary.status)
            } catch is CancellationError {
                return
            } catch {
                if detail == nil {
                    loadErrorMessage = error.localizedDescription
                } else {
                    if transfer != nil { transferLoadState = .stale }
                    refreshState.recordFailure()
                }
            }
        }

        /// Refreshes only the transfer slice needed by the Download section. A client
        /// probe failure retains the last known telemetry and is reported separately
        /// from a successful 204 response, which means the handoff is still preparing.
        private func refreshTransfer(for status: AcquisitionStatus) async throws -> Bool {
            guard RequestActivityAcquisitionLifecyclePolicy.content(for: status) == .download else {
                transfer = nil
                transferLoadState = .preparing
                return true
            }

            do {
                let nextTransfer = try await service.fetchRequestActivityTransfer(id: acquisitionID)
                if transfer != nextTransfer { transfer = nextTransfer }
                transferLoadState = nextTransfer == nil ? .preparing : .current
                return true
            } catch {
                if error is CancellationError { throw error }
                transferLoadState = transfer == nil ? .unavailable : .stale
                return false
            }
        }

        private func refreshFiles(for status: AcquisitionStatus, isInitial: Bool) async {
            guard RequestActivityAcquisitionLifecyclePolicy.content(for: status) == .files else { return }
            do {
                let nextFiles = try await service.fetchRequestActivityFiles(id: acquisitionID)
                if !nextFiles.files.isEmpty {
                    filesLoadState.recordSuccess(nextFiles)
                } else if nextFiles.importInformationUnavailable == true {
                    filesLoadState.recordUnavailable()
                } else if status.rawValue == "imported" {
                    filesLoadState.recordEmpty()
                } else {
                    filesLoadState.recordWaiting()
                }
            } catch is CancellationError {
                return
            } catch {
                if filesLoadState.files != nil {
                    filesLoadState.recordRefreshFailure()
                } else if isInitial {
                    filesLoadState.recordInitialFailure(error.localizedDescription)
                }
            }
        }

        private func pollWhileVisible() async {
            while liveRefreshIsActive {
                do { try await Task.sleep(for: liveRefreshInterval) } catch { return }
                guard !Task.isCancelled, liveRefreshIsActive else { return }
                await load(showSpinner: false)
            }
        }

        private var liveRefreshTaskIdentity: String {
            "\(acquisitionID.uuidString)-\(liveRefreshIsActive)"
        }

        private var liveRefreshIsActive: Bool {
            pageIsActive && scenePhase == .active
        }

        private var liveRefreshInterval: Duration {
            detail.map { RequestActivityStatusPolicy.shouldPoll($0.summary.status) } == true
                ? .seconds(4)
                : .seconds(12)
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

        private func performLifecycleAction(_ action: RequestActivityAcquisitionAction) async {
            switch action {
            case .research:
                await mutateLifecycle(action) {
                    try await service.researchRequestActivityAcquisition(id: acquisitionID)
                }
            case .cancel:
                let succeeded = await mutateLifecycle(action) {
                    try await service.cancelRequestActivityAcquisition(id: acquisitionID)
                }
                if succeeded { await onCancelled?() }
            case .retryImport(let allowFormatChange):
                await mutateLifecycle(action) {
                    try await service.retryRequestActivityImport(
                        id: acquisitionID,
                        allowFormatChange: allowFormatChange
                    )
                }
            case .startOver:
                await startOver()
            }
        }

        private func startOver() async {
            guard !isActing else { return }
            isActing = true
            activeLifecycleAction = .startOver
            actionErrorMessage = nil
            failedLifecycleAction = nil
            defer {
                activeLifecycleAction = nil
                isActing = false
            }
            do {
                try await service.removeRequestActivityAcquisition(id: acquisitionID)
                detail = nil
                transfer = nil
                transferLoadState = .preparing
                filesLoadState = .initialLoading
                blocklist = []
                refreshState.recordSuccess()
                await onReset?()
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = .startOver
            }
        }

        private func queue(_ candidate: RequestActivityReleaseCandidate) async {
            await mutateCandidate(.download(candidate.id)) {
                try await service.queueRequestActivityRelease(
                    acquisitionID: acquisitionID,
                    candidateID: candidate.id
                )
            }
        }

        private func blocklist(_ candidate: RequestActivityReleaseCandidate) async {
            let succeeded = await mutateCandidate(.blocklist(candidate.id)) {
                try await service.blocklistRequestActivityCandidate(
                    acquisitionID: acquisitionID,
                    candidateID: candidate.id
                )
            }
            if succeeded {
                AccessibilityNotification.Announcement(
                    "Blocked \(RequestActivityReleasePolicy.displayTitle(for: candidate))."
                ).post()
            }
        }

        private func removeBlocklistEntry(_ entry: RequestActivityBlocklistEntry) async {
            guard !isActing else { return }
            isActing = true
            defer { isActing = false }
            do {
                try await service.removeRequestActivityBlocklistEntry(id: entry.id)
                blocklist.removeAll { $0.id == entry.id }
                actionErrorMessage = nil
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = nil
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
                    actionErrorMessage = error.localizedDescription
                    failedLifecycleAction = nil
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
                let transferRefreshed = (try? await refreshTransfer(for: nextDetail.summary.status)) ?? false
                await refreshFiles(for: nextDetail.summary.status, isInitial: filesLoadState.files == nil)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                actionErrorMessage = nil
                failedLifecycleAction = nil
                if transferRefreshed {
                    refreshState.recordSuccess()
                } else {
                    refreshState.recordFailure()
                }
                await observeStatusTransition(nextDetail.summary.status)
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = nil
            }
        }

        @discardableResult
        private func mutateCandidate(
            _ action: RequestActivityCandidateAction,
            operation: () async throws -> RequestActivityAcquisitionDetail
        ) async -> Bool {
            guard !isActing else { return false }
            isActing = true
            activeCandidateAction = action
            defer {
                activeCandidateAction = nil
                isActing = false
            }
            do {
                let nextDetail = try await operation()
                detail = nextDetail
                let transferRefreshed = (try? await refreshTransfer(for: nextDetail.summary.status)) ?? false
                await refreshFiles(for: nextDetail.summary.status, isInitial: filesLoadState.files == nil)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                actionErrorMessage = nil
                failedLifecycleAction = nil
                if transferRefreshed {
                    refreshState.recordSuccess()
                } else {
                    refreshState.recordFailure()
                }
                await observeStatusTransition(nextDetail.summary.status)
                return true
            } catch is CancellationError {
                return false
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = nil
                return false
            }
        }

        @discardableResult
        private func mutateLifecycle(
            _ action: RequestActivityAcquisitionAction,
            operation: () async throws -> RequestActivityAcquisitionDetail
        ) async -> Bool {
            guard !isActing else { return false }
            isActing = true
            activeLifecycleAction = action
            actionErrorMessage = nil
            failedLifecycleAction = nil
            defer {
                activeLifecycleAction = nil
                isActing = false
            }
            do {
                let nextDetail = try await operation()
                detail = nextDetail
                let transferRefreshed = (try? await refreshTransfer(for: nextDetail.summary.status)) ?? false
                await refreshFiles(for: nextDetail.summary.status, isInitial: filesLoadState.files == nil)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                if transferRefreshed {
                    refreshState.recordSuccess()
                } else {
                    refreshState.recordFailure()
                }
                await observeStatusTransition(nextDetail.summary.status)
                return true
            } catch is CancellationError {
                return false
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = action
                return false
            }
        }

        private func retryFailedLifecycleAction() {
            guard let failedLifecycleAction else { return }
            actionErrorMessage = nil
            if failedLifecycleAction == .startOver {
                confirmsStartOver = true
            } else {
                Task { await performLifecycleAction(failedLifecycleAction) }
            }
        }

        private func dismissActionError() {
            actionErrorMessage = nil
            failedLifecycleAction = nil
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

        #Preview("Lifecycle · Preparing Search") {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: RequestActivityPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .pending),
                style: .embedded
            )
            .padding()
        }

        #Preview("Lifecycle · Failed Resumable") {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: RequestActivityPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .failedResumable),
                style: .embedded
            )
            .padding()
        }

        #Preview("Lifecycle · Cancelled · Accessibility") {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: RequestActivityPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .cancelled),
                style: .embedded
            )
            .padding()
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
