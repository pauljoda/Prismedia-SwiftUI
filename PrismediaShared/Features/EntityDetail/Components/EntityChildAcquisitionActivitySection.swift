import SwiftUI

struct EntityChildAcquisitionActivitySection: View {
    @Environment(\.prismediaPageIsActive) private var pageIsActive
    @Environment(\.scenePhase) private var scenePhase
    @State private var isExpanded: Bool
    @State private var hasLoaded: Bool
    @State private var items: [EntityChildAcquisitionActivityItem]
    @State private var errorMessage: String?
    let entities: [EntityThumbnail]
    let service: EntityAcquisitionService
    let onChanged: @MainActor () async -> Void
    #if DEBUG
        private var disablesLiveLoadingForPreview = false
    #endif

    init(
        entities: [EntityThumbnail],
        service: EntityAcquisitionService,
        onChanged: @escaping @MainActor () async -> Void
    ) {
        self.entities = entities
        self.service = service
        self.onChanged = onChanged
        _isExpanded = State(initialValue: Self.hasInitialAttention(in: entities))
        _hasLoaded = State(initialValue: false)
        _items = State(initialValue: [])
        _errorMessage = State(initialValue: nil)
    }

    #if DEBUG
        init(
            previewItems: [EntityChildAcquisitionActivityItem],
            service: EntityAcquisitionService,
            isExpanded: Bool = true,
            hasLoaded: Bool = true,
            errorMessage: String? = nil
        ) {
            self.entities = previewItems.map(\.entity)
            self.service = service
            onChanged = {}
            _isExpanded = State(initialValue: isExpanded)
            _hasLoaded = State(initialValue: hasLoaded)
            _items = State(initialValue: previewItems)
            _errorMessage = State(initialValue: errorMessage)
            disablesLiveLoadingForPreview = true
        }
    #endif

    var body: some View {
        #if os(tvOS)
            EmptyView()
        #else
            disclosureContent
        #endif
    }

    #if !os(tvOS)
        private var disclosureContent: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    if !hasLoaded {
                        PrismediaLoadingView("Loading child activity…")
                    } else if orderedItems.isEmpty, errorMessage == nil {
                        Label("No child acquisition activity right now.", systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(orderedItems) { item in
                            EntityChildAcquisitionActivityRow(item: item)
                            if item.id != orderedItems.last?.id { Divider() }
                        }
                    }

                    if let errorMessage {
                        EntityAcquisitionMessageCard(
                            title: "Couldn’t Refresh Child Activity",
                            message: errorMessage,
                            retryTitle: "Reload",
                            onRetry: {
                                Task {
                                    await load(
                                        preservingContent: hasLoaded,
                                        reportsError: true
                                    )
                                }
                            },
                            onDismiss: { self.errorMessage = nil }
                        )
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PrismediaSpacing.small) { sectionLabel }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) { sectionLabel }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isHeader)
            }
            .task(id: liveTaskIdentity) {
                #if DEBUG
                    guard !disablesLiveLoadingForPreview else { return }
                #endif
                guard liveRefreshIsActive else { return }

                if !hasLoaded || isExpanded || EntityChildAcquisitionActivityPolicy.shouldPoll(items) {
                    await load(
                        preservingContent: hasLoaded,
                        reportsError: !hasLoaded || isExpanded
                    )
                }

                while !Task.isCancelled,
                    liveRefreshIsActive,
                    isExpanded || EntityChildAcquisitionActivityPolicy.shouldPoll(items)
                {
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    guard !Task.isCancelled else { return }
                    await load(preservingContent: true, reportsError: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("entity-detail.acquisition.child-activity")
        }

        @ViewBuilder
        private var sectionLabel: some View {
            Label("Child Activity", systemImage: "arrow.down.circle")
                .font(.headline)
                .foregroundStyle(PrismediaColor.textPrimary)
            Text(summaryLabel)
                .font(.caption.monospacedDigit())
                .foregroundStyle(summaryForegroundStyle)
        }
    #endif

    private var orderedItems: [EntityChildAcquisitionActivityItem] {
        EntityChildAcquisitionActivityPolicy.orderedItems(items)
    }

    private var attentionCount: Int {
        orderedItems.count(where: EntityChildAcquisitionActivityPolicy.isAttentionRequired)
    }

    private var activeCount: Int {
        orderedItems.count { item in
            item.isPreparingMetadata
                || RequestActivityStatusPolicy.shouldPoll(item.acquisition?.status)
        }
    }

    private var summaryLabel: String {
        guard hasLoaded else { return "Loading" }
        if errorMessage != nil, orderedItems.isEmpty { return "Unavailable" }
        if attentionCount > 0, activeCount > 0 {
            return "\(attentionCount) need attention · \(activeCount) active"
        }
        if attentionCount > 0 { return "\(attentionCount) need attention" }
        if activeCount > 0 { return "\(activeCount) active" }
        return "Quiet"
    }

    private var summaryForegroundStyle: Color {
        if errorMessage != nil || attentionCount > 0 { return PrismediaColor.warning }
        if activeCount > 0 { return PrismediaColor.accent }
        return PrismediaColor.textMuted
    }

    private func load(preservingContent: Bool, reportsError: Bool) async {
        let previouslyLoaded = hasLoaded
        let previousItemsByID = Dictionary(
            uniqueKeysWithValues: items.map { ($0.id, $0) }
        )

        do {
            let states = try await service.loadStates(entityIDs: entities.map(\.id))
            guard !Task.isCancelled else { return }
            let statesByID = Dictionary(
                states.map { ($0.entityID, $0) },
                uniquingKeysWith: { _, latest in latest }
            )
            let nextItems = entities.compactMap { entity in
                statesByID[entity.id].map {
                    EntityChildAcquisitionActivityItem(entity: entity, state: $0)
                }
            }
            let importedDuringRefresh = previouslyLoaded && nextItems.contains { nextItem in
                guard nextItem.acquisition?.status.rawValue == "imported",
                    let previousStatus = previousItemsByID[nextItem.id]?.acquisition?.status
                else { return false }
                return RequestActivityStatusPolicy.shouldPoll(previousStatus)
            }

            items = nextItems
            hasLoaded = true
            errorMessage = nil
            if !previouslyLoaded,
                EntityChildAcquisitionActivityPolicy.shouldAutoExpand(nextItems)
            {
                isExpanded = true
            }
            if importedDuringRefresh { await onChanged() }
        } catch is CancellationError {
            return
        } catch {
            if reportsError || !preservingContent || !hasLoaded {
                errorMessage = error.localizedDescription
            }
            hasLoaded = true
        }
    }

    private var liveRefreshIsActive: Bool {
        pageIsActive && scenePhase == .active
    }

    private var liveTaskIdentity: String {
        "\(isExpanded)-\(liveRefreshIsActive)-\(entities.map(\.id).hashValue)"
    }

    private static func hasInitialAttention(in entities: [EntityThumbnail]) -> Bool {
        entities.contains { entity in
            let statuses = [entity.latestAcquisitionStatus, entity.wantedStatus].compactMap { $0 }
            return statuses.contains { status in
                RequestActivityStatusPolicy.shouldPoll(status)
                    || status.rawValue == "awaiting-selection"
                    || status.rawValue == "failed"
                    || status.rawValue == "manual-import-required"
            }
        }
    }
}

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Child Acquisition Activity Section") {
        PreviewShell {
            NavigationStack {
                EntityChildAcquisitionActivitySection(
                    previewItems: EntityChildAcquisitionActivityPreviewFixtures.simultaneousItems,
                    service: EntityChildAcquisitionActivityPreviewFixtures.service
                )
                .padding()
            }
        }
        .environment(\.prismediaPageIsActive, false)
    }
#endif
