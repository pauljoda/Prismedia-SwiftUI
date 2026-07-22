#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    // One-off visual review catalog for the Acquisition UI redesign.
    //
    // Each focused Acquisition pass appends a named, deterministic `#Preview`
    // for every visual state and component it introduces. Keep all fixtures
    // in-memory so the complete flow can be reviewed without a live server.
    #Preview("Acquisition UI Review · Index") {
        ContentUnavailableView {
            Label("Acquisition UI Review", systemImage: "rectangle.stack")
        } description: {
            Text("Use the named previews in this file to inspect every Acquisition state.")
        }
        .padding()
        .preferredColorScheme(.dark)
    }

    #Preview("Acquisition Review · Monitor · Loading") {
        acquisitionMonitorReviewPanel(phase: .loading)
    }

    #Preview("Acquisition Review · Monitor · Off · No Monitor") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.wantedState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Paused") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.pausedState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Fulfilled") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.fulfilledState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Unavailable") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.unavailableState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Enabling") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.wantedState
            ),
            isMutating: true,
            pendingMonitorValue: true
        )
    }

    #Preview("Acquisition Review · Monitor · Resuming") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.pausedState
            ),
            isMutating: true,
            pendingMonitorValue: true
        )
    }

    #Preview("Acquisition Review · Monitor · Active Leaf") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.activeLeafState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Active Grouping") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.groupingState
            ),
            childGroups: [EntityAcquisitionPanelPreviewFixtures.childGroup]
        )
    }

    #Preview("Acquisition Review · Monitor · Deleting Files") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.deletingFilesState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Stopping · Cleanup Retry") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.stoppingState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Unknown · Locked") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.unknownState
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Initial Load Failure") {
        acquisitionMonitorReviewPanel(
            phase: .failure("The monitoring service could not be reached.")
        )
    }

    #Preview("Acquisition Review · Monitor · Mutation Failure · Retry") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.wantedState
            ),
            mutationError: "The server rejected the monitoring change.",
            failedCommand: .start(EntityAcquisitionPanelPreviewFixtures.entityID),
            failedPendingMonitorValue: true
        )
    }

    #Preview("Acquisition Review · Monitor · Saved · Refresh Failure") {
        acquisitionMonitorReviewPanel(
            phase: acquisitionMonitorReviewPhase(
                EntityAcquisitionPanelPreviewFixtures.wantedState
            ),
            refreshError: "The owner record is temporarily unavailable.",
            confirmedMonitorValue: true
        )
    }

    #Preview("Acquisition Review · Monitor · Children · Loading") {
        acquisitionMonitorReviewChildSection(
            items: EntityAcquisitionPanelPreviewFixtures.childReviewItems,
            hasLoaded: false
        )
    }

    #Preview("Acquisition Review · Monitor · Children · State Matrix") {
        acquisitionMonitorReviewChildSection(
            items: EntityAcquisitionPanelPreviewFixtures.childReviewItems,
            busyIDs: [EntityAcquisitionPanelPreviewFixtures.childBusyID]
        )
    }

    #Preview("Acquisition Review · Monitor · Children · Failure") {
        acquisitionMonitorReviewChildSection(
            items: EntityAcquisitionPanelPreviewFixtures.childReviewItems,
            errorMessage: "Season 6 could not be updated. Try reloading the monitoring states."
        )
    }

    #Preview("Acquisition Review · Monitor · Child Row · Off") {
        acquisitionMonitorReviewChildRow(index: 0)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Active") {
        acquisitionMonitorReviewChildRow(index: 1)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Paused") {
        acquisitionMonitorReviewChildRow(index: 2)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Fulfilled") {
        acquisitionMonitorReviewChildRow(index: 3)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Deleting Files") {
        acquisitionMonitorReviewChildRow(index: 4)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Stopping · Retry") {
        acquisitionMonitorReviewChildRow(index: 5)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Unavailable") {
        acquisitionMonitorReviewChildRow(index: 6)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Unknown · Locked") {
        acquisitionMonitorReviewChildRow(index: 7)
    }

    #Preview("Acquisition Review · Monitor · Child Row · Busy") {
        acquisitionMonitorReviewChildRow(index: 8, isBusy: true)
    }

    #Preview("Acquisition Review · Monitor · Message · Mutation Error") {
        acquisitionMonitorReviewMessage(
            EntityAcquisitionMessageCard(
                title: "Couldn’t Update Monitoring",
                message: "The server rejected the monitoring change.",
                retryTitle: "Retry",
                onRetry: {},
                onDismiss: {}
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Message · Refresh Warning") {
        acquisitionMonitorReviewMessage(
            EntityAcquisitionMessageCard(
                title: "Monitoring Updated",
                message: "The change was saved, but this page couldn’t refresh.",
                isWarning: true,
                retryTitle: "Refresh",
                onRetry: {},
                onDismiss: {}
            )
        )
    }

    #Preview("Acquisition Review · Monitor · Message · Discovery Notice") {
        acquisitionMonitorReviewMessage(
            EntityAcquisitionMessageCard(
                title: "Search Started",
                message: "Searches were queued for 3 items; 1 could not be searched yet.",
                isInformational: true,
                onDismiss: {}
            )
        )
    }

    private func acquisitionMonitorReviewPhase(
        _ state: EntityMonitorState
    ) -> EntityAcquisitionPanelPhase {
        .content(EntityAcquisitionPanelSnapshot(state: state, latestAcquisition: nil))
    }

    @MainActor
    private func acquisitionMonitorReviewPanel(
        phase: EntityAcquisitionPanelPhase,
        childGroups: [EntityGroup] = [],
        isMutating: Bool = false,
        mutationError: String? = nil,
        refreshError: String? = nil,
        pendingMonitorValue: Bool? = nil,
        confirmedMonitorValue: Bool? = nil,
        failedCommand: EntityAcquisitionCommand? = nil,
        failedPendingMonitorValue: Bool? = nil
    ) -> some View {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                childGroups: childGroups,
                previewPhase: phase,
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.wantedState,
                    additionalSnapshots: EntityAcquisitionPanelPreviewFixtures.childStates
                ),
                isMutating: isMutating,
                mutationError: mutationError,
                refreshError: refreshError,
                pendingMonitorValue: pendingMonitorValue,
                confirmedMonitorValue: confirmedMonitorValue,
                failedCommand: failedCommand,
                failedPendingMonitorValue: failedPendingMonitorValue
            )
            .frame(maxWidth: 720)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionMonitorReviewChildSection(
        items: [EntityChildMonitoringItem],
        hasLoaded: Bool = true,
        busyIDs: Set<UUID> = [],
        errorMessage: String? = nil
    ) -> some View {
        ScrollView {
            EntityChildMonitoringSection(
                title: "Episode Monitoring",
                previewItems: items,
                primaryAccent: PrismediaColor.spectrumCyan,
                service: EntityAcquisitionService(
                    port: PreviewEntityAcquisitionService(
                        snapshot: EntityAcquisitionPanelPreviewFixtures.groupingState,
                        additionalSnapshots: EntityAcquisitionPanelPreviewFixtures.childStates
                    )
                ),
                hasLoaded: hasLoaded,
                busyIDs: busyIDs,
                errorMessage: errorMessage
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: 720)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionMonitorReviewChildRow(
        index: Int,
        isBusy: Bool = false
    ) -> some View {
        EntityChildMonitoringRow(
            item: EntityAcquisitionPanelPreviewFixtures.childReviewItems[index],
            isBusy: isBusy,
            primaryAccent: PrismediaColor.spectrumCyan,
            onToggle: { _ in },
            onRetryCleanup: {}
        )
        .padding(PrismediaSpacing.extraLarge)
        .prismediaCard()
        .frame(maxWidth: 720)
        .padding()
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionMonitorReviewMessage(
        _ card: EntityAcquisitionMessageCard
    ) -> some View {
        card
            .frame(maxWidth: 720)
            .padding()
            .background(PrismediaBackdrop())
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
            .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
            .preferredColorScheme(.dark)
    }
#endif
