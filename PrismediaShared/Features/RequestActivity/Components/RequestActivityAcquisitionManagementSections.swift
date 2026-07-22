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
        @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
        @Environment(\.prismediaPageIsActive) private var pageIsActive
        @Environment(\.scenePhase) private var scenePhase
        @State private var detail: RequestActivityAcquisitionDetail?
        @State private var transfer: RequestActivityTransfer?
        @State private var files: RequestActivityFiles?
        @State private var blocklist: [RequestActivityBlocklistEntry] = []
        @State private var isLoading = true
        @State private var isActing = false
        @State private var loadErrorMessage: String?
        @State private var actionErrorMessage: String?
        @State private var refreshState = RequestActivityAcquisitionRefreshState()
        @State private var activeLifecycleAction: RequestActivityAcquisitionAction?
        @State private var failedLifecycleAction: RequestActivityAcquisitionAction?
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
            .task(id: liveRefreshTaskIdentity) {
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
            switch RequestActivityAcquisitionLifecyclePolicy.content(for: detail.summary.status) {
            case .download:
                transferSection
                filesSection
            case .files:
                filesSection
            case .releases:
                blocklistSection
                candidatesSection
            case .preparingSearch, .searching, .lifecycleOnly, .locked:
                EmptyView()
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
                            .prismediaCompactActionControlSize()
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
                HStack(spacing: PrismediaSpacing.medium) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading acquisition…")
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                    embeddedStatusSummary(detail)
                    Spacer(minLength: PrismediaSpacing.medium)
                    if hasLifecycleActions(detail) {
                        GlassEffectContainer(spacing: PrismediaSpacing.small) {
                            HStack(spacing: PrismediaSpacing.small) {
                                wideLifecycleActions(detail)
                            }
                        }
                        .prismediaCompactActionControlSize()
                    }
                }
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    embeddedStatusSummary(detail)
                    if hasLifecycleActions(detail) {
                        GlassEffectContainer(spacing: PrismediaSpacing.small) {
                            HStack(spacing: PrismediaSpacing.small) {
                                compactLifecycleActions(detail)
                            }
                        }
                        .prismediaCompactActionControlSize()
                    }
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
        private func wideLifecycleActions(_ detail: RequestActivityAcquisitionDetail) -> some View {
            ForEach(allLifecycleActions(for: detail), id: \.self) { action in
                lifecycleButton(action, primaryAction: primaryLifecycleAction(for: detail))
            }
        }

        @ViewBuilder
        private func compactLifecycleActions(_ detail: RequestActivityAcquisitionDetail) -> some View {
            let visibleActions = compactVisibleActions(for: detail)
            let overflowActions = allLifecycleActions(for: detail).filter { !visibleActions.contains($0) }

            ForEach(visibleActions, id: \.self) { action in
                lifecycleButton(action, primaryAction: primaryLifecycleAction(for: detail))
            }

            if !overflowActions.isEmpty {
                Menu {
                    ForEach(overflowActions, id: \.self) { action in
                        lifecycleMenuButton(action)
                    }
                } label: {
                    Label("More Acquisition Actions", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.glass)
                .accessibilityLabel("More Acquisition Actions")
                .disabled(isActing)
            }
        }

        private func compactVisibleActions(
            for detail: RequestActivityAcquisitionDetail
        ) -> [RequestActivityAcquisitionAction] {
            if let primary = primaryLifecycleAction(for: detail) { return [primary] }
            let secondary = secondaryLifecycleActions(for: detail)
            return secondary == [.cancel] ? [.cancel] : []
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
        }

        @ViewBuilder
        private func embeddedBody(_ detail: RequestActivityAcquisitionDetail) -> some View {
            let status = detail.summary.status
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
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Preparing search")
            case .searching:
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Searching indexers")
            case .download:
                RequestActivityDownloadSection(transfer: transfer)
            case .files:
                RequestActivityFilesSection(
                    files: files,
                    isActive: RequestActivityStatusPolicy.shouldPoll(status)
                )
            case .releases:
                RequestActivityReleasesSection(
                    candidates: detail.candidates,
                    canPickRelease: canPickRelease(detail),
                    isBusy: isActing,
                    onQueue: { target in Task { await queue(target) } },
                    onBlocklist: { target in Task { await blocklist(target) } },
                    onUploadTorrent: { isImportingTorrent = true }
                )
            case .lifecycleOnly:
                EmptyView()
            }
        }

        private func canPickRelease(_ detail: RequestActivityAcquisitionDetail) -> Bool {
            let status = detail.summary.status.rawValue
            return status == "awaiting-selection"
                || status == "manual-import-required"
        }

        // MARK: - Loading and actions

        private func load(showSpinner: Bool) async {
            if showSpinner { isLoading = true }
            defer { if showSpinner { isLoading = false } }
            do {
                let nextDetail = try await service.fetchRequestActivityAcquisition(id: acquisitionID)
                if detail != nextDetail { detail = nextDetail }
                let nextTransfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                if transfer != nextTransfer { transfer = nextTransfer }
                let nextFiles = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                if files != nextFiles { files = nextFiles }
                let nextBlocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                if blocklist != nextBlocklist { blocklist = nextBlocklist }
                loadErrorMessage = nil
                refreshState.recordSuccess()
                await observeStatusTransition(nextDetail.summary.status)
            } catch is CancellationError {
                return
            } catch {
                if detail == nil {
                    loadErrorMessage = error.localizedDescription
                } else {
                    refreshState.recordFailure()
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
                files = nil
                blocklist = []
                refreshState.recordSuccess()
                await onReset?()
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = .startOver
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
                transfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                files = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                actionErrorMessage = nil
                failedLifecycleAction = nil
                refreshState.recordSuccess()
                await observeStatusTransition(nextDetail.summary.status)
            } catch {
                actionErrorMessage = error.localizedDescription
                failedLifecycleAction = nil
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
                transfer = try? await service.fetchRequestActivityTransfer(id: acquisitionID)
                files = try? await service.fetchRequestActivityFiles(id: acquisitionID)
                blocklist =
                    (try? await service.listRequestActivityBlocklist())?.filter {
                        $0.acquisitionID == acquisitionID
                    } ?? []
                refreshState.recordSuccess()
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
