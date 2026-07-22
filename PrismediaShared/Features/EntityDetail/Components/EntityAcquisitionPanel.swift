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
    private let entityID: UUID
    private let service: EntityAcquisitionService?
    private let requestActivityService: (any RequestActivityServicing)?
    private let onMutated: @MainActor () async -> Void
    private let onEntityPruned: @MainActor () -> Void

    init(
        entityID: UUID,
        acquisitionService: (any EntityAcquisitionServicing)?,
        requestActivityService: (any RequestActivityServicing)? = nil,
        onMutated: @escaping @MainActor () async -> Void,
        onEntityPruned: @escaping @MainActor () -> Void
    ) {
        self.entityID = entityID
        service = acquisitionService.map(EntityAcquisitionService.init(port:))
        self.requestActivityService = requestActivityService
        self.onMutated = onMutated
        self.onEntityPruned = onEntityPruned
    }

    var body: some View {
        Group {
            if let service {
                switch state.phase {
                case .loading:
                    ProgressView("Loading acquisition status…")
                        .frame(maxWidth: .infinity, minHeight: 150)
                case .failure(let message):
                    failureView(message, service: service)
                case .content(let snapshot):
                    contentView(snapshot, service: service)
                }
            } else {
                adminUnavailableView
            }
        }
        .task(id: liveRefreshTaskIdentity) {
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
        .alert("Couldn’t Update Acquisition", isPresented: mutationErrorPresented) {
            Button("OK", role: .cancel) { state.dismissMutationError() }
        } message: {
            Text(state.mutationError ?? "Please try again.")
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

    private func failureView(
        _ message: String,
        service: EntityAcquisitionService
    ) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Acquisition", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent) {
                Task { await load(using: service) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func contentView(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            monitorToggle(snapshot.state, service: service)

            if displayedMonitorValue(snapshot.state) {
                expandedContent(snapshot, service: service)
            }
        }
        .padding(PrismediaSpacing.extraLarge)
        .prismediaCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func expandedContent(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        guidanceContent(snapshot)

        if hasPanelActions(snapshot) {
            actionContent(snapshot, service: service)
        }

        #if os(iOS) || os(macOS)
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
                    }
                )
                .id(acquisition.summary.id)
            } else {
                fallbackContent(snapshot)
            }

            if !historyEntries.isEmpty {
                Divider()
                EntityAcquisitionHistorySection(entries: historyEntries)
            }
        #else
            fallbackContent(snapshot)
        #endif
    }

    // MARK: - Actions

    private func actionContent(
        _ snapshot: EntityAcquisitionPanelSnapshot,
        service: EntityAcquisitionService
    ) -> some View {
        ViewThatFits(in: .horizontal) {
            GlassEffectContainer(spacing: PrismediaSpacing.small) {
                HStack(spacing: PrismediaSpacing.small) {
                    actionButtons(snapshot, service: service)
                    mutationProgress
                }
            }
            GlassEffectContainer(spacing: PrismediaSpacing.small) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    actionButtons(snapshot, service: service)
                    mutationProgress
                }
            }
        }
        .prismediaCompactActionControlSize()
        .disabled(state.isMutating)
    }

    @ViewBuilder
    private var mutationProgress: some View {
        if state.isMutating {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Updating acquisition")
        }
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
                primaryTint: artworkPrimaryAccent
            ) {
                Task { await perform(.searchForRelease(entityID), using: service) }
            }
        }

        if !embedsManagement(snapshot), let acquisition = snapshot.state.latestAcquisition {
            PrismediaButton("Search Again", systemImage: "arrow.clockwise") {
                Task { await perform(.searchAgain(acquisition.id), using: service) }
            }
        }
    }

    private func monitorToggle(
        _ monitorState: EntityMonitorState,
        service: EntityAcquisitionService
    ) -> some View {
        Toggle(
            "Monitor",
            isOn: Binding(
                get: { displayedMonitorValue(monitorState) },
                set: { nextValue in
                    updateMonitor(
                        to: nextValue,
                        monitorState: monitorState,
                        service: service
                    )
                }
            )
        )
        .disabled(state.isMutating || monitorToggleIsLocked(monitorState))
        .accessibilityHint(
            displayedMonitorValue(monitorState)
                ? "Turns off monitoring after confirmation"
                : "Turns on monitoring for this item"
        )
    }

    private func updateMonitor(
        to nextValue: Bool,
        monitorState: EntityMonitorState,
        service: EntityAcquisitionService
    ) {
        guard nextValue != displayedMonitorValue(monitorState) else { return }

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

    private func displayedMonitorValue(_ monitorState: EntityMonitorState) -> Bool {
        guard let status = monitorState.monitor?.status else {
            return pendingMonitorValue ?? false
        }
        return pendingMonitorValue ?? (status == .active || status == .deletingFiles)
    }

    private func monitorToggleIsLocked(_ monitorState: EntityMonitorState) -> Bool {
        guard let monitor = monitorState.monitor else { return !monitorState.canMonitor }
        return isMonitorTransitionLocked(monitor.status)
    }

    // MARK: - Guidance lines

    @ViewBuilder
    private func guidanceContent(_ snapshot: EntityAcquisitionPanelSnapshot) -> some View {
        let monitorState = snapshot.state
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            if showsMonitorControl(monitorState), !monitorState.trackableProviders.isEmpty {
                Text(trackedViaLine(monitorState))
                    .font(.caption)
                    .foregroundStyle(artworkSecondaryText)
            } else if monitorState.monitor == nil, !monitorState.canMonitor,
                monitorState.trackableProviders.isEmpty
            {
                Text(
                    "No enabled metadata provider can track this entity yet. Identify it with a supported provider first."
                )
                .font(.caption)
                .foregroundStyle(artworkSecondaryText)
            }

            if showsSearchForRelease(snapshot) {
                Text("No file yet. Searching starts an auto-grabbing, monitored acquisition for this item.")
                    .font(.caption)
                    .foregroundStyle(artworkSecondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func trackedViaLine(_ monitorState: EntityMonitorState) -> String {
        let via = monitorState.trackableProviders.joined(separator: ", ")
        if monitorState.monitor?.status == .deletingFiles {
            return "Tracking stays enabled via \(via) while files are deleted."
        }
        if monitorState.monitor?.status == .active {
            if monitorState.discoversChildren {
                return "Checked daily for new works via \(via)."
            }
            return "Tracked via \(via)."
        }
        return "Tracking is available via \(via)."
    }

    // MARK: - Gates

    private func showsMonitorControl(_ monitorState: EntityMonitorState) -> Bool {
        monitorState.monitor != nil || monitorState.canMonitor
    }

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

    private func isUnknownMonitorStatus(_ status: EntityMonitorStatus) -> Bool {
        ![.active, .paused, .fulfilled, .deletingFiles, .stopping].contains(status)
    }

    private func isMonitorTransitionLocked(_ status: EntityMonitorStatus) -> Bool {
        status == .stopping || status == .deletingFiles || isUnknownMonitorStatus(status)
    }

    // MARK: - Fallback summary (tvOS and missing request-activity service)

    @ViewBuilder
    private func fallbackContent(_ snapshot: EntityAcquisitionPanelSnapshot) -> some View {
        if snapshot.state.monitor != nil || snapshot.state.latestAcquisition != nil {
            Divider()
            summaryFallback(snapshot)
        }
    }

    @ViewBuilder
    private func summaryFallback(_ snapshot: EntityAcquisitionPanelSnapshot) -> some View {
        if let monitor = snapshot.state.monitor {
            monitorContent(monitor)
        }
        if let acquisition = snapshot.state.latestAcquisition {
            acquisitionContent(acquisition)
        }
    }

    private func monitorContent(_ monitor: EntityMonitor) -> some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Text("Monitor")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            LabeledContent("Status", value: monitor.status.displayName)
            LabeledContent("Preset", value: monitor.preset.displayName)
            LabeledContent("Updated", value: monitor.updatedAt.formatted(date: .abbreviated, time: .shortened))
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
        await loadHistory()
    }

    private func backgroundLoad(using service: EntityAcquisitionService) async {
        let outcome = await service.load(entityID: entityID)
        state.finishBackgroundLoad(outcome)
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
        guard state.beginMutation() else { return }
        let outcome = await service.perform(command)
        switch state.finishMutation(outcome) {
        case .entityPruned:
            onEntityPruned()
        case .refresh:
            await load(using: service)
            await onMutated()
        case .none:
            break
        }
    }

    private func performMonitorMutation(
        _ command: EntityAcquisitionCommand,
        pendingValue: Bool,
        using service: EntityAcquisitionService
    ) async {
        pendingMonitorValue = pendingValue
        await perform(command, using: service)
        pendingMonitorValue = nil
    }

    private var mutationErrorPresented: Binding<Bool> {
        Binding(
            get: { state.mutationError != nil },
            set: { isPresented in
                if !isPresented { state.dismissMutationError() }
            }
        )
    }
}

extension EntityMonitorStatus {
    fileprivate var displayName: String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

extension AcquisitionStatus {
    fileprivate var displayName: String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}

extension String {
    fileprivate var displayName: String {
        replacingOccurrences(of: "-", with: " ").capitalized
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
