import SwiftUI

#if os(iOS) || os(macOS)
    /// Collapsible durable activity log and entity-scoped blocklist recovery surface.
    /// The owning panel supplies history state while the nested recovery control loads its count.
    struct EntityAcquisitionHistorySection: View {
        let entries: [RequestActivityHistoryEntry]
        let loadState: EntityAcquisitionHistoryLoadState
        let entityID: UUID
        let service: EntityAcquisitionService
        let referenceDate: Date
        let onRetry: @MainActor () async -> Void
        @State private var isExpanded: Bool

        init(
            entries: [RequestActivityHistoryEntry],
            loadState: EntityAcquisitionHistoryLoadState,
            entityID: UUID,
            service: EntityAcquisitionService,
            referenceDate: Date = .now,
            isInitiallyExpanded: Bool = false,
            onRetry: @escaping @MainActor () async -> Void
        ) {
            self.entries = entries
            self.loadState = loadState
            self.entityID = entityID
            self.service = service
            self.referenceDate = referenceDate
            self.onRetry = onRetry
            _isExpanded = State(initialValue: isInitiallyExpanded)
        }

        var body: some View {
            DisclosureGroup(isExpanded: $isExpanded) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    historyContent
                    Divider()
                    EntityAcquisitionBlocklistSection(
                        entityID: entityID,
                        service: service
                    )
                }
                .padding(.top, PrismediaSpacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
            } label: {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: PrismediaSpacing.small) {
                        sectionTitle
                        loadSummary
                    }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        sectionTitle
                        loadSummary
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("entity-detail.acquisition.history")
        }

        private var sectionTitle: some View {
            Label("History", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(PrismediaColor.textPrimary)
        }

        @ViewBuilder
        private var loadSummary: some View {
            switch loadState {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .accessibilityHidden(true)
            case .loaded:
                if EntityAcquisitionHistoryPolicy.reachedEntryLimit(entries.count) {
                    Text("Latest \(EntityAcquisitionHistoryPolicy.entryLimit)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                } else {
                    Text(entries.count, format: .number)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(PrismediaColor.textMuted)
                }
            case .failed:
                EmptyView()
            }
        }

        @ViewBuilder
        private var historyContent: some View {
            switch loadState {
            case .loading:
                PrismediaLoadingView("Loading history…")
                    .frame(minHeight: 120)
            case let .failed(message):
                VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    Label("Unable to Load History", systemImage: "exclamationmark.triangle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PrismediaColor.warning)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(PrismediaColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                    PrismediaButton(
                        "Try Again",
                        systemImage: "arrow.clockwise"
                    ) {
                        Task { await onRetry() }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .loaded:
                if entries.isEmpty {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Label("No Acquisition Activity", systemImage: "clock")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PrismediaColor.textSecondary)
                        Text("Grabs, imports, failures, upgrades, and removals will appear here.")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                        ForEach(entries) { entry in
                            EntityAcquisitionHistoryRow(
                                entry: entry,
                                referenceDate: referenceDate
                            )
                            if entry.id != entries.last?.id {
                                Divider()
                            }
                        }

                        if EntityAcquisitionHistoryPolicy.reachedEntryLimit(entries.count) {
                            Text("Showing the latest \(EntityAcquisitionHistoryPolicy.entryLimit) acquisition events.")
                                .font(.caption)
                                .foregroundStyle(PrismediaColor.textMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    #if DEBUG
        #Preview("Acquisition Review · History · Section Component") {
            ScrollView {
                EntityAcquisitionHistorySection(
                    entries: RequestActivityPreviewFixtures.historyEntries,
                    loadState: .loaded,
                    entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                    service: EntityAcquisitionService(
                        port: PreviewEntityAcquisitionService(
                            snapshot: EntityAcquisitionPanelPreviewFixtures.downloadingState
                        )
                    ),
                    referenceDate: RequestActivityPreviewFixtures.referenceDate,
                    isInitiallyExpanded: true,
                    onRetry: {}
                )
                .padding(PrismediaSpacing.extraLarge)
                .prismediaCard()
                .padding()
            }
            .background(PrismediaBackdrop())
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
            .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
            .environment(\.prismediaPageIsActive, false)
            .preferredColorScheme(.dark)
        }
    #endif
#endif
