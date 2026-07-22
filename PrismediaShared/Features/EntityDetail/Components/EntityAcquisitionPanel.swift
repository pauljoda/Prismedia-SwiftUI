import SwiftUI

struct EntityAcquisitionPanel: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @Environment(\.prismediaPageIsActive) private var pageIsActive
    @Environment(\.scenePhase) private var scenePhase
    @State private var state = EntityAcquisitionPanelState()
    @State private var confirmsUnmonitor = false
    @State private var historyEntries: [RequestActivityHistoryEntry] = []
    @State private var pendingMonitorValue: Bool?
    @State private var confirmedMonitorValue: Bool?
    @State private var activeCommand: EntityAcquisitionCommand?
    @State private var failedCommand: EntityAcquisitionCommand?
    @State private var failedPendingMonitorValue: Bool?
    @State private var actionNotice: String?
    @State private var isManualAcquisitionBusy = false
    private let entityID: UUID
    private let entityKind: EntityKind
    private let hasOwnedContent: Bool
    private let childGroups: [EntityGroup]
    private let service: EntityAcquisitionService?
    private let requestActivityService: (any RequestActivityServicing)?
    private let onMutated: @MainActor () async -> Void
    private let onEntityPruned: @MainActor () -> Void
    #if DEBUG
        private var disablesLiveLoadingForPreview = false
    #endif

    init(
        entityID: UUID,
        entityKind: EntityKind = .book,
        hasOwnedContent: Bool = false,
        childGroups: [EntityGroup] = [],
        acquisitionService: (any EntityAcquisitionServicing)?,
        requestActivityService: (any RequestActivityServicing)? = nil,
        onMutated: @escaping @MainActor () async -> Void,
        onEntityPruned: @escaping @MainActor () -> Void
    ) {
        self.entityID = entityID
        self.entityKind = entityKind
        self.hasOwnedContent = hasOwnedContent
        self.childGroups = childGroups
        service = acquisitionService.map(EntityAcquisitionService.init(port:))
        self.requestActivityService = requestActivityService
        self.onMutated = onMutated
        self.onEntityPruned = onEntityPruned
    }

    #if DEBUG
        init(
            entityID: UUID,
            entityKind: EntityKind = .book,
            hasOwnedContent: Bool = false,
            childGroups: [EntityGroup] = [],
            previewPhase: EntityAcquisitionPanelPhase,
            acquisitionService: any EntityAcquisitionServicing,
            requestActivityService: (any RequestActivityServicing)? = nil,
            isMutating: Bool = false,
            mutationError: String? = nil,
            refreshError: String? = nil,
            pendingMonitorValue: Bool? = nil,
            confirmedMonitorValue: Bool? = nil,
            activeCommand: EntityAcquisitionCommand? = nil,
            failedCommand: EntityAcquisitionCommand? = nil,
            failedPendingMonitorValue: Bool? = nil,
            actionNotice: String? = nil,
            onMutated: @escaping @MainActor () async -> Void = {},
            onEntityPruned: @escaping @MainActor () -> Void = {}
        ) {
            self.init(
                entityID: entityID,
                entityKind: entityKind,
                hasOwnedContent: hasOwnedContent,
                childGroups: childGroups,
                acquisitionService: acquisitionService,
                requestActivityService: requestActivityService,
                onMutated: onMutated,
                onEntityPruned: onEntityPruned
            )
            _state = State(
                initialValue: EntityAcquisitionPanelState(
                    previewPhase: previewPhase,
                    isMutating: isMutating,
                    mutationError: mutationError,
                    refreshError: refreshError
                )
            )
            _pendingMonitorValue = State(initialValue: pendingMonitorValue)
            _confirmedMonitorValue = State(initialValue: confirmedMonitorValue)
            _activeCommand = State(initialValue: activeCommand)
            _failedCommand = State(initialValue: failedCommand)
            _failedPendingMonitorValue = State(initialValue: failedPendingMonitorValue)
            _actionNotice = State(initialValue: actionNotice)
            disablesLiveLoadingForPreview = true
        }
    #endif

    var body: some View {
        Group {
            if let service {
                switch state.phase {
                case .loading:
                    monitorSurface(monitorState: nil, snapshot: nil, service: service)
                case .failure(let message):
                    monitorSurface(
                        monitorState: nil,
                        snapshot: nil,
                        service: service,
                        loadError: message
                    )
                case .content(let snapshot):
                    contentView(snapshot, service: service)
                }
            } else {
                adminUnavailableView
            }
        }
        .task(id: liveRefreshTaskIdentity) {
            #if DEBUG
                guard !disablesLiveLoadingForPreview else { return }
            #endif
            guard let service, liveRefreshIsActive else { return }
            if case .content = state.phase {
                await backgroundLoad(using: service)
            } else {
                await load(using: service)
            }
            await pollWhileVisible(using: service)
        }
        .confirmationDialog(
            "Stop monitoring this item?",
            isPresented: $confirmsUnmonitor,
            titleVisibility: .visible
        ) {
            Button("Unmonitor", role: .destructive) {
                guard case .content(let snapshot) = state.phase,
                    let monitor = snapshot.state.monitor,
                    let service
                else { return }
                Task {
                    await performMonitorMutation(
                        .unmonitor(monitor.id),
                        pendingValue: false,
                        using: service
                    )
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This removes its acquisition and downloads. A fileless wanted placeholder may also be removed from the library."
            )
        }
        .accessibilityIdentifier("entity-detail.acquisition")
    }

    private var adminUnavailableView: some View {
        ContentUnavailableView {
            Label("Administrator Access Required", systemImage: "lock.shield")
        } description: {
            Text("Monitoring and acquisition controls are managed by server administrators.")
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func contentView(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        monitorSurface(
            monitorState: snapshot.state,
            snapshot: snapshot,
            service: service
        )
    }

    private func monitorSurface(
        monitorState: EntityMonitorState?,
        snapshot: EntityAcquisitionPanelSnapshot?,
        service: EntityAcquisitionService,
        loadError: String? = nil
    ) -> some View {
        let presentation = EntityMonitorPresentation(
            state: monitorState,
            isMutating: state.isMutating || isManualAcquisitionBusy,
            pendingValue: pendingMonitorValue,
            confirmedValue: confirmedMonitorValue
        )

        return VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            EntityMonitorControl(
                monitorState: monitorState,
                presentation: presentation,
                showsMutationProgress: pendingMonitorValue != nil
                    || confirmedMonitorValue != nil,
                primaryAccent: artworkPrimaryAccent,
                onChange: { nextValue in
                    guard let monitorState else { return }
                    updateMonitor(
                        to: nextValue,
                        monitorState: monitorState,
                        service: service
                    )
                }
            )

            messageContent(
                presentation: presentation,
                monitorState: monitorState,
                service: service,
                loadError: loadError
            )

            if loadError == nil, monitorState == nil {
                PrismediaLoadingView("Loading monitoring…")
            }

            if presentation.showsExpandedContent, let snapshot {
                expandedContent(snapshot, service: service)
            }

            #if os(iOS) || os(macOS)
                if !presentation.showsExpandedContent || snapshot == nil {
                    childActivityContent(service: service)
                }
            #endif
        }
        .padding(PrismediaSpacing.extraLarge)
        .prismediaCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func messageContent(
        presentation: EntityMonitorPresentation,
        monitorState: EntityMonitorState?,
        service: EntityAcquisitionService,
        loadError: String?
    ) -> some View {
        if let loadError {
            EntityAcquisitionMessageCard(
                title: "Couldn’t Load Monitoring",
                message: loadError,
                retryTitle: "Try Again",
                onRetry: { Task { await load(using: service) } }
            )
        }

        if presentation.canRetryCleanup,
            let monitorID = monitorState?.monitor?.id
        {
            EntityAcquisitionMessageCard(
                title: "Cleanup Needs Attention",
                message: "Monitoring is off, but server cleanup has not finished.",
                isWarning: true,
                retryTitle: "Finish Unmonitoring",
                onRetry: {
                    Task {
                        await performMonitorMutation(
                            .unmonitor(monitorID),
                            pendingValue: false,
                            using: service
                        )
                    }
                }
            )
        }

        if let mutationError = state.mutationError {
            EntityAcquisitionMessageCard(
                title: mutationErrorTitle,
                message: mutationError,
                retryTitle: failedCommand == nil ? nil : "Retry",
                onRetry: failedCommand.map { command in
                    {
                        Task {
                            await performCommand(
                                command,
                                pendingMonitorValue: failedPendingMonitorValue,
                                using: service
                            )
                        }
                    }
                },
                onDismiss: {
                    state.dismissMutationError()
                    failedCommand = nil
                    failedPendingMonitorValue = nil
                }
            )
        }

        if let refreshError = state.refreshError {
            EntityAcquisitionMessageCard(
                title: "Monitoring Updated",
                message: "The change was saved, but this page couldn’t refresh. \(refreshError)",
                isWarning: true,
                retryTitle: "Refresh",
                onRetry: { Task { await retryRefresh(using: service) } },
                onDismiss: { state.dismissRefreshError() }
            )
        }

        if let actionNotice {
            EntityAcquisitionMessageCard(
                title: "Search Started",
                message: actionNotice,
                isInformational: true,
                onDismiss: { self.actionNotice = nil }
            )
        }
    }

    @ViewBuilder
    private func expandedContent(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        if snapshot.state.discoversChildren {
            groupingContent(snapshot.state, service: service)
        }

        if hasPanelActions(snapshot) {
            actionContent(snapshot, service: service)
        }

        #if os(iOS) || os(macOS)
            if let requestActivityService,
                RequestActivityManualUploadPolicy.canUploadContent(
                    kind: entityKind,
                    hasOwnedContent: hasOwnedContent,
                    acquisitionStatus: snapshot.latestAcquisition?.summary.status
                        ?? snapshot.state.latestAcquisition?.status
                )
            {
                Divider()
                EntityManualContentUploadSection(
                    entityID: entityID,
                    kind: entityKind,
                    bookRendition: snapshot.latestAcquisition?.summary.bookRendition,
                    service: requestActivityService,
                    isParentBusy: $isManualAcquisitionBusy,
                    onUploaded: { detail in
                        await manualContentUploaded(detail, using: service)
                    }
                )
            }

            if let acquisition = snapshot.latestAcquisition, let requestActivityService {
                Divider()
                RequestActivityAcquisitionManagementSections(
                    acquisitionID: acquisition.summary.id,
                    service: requestActivityService,
                    style: .embedded,
                    onCancelled: { await load(using: service) },
                    onImported: {
                        await load(using: service)
                        await onMutated()
                    },
                    onReset: {
                        await load(using: service)
                        await onMutated()
                    },
                    isExternallyDisabled: isManualAcquisitionBusy
                )
                .id(acquisition.summary.id)
            } else if snapshot.state.latestAcquisition != nil {
                fallbackContent(snapshot)
            }

            if snapshot.state.discoversChildren,
                !monitoringChildren(for: snapshot.state).isEmpty
            {
                Divider()
                EntityChildMonitoringSection(
                    title: childMonitoringTitle(for: snapshot.state),
                    entities: monitoringChildren(for: snapshot.state),
                    primaryAccent: artworkPrimaryAccent,
                    service: service,
                    onChanged: onMutated
                )
            }

            childActivityContent(service: service)

            if !historyEntries.isEmpty {
                Divider()
                EntityAcquisitionHistorySection(entries: historyEntries)
            }
        #else
            fallbackContent(snapshot)
        #endif
    }

    private func groupingContent(
        _ monitorState: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            Divider()
            if let monitor = monitorState.monitor {
                LabeledContent("Monitoring Scope", value: scopeLabel(monitor.preset))
                    .foregroundStyle(PrismediaColor.textPrimary)
            }

            GlassEffectContainer(spacing: PrismediaSpacing.small) {
                VStack(spacing: PrismediaSpacing.small) {
                    groupingButtons(monitorState, service: service)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .prismediaCompactActionControlSize()
            .disabled(state.isMutating || isManualAcquisitionBusy)
        }
    }

    @ViewBuilder
    private func groupingButtons(
        _ monitorState: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        PrismediaButton(
            "Check for New Content Now",
            systemImage: "arrow.clockwise",
            form: .fill,
            isLoading: activeCommand == .syncContainer(entityID),
            loadingTitle: "Checking…"
        ) {
            Task { await perform(.syncContainer(entityID), using: service) }
        }
        .frame(maxWidth: .infinity)

        if monitorState.canSearchMissingChildren {
            PrismediaButton(
                missingChildCount(for: monitorState) > 0
                    ? "Search \(missingChildCount(for: monitorState)) Missing"
                    : "Search for Missing Content",
                systemImage: "magnifyingglass",
                form: .fill,
                isLoading: activeCommand == .searchMissingChildren(entityID),
                loadingTitle: "Searching…"
            ) {
                Task { await perform(.searchMissingChildren(entityID), using: service) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func monitoringChildren(
        for monitorState: EntityMonitorState
    ) -> [EntityThumbnail] {
        guard let kind = monitorState.missingChildEntityKind else {
            return childGroups.flatMap(\.entities)
        }
        return childGroups.first(where: { $0.kind == kind })?.entities ?? []
    }

    @ViewBuilder
    private func childActivityContent(service: EntityAcquisitionService) -> some View {
        let children = EntityChildAcquisitionActivityPolicy.eligibleChildren(
            parentID: entityID,
            groups: childGroups
        )
        if !children.isEmpty {
            Divider()
            EntityChildAcquisitionActivitySection(
                entities: children,
                service: service,
                onChanged: onMutated
            )
        }
    }

    private func childMonitoringTitle(for monitorState: EntityMonitorState) -> String {
        guard let childKind = monitorState.missingChildEntityKind else {
            return "Child Monitoring"
        }
        if monitorState.monitor?.kind == .videoSeason, childKind == .video {
            return "Episode Monitoring"
        }
        return "\(childKind.displayLabel) Monitoring"
    }

    private func missingChildCount(for monitorState: EntityMonitorState) -> Int {
        guard let kind = monitorState.missingChildEntityKind else { return 0 }
        return monitoringChildren(for: monitorState).filter {
            $0.kind == kind && $0.isWanted && $0.wantedStatus == nil
        }.count
    }

    private func scopeLabel(_ preset: String) -> String {
        preset == "all"
            ? "All current and future"
            : preset.replacingOccurrences(of: "-", with: " ").capitalized
    }

    // MARK: - Actions

    private func actionContent(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        GlassEffectContainer(spacing: PrismediaSpacing.small) {
            VStack(spacing: PrismediaSpacing.small) {
                actionButtons(snapshot, service: service)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .prismediaCompactActionControlSize()
        .disabled(state.isMutating || activeCommand != nil || isManualAcquisitionBusy)
    }

    @ViewBuilder
    private func actionButtons(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        if showsSearchForRelease(snapshot) {
            PrismediaButton(
                "Search for release",
                systemImage: "magnifyingglass",
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent,
                isLoading: activeCommand == .searchForRelease(entityID),
                loadingTitle: "Searching…"
            ) {
                Task { await perform(.searchForRelease(entityID), using: service) }
            }
        }

        if !embedsManagement(snapshot), let acquisition = snapshot.state.latestAcquisition {
            PrismediaButton(
                "Search Again",
                systemImage: "arrow.clockwise",
                form: .fill,
                isLoading: activeCommand == .searchAgain(acquisition.id),
                loadingTitle: "Searching…"
            ) {
                Task { await perform(.searchAgain(acquisition.id), using: service) }
            }
        }
    }

    private func updateMonitor(
        to nextValue: Bool,
        monitorState: EntityMonitorState,
        service: EntityAcquisitionService
    ) {
        let presentation = EntityMonitorPresentation(
            state: monitorState,
            isMutating: state.isMutating,
            pendingValue: pendingMonitorValue,
            confirmedValue: confirmedMonitorValue
        )
        guard nextValue != presentation.isOn else { return }

        if nextValue {
            let command =
                monitorState.monitor.map { EntityAcquisitionCommand.resume($0.id) }
                ?? .start(entityID)
            Task {
                await performMonitorMutation(
                    command,
                    pendingValue: true,
                    using: service
                )
            }
        } else {
            confirmsUnmonitor = true
        }
    }

    // MARK: - Gates

    private func hasPanelActions(_ snapshot: EntityAcquisitionPanelSnapshot) -> Bool {
        showsSearchForRelease(snapshot)
            || (!embedsManagement(snapshot) && snapshot.state.latestAcquisition != nil)
    }

    private func showsSearchForRelease(_ snapshot: EntityAcquisitionPanelSnapshot) -> Bool {
        guard snapshot.state.canRequest,
            snapshot.latestAcquisition == nil,
            snapshot.state.latestAcquisition == nil
        else { return false }
        guard let monitor = snapshot.state.monitor else { return true }
        return !isMonitorTransitionLocked(monitor.status)
    }

    private func embedsManagement(_ snapshot: EntityAcquisitionPanelSnapshot) -> Bool {
        #if os(iOS) || os(macOS)
            return snapshot.latestAcquisition != nil && requestActivityService != nil
        #else
            return false
        #endif
    }

    private func isMonitorTransitionLocked(_ status: EntityMonitorStatus) -> Bool {
        ![.active, .paused, .fulfilled].contains(status)
    }

    // MARK: - Fallback summary (tvOS and missing request-activity service)

    @ViewBuilder
    private func fallbackContent(_ snapshot: EntityAcquisitionPanelSnapshot) -> some View {
        if snapshot.state.latestAcquisition != nil {
            Divider()
            summaryFallback(snapshot)
        }
    }

    @ViewBuilder
    private func summaryFallback(_ snapshot: EntityAcquisitionPanelSnapshot) -> some View {
        if let acquisition = snapshot.state.latestAcquisition {
            acquisitionContent(acquisition)
        }
    }

    private func acquisitionContent(_ acquisition: EntityAcquisitionSummary) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text("Latest Acquisition")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LabeledContent("Status", value: acquisition.status.displayName)

            if let progress = acquisition.progress {
                ProgressView(value: min(max(progress, 0), 1)) {
                    Text("Download progress")
                } currentValueLabel: {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                .accessibilityValue(
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                )
            }

            if let message = acquisition.statusMessage, !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(artworkSecondaryText)
            }
        }
    }

    // MARK: - Loading and mutation

    private func load(using service: EntityAcquisitionService) async {
        let outcome = await service.load(entityID: entityID)
        state.finishLoad(outcome)
        if case .content = outcome { confirmedMonitorValue = nil }
        await loadHistory()
    }

    private func backgroundLoad(using service: EntityAcquisitionService) async {
        let outcome = await service.load(
            entityID: entityID,
            fallbackAcquisition: state.latestAcquisition
        )
        state.finishBackgroundLoad(outcome)
        if case .content = outcome { confirmedMonitorValue = nil }
        await loadHistory()
    }

    private func manualContentUploaded(
        _ detail: RequestActivityAcquisitionDetail,
        using service: EntityAcquisitionService
    ) async {
        state.applyLatestAcquisition(detail)
        await onMutated()
        let outcome = await service.load(
            entityID: entityID,
            fallbackAcquisition: detail
        )
        _ = state.finishMutationRefresh(outcome)
        await loadHistory()
    }

    /// Secondary surface: a history-load failure must never break the acquisition
    /// view, so it silently keeps whatever is already shown.
    private func loadHistory() async {
        #if os(iOS) || os(macOS)
            guard let requestActivityService else { return }
            let nextEntries =
                (try? await requestActivityService.listRequestActivityHistory(
                    limit: 50,
                    entityID: entityID
                )) ?? historyEntries
            if historyEntries != nextEntries { historyEntries = nextEntries }
        #endif
    }

    private func pollWhileVisible(using service: EntityAcquisitionService) async {
        while liveRefreshIsActive {
            do { try await Task.sleep(for: liveRefreshInterval) } catch { return }
            guard !Task.isCancelled, liveRefreshIsActive else { return }
            await backgroundLoad(using: service)
        }
    }

    private var liveRefreshTaskIdentity: String {
        "\(entityID.uuidString)-\(liveRefreshIsActive)"
    }

    private var liveRefreshIsActive: Bool {
        pageIsActive && scenePhase == .active
    }

    private var liveRefreshInterval: Duration {
        requiresFrequentRefresh ? .seconds(4) : .seconds(12)
    }

    private var requiresFrequentRefresh: Bool {
        guard case .content(let snapshot) = state.phase else { return false }
        if let monitor = snapshot.state.monitor,
            monitor.status == .stopping || monitor.status == .deletingFiles
        {
            return true
        }
        if let detail = snapshot.latestAcquisition {
            return RequestActivityStatusPolicy.shouldPoll(detail.summary.status)
        }
        if let summary = snapshot.state.latestAcquisition {
            return RequestActivityStatusPolicy.shouldPoll(summary.status)
        }
        return false
    }

    private func perform(
        _ command: EntityAcquisitionCommand,
        using service: EntityAcquisitionService
    ) async {
        await performCommand(command, pendingMonitorValue: nil, using: service)
    }

    private func performCommand(
        _ command: EntityAcquisitionCommand,
        pendingMonitorValue nextMonitorValue: Bool?,
        using service: EntityAcquisitionService
    ) async {
        guard state.beginMutation() else { return }
        activeCommand = command
        defer { activeCommand = nil }
        failedCommand = nil
        failedPendingMonitorValue = nil
        pendingMonitorValue = nextMonitorValue
        let outcome = await service.perform(command)

        if case .missingChildrenSearchCompleted(let result) = outcome {
            actionNotice = missingChildrenResultMessage(result)
        }

        switch state.finishMutation(outcome) {
        case .entityPruned:
            pendingMonitorValue = nil
            onEntityPruned()
        case .refresh:
            if let nextMonitorValue { confirmedMonitorValue = nextMonitorValue }
            pendingMonitorValue = nil
            let refreshOutcome = await service.load(
                entityID: entityID,
                fallbackAcquisition: state.latestAcquisition
            )
            if state.finishMutationRefresh(refreshOutcome) {
                confirmedMonitorValue = nil
            }
            await loadHistory()
            await onMutated()
        case .none:
            pendingMonitorValue = nil
            if case .failure = outcome {
                failedCommand = command
                failedPendingMonitorValue = nextMonitorValue
            }
        }
    }

    private func performMonitorMutation(
        _ command: EntityAcquisitionCommand,
        pendingValue: Bool,
        using service: EntityAcquisitionService
    ) async {
        await performCommand(
            command,
            pendingMonitorValue: pendingValue,
            using: service
        )
    }

    private func retryRefresh(using service: EntityAcquisitionService) async {
        let outcome = await service.load(
            entityID: entityID,
            fallbackAcquisition: state.latestAcquisition
        )
        if state.finishMutationRefresh(outcome) {
            confirmedMonitorValue = nil
            await loadHistory()
            await onMutated()
        }
    }

    private func missingChildrenResultMessage(
        _ result: EntityMissingChildrenSearchResponse
    ) -> String {
        if result.missing == 0 {
            return "Searches were queued for \(result.covered) missing items."
        }
        return "Searches were queued for \(result.covered) items; \(result.missing) could not be searched yet."
    }

    private var mutationErrorTitle: LocalizedStringKey {
        switch failedCommand {
        case .searchForRelease, .searchAgain:
            return "Couldn’t Start Search"
        default:
            return "Couldn’t Update Monitoring"
        }
    }
}

extension AcquisitionStatus {
    fileprivate var displayName: String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

#if DEBUG
    #Preview("Entity Acquisition · Downloading") {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.downloadingState,
                    acquisitionDetail: EntityAcquisitionPanelPreviewFixtures.downloadingDetail
                ),
                requestActivityService: EntityAcquisitionPanelPreviewFixtures.requestActivityService(
                    scenario: .downloading
                ),
                onMutated: {},
                onEntityPruned: {}
            )
            .padding()
        }
    }

    #Preview("Entity Acquisition · Releases") {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.awaitingSelectionState,
                    acquisitionDetail: EntityAcquisitionPanelPreviewFixtures.releasesDetail
                ),
                requestActivityService: EntityAcquisitionPanelPreviewFixtures.requestActivityService(
                    scenario: .releases
                ),
                onMutated: {},
                onEntityPruned: {}
            )
            .padding()
        }
    }

    #Preview("Entity Acquisition · Wanted, No Acquisition") {
        EntityAcquisitionPanel(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            acquisitionService: PreviewEntityAcquisitionService(
                snapshot: EntityAcquisitionPanelPreviewFixtures.wantedState
            ),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
    }

    #Preview("Entity Acquisition · Active Group") {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                childGroups: [EntityAcquisitionPanelPreviewFixtures.childGroup],
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.groupingState,
                    additionalSnapshots: EntityAcquisitionPanelPreviewFixtures.childStates
                ),
                onMutated: {},
                onEntityPruned: {}
            )
            .padding()
        }
    }

    #Preview("Entity Acquisition · Paused") {
        EntityAcquisitionPanel(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            acquisitionService: PreviewEntityAcquisitionService(
                snapshot: EntityAcquisitionPanelPreviewFixtures.pausedState
            ),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
    }

    #Preview("Entity Acquisition · Unavailable") {
        EntityAcquisitionPanel(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            acquisitionService: PreviewEntityAcquisitionService(
                snapshot: EntityAcquisitionPanelPreviewFixtures.unavailableState
            ),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
    }

    #Preview("Entity Acquisition · Stopping") {
        EntityAcquisitionPanel(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            acquisitionService: PreviewEntityAcquisitionService(
                snapshot: EntityAcquisitionPanelPreviewFixtures.stoppingState
            ),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
    }

    #Preview("Entity Acquisition · Unknown") {
        EntityAcquisitionPanel(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            acquisitionService: PreviewEntityAcquisitionService(
                snapshot: EntityAcquisitionPanelPreviewFixtures.unknownState
            ),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("Entity Acquisition · Error") {
        EntityAcquisitionPanel(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            acquisitionService: PreviewEntityAcquisitionService(
                snapshot: EntityAcquisitionPanelPreviewFixtures.wantedState,
                loadError: "The server is unreachable."
            ),
            onMutated: {},
            onEntityPruned: {}
        )
        .padding()
    }
#endif
