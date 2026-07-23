import SwiftUI

#if canImport(Accessibility)
    import Accessibility
#endif

struct EntityAcquisitionPanel: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.prismediaPageIsActive) private var pageIsActive
    @Environment(\.scenePhase) private var scenePhase
    @State private var state = EntityAcquisitionPanelState()
    @State private var confirmsUnmonitor = false
    @State private var confirmsDeleteFiles = false
    @State private var historyEntries: [RequestActivityHistoryEntry] = []
    @State private var pendingMonitorValue: Bool?
    @State private var confirmedMonitorValue: Bool?
    @State private var activeCommand: EntityAcquisitionCommand?
    @State private var failedCommand: EntityAcquisitionCommand?
    @State private var failedPendingMonitorValue: Bool?
    @State private var actionNotice: String?
    @State private var deletionResult: EntityDeleteResponse?
    @State private var savedMutationCommand: EntityAcquisitionCommand?
    @State private var isManualAcquisitionBusy = false
    @State private var didAnnounceFailedParentActivity = false
    @State private var previousActiveChildAcquisitionCount: Int?
    @State private var liveChildActivityEntityIDs: Set<UUID>?
    @State private var liveActiveChildAcquisitionIDs: Set<UUID>?
    private let entityID: UUID
    private let entityTitle: String
    private let entityKind: EntityKind
    private let hasOwnedContent: Bool
    private let canDeleteFiles: Bool
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
        entityTitle: String = "this item",
        entityKind: EntityKind = .book,
        hasOwnedContent: Bool = false,
        canDeleteFiles: Bool = false,
        childGroups: [EntityGroup] = [],
        acquisitionService: (any EntityAcquisitionServicing)?,
        requestActivityService: (any RequestActivityServicing)? = nil,
        onMutated: @escaping @MainActor () async -> Void,
        onEntityPruned: @escaping @MainActor () -> Void
    ) {
        self.entityID = entityID
        self.entityTitle = entityTitle
        self.entityKind = entityKind
        self.hasOwnedContent = hasOwnedContent
        self.canDeleteFiles = canDeleteFiles
        self.childGroups = childGroups
        service = acquisitionService.map(EntityAcquisitionService.init(port:))
        self.requestActivityService = requestActivityService
        self.onMutated = onMutated
        self.onEntityPruned = onEntityPruned
    }

    #if DEBUG
        init(
            entityID: UUID,
            entityTitle: String = "Preview Item",
            entityKind: EntityKind = .book,
            hasOwnedContent: Bool = false,
            canDeleteFiles: Bool = false,
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
            deletionResult: EntityDeleteResponse? = nil,
            savedMutationCommand: EntityAcquisitionCommand? = nil,
            confirmsUnmonitor: Bool = false,
            confirmsDeleteFiles: Bool = false,
            onMutated: @escaping @MainActor () async -> Void = {},
            onEntityPruned: @escaping @MainActor () -> Void = {}
        ) {
            self.init(
                entityID: entityID,
                entityTitle: entityTitle,
                entityKind: entityKind,
                hasOwnedContent: hasOwnedContent,
                canDeleteFiles: canDeleteFiles,
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
            _deletionResult = State(initialValue: deletionResult)
            _savedMutationCommand = State(initialValue: savedMutationCommand)
            _confirmsUnmonitor = State(initialValue: confirmsUnmonitor)
            _confirmsDeleteFiles = State(initialValue: confirmsDeleteFiles)
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
            unmonitorConfirmationTitle,
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
            Text(unmonitorConfirmationMessage)
        }
        .alert(
            "Delete files for \(entityTitle)?",
            isPresented: $confirmsDeleteFiles
        ) {
            Button("Delete Files", role: .destructive) {
                guard let service else { return }
                Task {
                    await perform(
                        .deleteFiles(entityID),
                        using: service
                    )
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(deleteFilesConfirmationMessage)
        }
        .accessibilityIdentifier("entity-detail.acquisition")
        .onChange(of: failedParentAccessibilityIdentity, initial: true) {
            updateFailedParentAccessibilityAnnouncements()
        }
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
            confirmedValue: confirmedMonitorValue,
            preservesExpandedContentWhileBusy: activeCommand == .deleteFiles(entityID)
        )

        return VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
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
                .frame(maxWidth: .infinity, alignment: .leading)

                #if os(iOS) || os(macOS)
                    if showsStandaloneDeletionMenu(
                        snapshot: snapshot,
                        presentation: presentation
                    ) {
                        RequestActivityAcquisitionActionMenu(
                            lifecycleActions: [],
                            showsDeleteFiles: true,
                            isLifecycleDisabled: true,
                            isDeleteFilesDisabled: deleteFilesIsDisabled(
                                monitorState: monitorState
                            ),
                            onPerform: { _ in },
                            onDeleteFiles: { confirmsDeleteFiles = true }
                        )
                    }
                #endif
            }

            messageContent(
                presentation: presentation,
                monitorState: monitorState,
                service: service,
                loadError: loadError
            )

            if activeCommand == .deleteFiles(entityID) {
                HStack(spacing: PrismediaSpacing.small) {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("Deleting Files")
                            .font(.headline)
                            .foregroundStyle(PrismediaColor.textPrimary)
                        Text("Removing managed source files while keeping safe acquisition content visible.")
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }
                .accessibilityElement(children: .combine)
            }

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
                message: mutationErrorMessage(mutationError),
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
                    deletionResult = nil
                }
            )
        }

        if let refreshError = state.refreshError {
            EntityAcquisitionMessageCard(
                title: savedMutationCommand == .deleteFiles(entityID)
                    ? "Files Deleted"
                    : "Monitoring Updated",
                message: savedMutationCommand == .deleteFiles(entityID)
                    ? "The managed files were deleted, but this page couldn’t refresh the updated Wanted state. \(refreshError)"
                    : "The change was saved, but this page couldn’t refresh. \(refreshError)",
                isWarning: true,
                retryTitle: "Refresh",
                onRetry: { Task { await retryRefresh(using: service) } },
                onDismiss: { state.dismissRefreshError() }
            )
        }

        if let deletionResult,
            deletionResult.failures.isEmpty,
            deletionResult.reverted > 0
        {
            EntityAcquisitionMessageCard(
                title: "Files Deleted",
                message: deleteFilesCompletionMessage(deletionResult),
                isInformational: true,
                onDismiss: { self.deletionResult = nil }
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
        let eligibleChildren = eligibleChildActivityEntities
        let activeChildren = activeChildAcquisitionEntities
        let demotesFailedParent = EntityFailedParentAcquisitionPolicy.shouldDemoteParent(
            status: parentAcquisitionStatus,
            activeChildren: activeChildren
        )

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

            // Stable IDs retain each section's local disclosure/loading state when the
            // parent lifecycle moves behind active child work and later returns first.
            ForEach(
                EntityAcquisitionPanelSection.ordered(
                    demotesFailedParent: demotesFailedParent
                )
            ) { section in
                switch section {
                case .parentAcquisition:
                    if hasParentAcquisitionContent(snapshot) {
                        Divider()
                        if demotesFailedParent {
                            EntityFailedParentAcquisitionSection(
                                activeSummary: EntityFailedParentAcquisitionPolicy.activeSummary(
                                    activeChildren: activeChildren,
                                    eligibleChildren: eligibleChildren
                                )
                            ) {
                                parentAcquisitionContent(snapshot, service: service)
                            }
                        } else {
                            parentAcquisitionContent(snapshot, service: service)
                        }
                    }
                case .childMonitoring:
                    childMonitoringContent(snapshot.state, service: service)
                case .childActivity:
                    childActivityContent(service: service)
                }
            }

            Divider()
            EntityAcquisitionHistorySection(
                entries: historyEntries,
                entityID: entityID,
                service: service
            )
        #else
            fallbackContent(snapshot)
        #endif
    }

    #if os(iOS) || os(macOS)
        @ViewBuilder
        private func parentAcquisitionContent(
            _ snapshot: EntityAcquisitionPanelSnapshot,
            service: EntityAcquisitionService
        ) -> some View {
            if let acquisition = snapshot.latestAcquisition, let requestActivityService {
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
                    isExternallyDisabled: isManualAcquisitionBusy || state.isMutating,
                    showsDeleteFilesAction: canDeleteFiles,
                    isDeleteFilesDisabled: deleteFilesIsDisabled(
                        monitorState: snapshot.state
                    ),
                    onDeleteFiles: { confirmsDeleteFiles = true }
                )
                .id(acquisition.summary.id)
            } else if snapshot.state.latestAcquisition != nil {
                summaryFallback(snapshot)
            }
        }

        private func hasParentAcquisitionContent(
            _ snapshot: EntityAcquisitionPanelSnapshot
        ) -> Bool {
            (snapshot.latestAcquisition != nil && requestActivityService != nil)
                || snapshot.state.latestAcquisition != nil
        }

        @ViewBuilder
        private func childMonitoringContent(
            _ monitorState: EntityMonitorState,
            service: EntityAcquisitionService
        ) -> some View {
            if monitorState.discoversChildren,
                !monitoringChildren(for: monitorState).isEmpty
            {
                Divider()
                EntityChildMonitoringSection(
                    title: childMonitoringTitle(for: monitorState),
                    entities: monitoringChildren(for: monitorState),
                    primaryAccent: artworkPrimaryAccent,
                    service: service,
                    onChanged: onMutated
                )
            }
        }
    #endif

    private func groupingContent(
        _ monitorState: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        EntityAcquisitionGroupingActions(
            monitoringScope: monitorState.monitor.map { scopeLabel($0.preset) },
            canSearchMissingChildren: monitorState.canSearchMissingChildren,
            missingChildCount: missingChildCount(for: monitorState),
            isChecking: activeCommand == .syncContainer(entityID),
            isSearching: activeCommand == .searchMissingChildren(entityID),
            isDisabled: state.isMutating || isManualAcquisitionBusy,
            onCheck: { requestPerform(.syncContainer(entityID), using: service) },
            onSearchMissing: {
                requestPerform(.searchMissingChildren(entityID), using: service)
            }
        )
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
        let children = eligibleChildActivityEntities
        if !children.isEmpty {
            Divider()
            EntityChildAcquisitionActivitySection(
                entities: children,
                service: service,
                onChanged: onMutated,
                onSnapshotChanged: receiveChildActivitySnapshot
            )
        }
    }

    private var eligibleChildActivityEntities: [EntityThumbnail] {
        EntityChildAcquisitionActivityPolicy.eligibleChildren(
            parentID: entityID,
            groups: childGroups
        )
    }

    private var activeChildAcquisitionEntities: [EntityThumbnail] {
        let initialChildren = EntityFailedParentAcquisitionPolicy.activeChildren(
            parentID: entityID,
            groups: childGroups
        )
        let eligibleChildren = eligibleChildActivityEntities
        guard liveChildActivityEntityIDs == Set(eligibleChildren.map(\.id)),
            let liveActiveChildAcquisitionIDs
        else { return initialChildren }
        return eligibleChildren.filter { liveActiveChildAcquisitionIDs.contains($0.id) }
    }

    private func receiveChildActivitySnapshot(
        _ items: [EntityChildAcquisitionActivityItem]
    ) {
        liveChildActivityEntityIDs = Set(eligibleChildActivityEntities.map(\.id))
        liveActiveChildAcquisitionIDs = Set(
            items.filter { item in
                item.isPreparingMetadata
                    || RequestActivityStatusPolicy.shouldPoll(item.acquisition?.status)
            }
            .map(\.id)
        )
    }

    private var parentAcquisitionStatus: AcquisitionStatus? {
        guard case .content(let snapshot) = state.phase else { return nil }
        return snapshot.latestAcquisition?.summary.status
            ?? snapshot.state.latestAcquisition?.status
    }

    private var failedParentAccessibilityIdentity: String {
        "\(liveRefreshIsActive)-\(parentAcquisitionStatus?.rawValue ?? "none")-\(activeChildAcquisitionEntities.count)"
    }

    private func updateFailedParentAccessibilityAnnouncements() {
        let activeChildren = activeChildAcquisitionEntities
        let previousCount = previousActiveChildAcquisitionCount
        previousActiveChildAcquisitionCount = activeChildren.count

        guard parentAcquisitionStatus?.rawValue == "failed" else {
            didAnnounceFailedParentActivity = false
            return
        }

        guard !activeChildren.isEmpty else {
            if liveRefreshIsActive,
                didAnnounceFailedParentActivity,
                previousCount.map({ $0 > 0 }) == true
            {
                postAccessibilityAnnouncement(
                    EntityFailedParentAcquisitionPolicy.accessibilityCompletionMessage
                )
            }
            didAnnounceFailedParentActivity = false
            return
        }

        guard liveRefreshIsActive, !didAnnounceFailedParentActivity else { return }
        postAccessibilityAnnouncement(
            EntityFailedParentAcquisitionPolicy.accessibilityEntryMessage(
                activeChildren: activeChildren,
                eligibleChildren: eligibleChildActivityEntities
            )
        )
        didAnnounceFailedParentActivity = true
    }

    private func postAccessibilityAnnouncement(_ message: String) {
        #if (os(iOS) || os(macOS)) && canImport(Accessibility)
            AccessibilityNotification.Announcement(message).post()
        #endif
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
        let searchAgainAcquisitionID = snapshot.state.latestAcquisition?.id
        return EntityAcquisitionActions(
            showsSearchForRelease: showsSearchForRelease(snapshot),
            showsSearchAgain: !embedsManagement(snapshot)
                && searchAgainAcquisitionID != nil,
            isSearchingForRelease: activeCommand == .searchForRelease(entityID),
            isSearchingAgain: searchAgainAcquisitionID.map {
                activeCommand == .searchAgain($0)
            } ?? false,
            primaryTint: artworkPrimaryAccent,
            isDisabled: state.isMutating || activeCommand != nil || isManualAcquisitionBusy,
            onSearchForRelease: {
                requestPerform(.searchForRelease(entityID), using: service)
            },
            onSearchAgain: {
                guard let searchAgainAcquisitionID else { return }
                requestPerform(.searchAgain(searchAgainAcquisitionID), using: service)
            }
        )
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

    private var unmonitorConfirmationTitle: String {
        guard let rendition = currentMonitorRendition else {
            return "Stop monitoring this item?"
        }
        return "Stop monitoring this \(renditionLabel(rendition)) rendition?"
    }

    private var unmonitorConfirmationMessage: String {
        guard let rendition = currentMonitorRendition else {
            return "This removes monitor intent, acquisition state, and reachable download data for this item and its acquisition-only children. Existing library media and history remain. Fileless wanted placeholders may be removed, and automatic rediscovery stops."
        }
        return "This stops monitoring only the \(renditionLabel(rendition)) rendition and removes that rendition’s acquisition and reachable download state. Other rendition monitoring, existing library files, and history remain."
    }

    private var currentMonitorRendition: RequestActivityBookRendition? {
        guard case .content(let snapshot) = state.phase else { return nil }
        return snapshot.state.monitor?.bookRendition
    }

    private func renditionLabel(_ rendition: RequestActivityBookRendition) -> String {
        rendition.rawValue == "audiobook" ? "audiobook" : "ebook"
    }

    private var deleteFilesConfirmationMessage: String {
        let scope =
            entityKind == .book
            ? "This permanently deletes every managed source file for “\(entityTitle)” and its structural children, which can include both ebook and audiobook files."
            : "This permanently deletes every managed source file for “\(entityTitle)” and its structural children."
        return "\(scope) Directly monitored content returns to Wanted and starts a clean search; unmonitored content is removed from the library. Acquisition history remains. This can’t be undone."
    }

    // MARK: - Gates

    private func hasPanelActions(_ snapshot: EntityAcquisitionPanelSnapshot) -> Bool {
        showsSearchForRelease(snapshot)
            || (!embedsManagement(snapshot) && snapshot.state.latestAcquisition != nil)
    }

    private func showsStandaloneDeletionMenu(
        snapshot: EntityAcquisitionPanelSnapshot?,
        presentation: EntityMonitorPresentation
    ) -> Bool {
        guard canDeleteFiles else { return false }
        guard let snapshot else { return true }
        return !presentation.showsExpandedContent || !embedsManagement(snapshot)
    }

    private func deleteFilesIsDisabled(
        monitorState: EntityMonitorState?
    ) -> Bool {
        guard !state.isMutating,
            activeCommand == nil,
            !isManualAcquisitionBusy,
            let monitorState
        else { return true }
        guard let monitor = monitorState.monitor else { return false }
        return ![.active, .paused, .fulfilled].contains(monitor.status)
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
        EntityAcquisitionSummaryView(acquisition: acquisition)
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

    private func requestPerform(
        _ command: EntityAcquisitionCommand,
        using service: EntityAcquisitionService
    ) {
        Task { await perform(command, using: service) }
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
        if command == .deleteFiles(entityID) {
            deletionResult = nil
            postAccessibilityAnnouncement("Deleting managed files.")
        } else if case .unmonitor = command {
            postAccessibilityAnnouncement("Stopping monitoring and cleaning up acquisition data.")
        }
        pendingMonitorValue = nextMonitorValue
        let outcome = await service.perform(command)

        if case .missingChildrenSearchCompleted(let result) = outcome {
            actionNotice = missingChildrenResultMessage(result)
        }
        if case .filesDeleted(let result) = outcome {
            deletionResult = result
        }

        switch state.finishMutation(outcome) {
        case .entityPruned:
            pendingMonitorValue = nil
            postAccessibilityAnnouncement(prunedEntityAnnouncement(for: command))
            onEntityPruned()
        case .refresh:
            savedMutationCommand = command
            if let nextMonitorValue { confirmedMonitorValue = nextMonitorValue }
            pendingMonitorValue = nil
            let refreshOutcome = await service.load(
                entityID: entityID,
                fallbackAcquisition: state.latestAcquisition
            )
            if state.finishMutationRefresh(refreshOutcome) {
                confirmedMonitorValue = nil
                savedMutationCommand = nil
            }
            await loadHistory()
            await onMutated()
        case .none:
            pendingMonitorValue = nil
            if case .failure = outcome {
                failedCommand = command
                failedPendingMonitorValue = nextMonitorValue
                postAccessibilityAnnouncement(mutationFailureAnnouncement(for: command))
            } else if case .filesDeleted(let response) = outcome,
                !response.failures.isEmpty
            {
                failedCommand = command
                postAccessibilityAnnouncement("Some files could not be deleted. Retry is available.")
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
            savedMutationCommand = nil
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
        case .deleteFiles:
            return "Couldn’t Delete Files"
        case .searchForRelease, .searchAgain:
            return "Couldn’t Start Search"
        default:
            return "Couldn’t Update Monitoring"
        }
    }

    private func mutationErrorMessage(_ fallback: String) -> String {
        guard failedCommand == .deleteFiles(entityID),
            let deletionResult,
            !deletionResult.failures.isEmpty
        else { return fallback }
        let removed = deleteFilesRemovedSummary(deletionResult)
        return "\(removed) Prismedia couldn’t finish deleting every scoped file. Retry Delete Files to continue cleanup.\n\(fallback)"
    }

    private func deleteFilesCompletionMessage(
        _ response: EntityDeleteResponse
    ) -> String {
        "\(deleteFilesRemovedSummary(response)) Monitoring remains on, so the item is Wanted and a clean search is starting. Acquisition history remains."
    }

    private func deleteFilesRemovedSummary(
        _ response: EntityDeleteResponse
    ) -> String {
        let pathLabel = response.filesDeleted == 1 ? "managed file path" : "managed file paths"
        return "Removed \(response.filesDeleted) \(pathLabel)."
    }

    private func mutationFailureAnnouncement(
        for command: EntityAcquisitionCommand
    ) -> String {
        switch command {
        case .deleteFiles:
            return "Files could not be deleted. Retry is available."
        case .unmonitor:
            return "Monitoring cleanup failed. Retry is available."
        default:
            return "The acquisition action failed. Retry is available."
        }
    }

    private func prunedEntityAnnouncement(
        for command: EntityAcquisitionCommand
    ) -> String {
        switch command {
        case .deleteFiles:
            return "Files deleted. Closing this item."
        case .unmonitor:
            return "Monitoring stopped. Closing this item."
        default:
            return "The item was removed. Closing this view."
        }
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
