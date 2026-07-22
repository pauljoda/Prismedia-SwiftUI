import SwiftUI

struct EntityChildMonitoringSection: View {
    @Environment(\.prismediaPageIsActive) private var pageIsActive
    @Environment(\.scenePhase) private var scenePhase
    @State private var isExpanded = false
    @State private var hasLoaded = false
    @State private var items: [EntityChildMonitoringItem] = []
    @State private var busyIDs: Set<UUID> = []
    @State private var isBulkMutating = false
    @State private var errorMessage: String?
    let title: String
    let entities: [EntityThumbnail]
    let primaryAccent: Color
    let service: EntityAcquisitionService
    let onChanged: @MainActor () async -> Void
    #if DEBUG
        private var disablesLiveLoadingForPreview = false
    #endif

    init(
        title: String,
        entities: [EntityThumbnail],
        primaryAccent: Color,
        service: EntityAcquisitionService,
        onChanged: @escaping @MainActor () async -> Void
    ) {
        self.title = title
        self.entities = entities
        self.primaryAccent = primaryAccent
        self.service = service
        self.onChanged = onChanged
    }

    #if DEBUG
        init(
            title: String,
            previewItems: [EntityChildMonitoringItem],
            primaryAccent: Color,
            service: EntityAcquisitionService,
            hasLoaded: Bool = true,
            busyIDs: Set<UUID> = [],
            errorMessage: String? = nil
        ) {
            self.init(
                title: title,
                entities: previewItems.map(\.entity),
                primaryAccent: primaryAccent,
                service: service,
                onChanged: {}
            )
            _isExpanded = State(initialValue: true)
            _hasLoaded = State(initialValue: hasLoaded)
            _items = State(initialValue: previewItems)
            _busyIDs = State(initialValue: busyIDs)
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
                        PrismediaLoadingView("Loading monitoring…")
                    } else if items.isEmpty {
                        Text("No child items can be monitored yet.")
                            .font(.subheadline)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    } else {
                        bulkActions

                        ForEach(items) { item in
                            EntityChildMonitoringRow(
                                item: item,
                                isBusy: isBulkMutating || busyIDs.contains(item.id),
                                primaryAccent: primaryAccent,
                                onToggle: { nextValue in
                                    Task { await mutate(item, to: nextValue) }
                                },
                                onRetryCleanup: {
                                    guard let command = item.cleanupCommand else { return }
                                    Task { await perform(command, for: item.id) }
                                }
                            )
                            if item.id != items.last?.id { Divider() }
                        }
                    }

                    if let errorMessage {
                        EntityAcquisitionMessageCard(
                            title: "Some Monitoring Changes Failed",
                            message: errorMessage,
                            retryTitle: "Reload",
                            onRetry: { Task { await load(preservingContent: false) } },
                            onDismiss: { self.errorMessage = nil }
                        )
                    }
                }
                .padding(.top, PrismediaSpacing.medium)
            } label: {
                HStack(spacing: PrismediaSpacing.small) {
                    Label(title, systemImage: "rectangle.stack.badge.checkmark")
                        .font(.headline)
                        .foregroundStyle(PrismediaColor.textPrimary)
                    Text(String(items.isEmpty ? entities.count : items.count))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }
                .accessibilityAddTraits(.isHeader)
            }
            .task(id: liveTaskIdentity) {
                #if DEBUG
                    guard !disablesLiveLoadingForPreview else { return }
                #endif
                guard isExpanded, liveRefreshIsActive else { return }
                if !hasLoaded { await load(preservingContent: false) }
                while !Task.isCancelled, isExpanded, liveRefreshIsActive {
                    do { try await Task.sleep(for: .seconds(5)) } catch { return }
                    guard !Task.isCancelled else { return }
                    await load(preservingContent: true)
                }
            }
            .accessibilityIdentifier("entity-detail.acquisition.children")
        }
    #endif

    private var bulkActions: some View {
        HStack {
            Spacer(minLength: 0)
            PrismediaButton(
                "Monitoring actions",
                systemImage: "ellipsis",
                form: .compactIcon,
                menuContent: {
                    Section("Manage all \(items.count) items") {
                        Button("Monitor All", systemImage: "bell") {
                            Task { await mutateAll(to: true) }
                        }
                        .disabled(!items.contains { $0.command(to: true) != nil })

                        Button("Unmonitor All", systemImage: "bell.slash", role: .destructive) {
                            Task { await mutateAll(to: false) }
                        }
                        .disabled(!items.contains { $0.command(to: false) != nil })
                    }
                }
            )
            .disabled(isBulkMutating || !busyIDs.isEmpty)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrismediaSpacing.extraSmall)
        .padding(.trailing, PrismediaSpacing.small)
        .prismediaCompactActionControlSize()
    }

    private func mutate(_ item: EntityChildMonitoringItem, to nextValue: Bool) async {
        guard let command = item.command(to: nextValue) else { return }
        await perform(command, for: item.id)
    }

    private func perform(_ command: EntityAcquisitionCommand, for id: UUID) async {
        guard busyIDs.insert(id).inserted else { return }
        defer { busyIDs.remove(id) }
        errorMessage = nil

        switch await service.perform(command) {
        case .completed, .missingChildrenSearchCompleted:
            if !(await load(preservingContent: true)) {
                errorMessage = "Monitoring changed, but the child list couldn’t refresh."
            }
            await onChanged()
        case .failure(let message):
            errorMessage = message
        case .cancelled:
            break
        }
    }

    private func mutateAll(to nextValue: Bool) async {
        guard !isBulkMutating else { return }
        isBulkMutating = true
        defer { isBulkMutating = false }
        errorMessage = nil
        var failures: [String] = []

        for item in items {
            guard let command = item.command(to: nextValue) else { continue }
            switch await service.perform(command) {
            case .completed, .missingChildrenSearchCompleted:
                break
            case .failure(let message):
                failures.append("\(item.entity.title): \(message)")
            case .cancelled:
                return
            }
        }

        let refreshed = await load(preservingContent: true)
        await onChanged()
        if !failures.isEmpty {
            errorMessage = failures.joined(separator: "\n")
        } else if !refreshed {
            errorMessage = "Monitoring changed, but the child list couldn’t refresh."
        }
    }

    @discardableResult
    private func load(preservingContent: Bool) async -> Bool {
        do {
            let states = try await service.loadStates(entityIDs: entities.map(\.id))
            guard !Task.isCancelled else { return false }
            let statesByID = Dictionary(
                states.map { ($0.entityID, $0) },
                uniquingKeysWith: { _, latest in latest }
            )
            items = entities.compactMap { entity in
                statesByID[entity.id].map { EntityChildMonitoringItem(entity: entity, state: $0) }
            }
            hasLoaded = true
            if !preservingContent { errorMessage = nil }
            return true
        } catch is CancellationError {
            return false
        } catch {
            if !preservingContent || !hasLoaded { errorMessage = error.localizedDescription }
            hasLoaded = true
            return false
        }
    }

    private var liveRefreshIsActive: Bool {
        pageIsActive && scenePhase == .active
    }

    private var liveTaskIdentity: String {
        "\(isExpanded)-\(liveRefreshIsActive)-\(entities.map(\.id).hashValue)"
    }
}

#if DEBUG
    #Preview("Child Monitoring Section") {
        EntityChildMonitoringSection(
            title: "Episode Monitoring",
            entities: EntityAcquisitionPanelPreviewFixtures.childGroup.entities,
            primaryAccent: PrismediaColor.spectrumCyan,
            service: EntityAcquisitionService(
                port: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.groupingState,
                    additionalSnapshots: EntityAcquisitionPanelPreviewFixtures.childStates
                )
            ),
            onChanged: {}
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
