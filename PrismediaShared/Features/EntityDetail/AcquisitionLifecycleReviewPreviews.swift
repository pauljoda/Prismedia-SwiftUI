#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    // Deterministic visual review catalog for the Acquisition request lifecycle.
    // Keep this pass separate from Monitor and later downstream Acquisition passes.
    #Preview("Acquisition Review · Lifecycle · Request Entry · No Acquisition") {
        acquisitionLifecycleReviewRequestPanel()
    }

    #Preview("Acquisition Review · Lifecycle · Request Entry · Searching") {
        acquisitionLifecycleReviewRequestPanel(
            activeCommand: .searchForRelease(EntityAcquisitionPanelPreviewFixtures.entityID)
        )
    }

    #Preview("Acquisition Review · Lifecycle · Initial Loading") {
        acquisitionLifecycleReviewSurface(isLoading: true)
    }

    #Preview("Acquisition Review · Lifecycle · Initial Load Failure") {
        acquisitionLifecycleReviewSurface(
            loadErrorMessage: "The acquisition service could not be reached."
        )
    }

    #Preview("Acquisition Review · Lifecycle · Preparing Search") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "pending")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Searching") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "searching")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Awaiting Selection · Summary") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "awaiting-selection"
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Queued") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "queued")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Downloading") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "downloading",
                statusMessage: "Fetching the selected release.",
                progress: 0.64
            ),
            transfer: RequestActivityPreviewFixtures.transfer
        )
    }

    #Preview("Acquisition Review · Lifecycle · Downloaded") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "downloaded"),
            files: RequestActivityPreviewFixtures.files
        )
    }

    #Preview("Acquisition Review · Lifecycle · Importing") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "importing"),
            files: RequestActivityPreviewFixtures.files
        )
    }

    #Preview("Acquisition Review · Lifecycle · Imported") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "imported"),
            files: RequestActivityFiles(
                imported: true,
                files: RequestActivityPreviewFixtures.files.files
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Stopping · Locked") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "stopping")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Failed · Resumable") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                statusMessage: "The imported file could not be finalized.",
                hasResumableImport: true
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Failed · Search Again") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "failed")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Manual Import Required") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "manual-import-required",
                statusMessage: "The downloaded format needs your approval.",
                hasResumableImport: true
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Cancelled") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "cancelled")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Unknown · Updating Locked") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "future-state")
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Busy · Search Again") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "failed"),
            isActing: true,
            activeLifecycleAction: .research
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Busy · Cancel Acquisition") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "downloading"),
            transfer: RequestActivityPreviewFixtures.transfer,
            isActing: true,
            activeLifecycleAction: .cancel
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Busy · Retry Import") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                hasResumableImport: true
            ),
            isActing: true,
            activeLifecycleAction: .retryImport(allowFormatChange: false)
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Busy · Import Anyway") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "manual-import-required",
                hasResumableImport: true
            ),
            isActing: true,
            activeLifecycleAction: .retryImport(allowFormatChange: true)
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Busy · Start Over") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                hasResumableImport: true
            ),
            isActing: true,
            activeLifecycleAction: .startOver
        )
    }

    #Preview("Acquisition Review · Lifecycle · Start Over · Confirmation") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                hasResumableImport: true
            ),
            confirmsStartOver: true
        )
    }

    #Preview("Acquisition Review · Lifecycle · Request Mutation Failure · Retry") {
        acquisitionLifecycleReviewRequestPanel(
            mutationError: "The server could not start this search.",
            failedCommand: .searchForRelease(EntityAcquisitionPanelPreviewFixtures.entityID)
        )
    }

    #Preview("Acquisition Review · Lifecycle · Request Saved · Refresh Failure") {
        acquisitionLifecycleReviewRequestPanel(
            refreshError: "The latest acquisition could not be loaded."
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Failure · Retry") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "downloading"),
            transfer: RequestActivityPreviewFixtures.transfer,
            actionErrorMessage: "The download client did not accept the cancellation.",
            failedLifecycleAction: .cancel
        )
    }

    #Preview("Acquisition Review · Lifecycle · Action Failure · Dismiss Only") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "awaiting-selection"
            ),
            actionErrorMessage: "The selected release could not be queued."
        )
    }

    #Preview("Acquisition Review · Lifecycle · Live Refresh Failure") {
        acquisitionLifecycleReviewSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "downloading"),
            transfer: RequestActivityPreviewFixtures.transfer,
            refreshMessage: "Live updates are failing. Prismedia will keep retrying in the background."
        )
    }

    #Preview("Acquisition Review · Lifecycle · Message · Load Error") {
        acquisitionLifecycleReviewMessage(
            RequestActivityLifecycleMessage(
                title: "Unable to Load Acquisition",
                message: "The acquisition service could not be reached.",
                retryTitle: "Try Again",
                onRetry: {}
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Message · Action Error · Retry") {
        acquisitionLifecycleReviewMessage(
            RequestActivityLifecycleMessage(
                title: "Acquisition Action Failed",
                message: "The server rejected the acquisition change.",
                retryTitle: "Retry",
                onRetry: {},
                onDismiss: {}
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Message · Action Error · Dismiss Only") {
        acquisitionLifecycleReviewMessage(
            RequestActivityLifecycleMessage(
                title: "Acquisition Action Failed",
                message: "The selected release could not be queued.",
                onDismiss: {}
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Message · Live Refresh Warning") {
        acquisitionLifecycleReviewMessage(
            RequestActivityLifecycleMessage(
                title: "Live Updates Delayed",
                message: "Prismedia will keep retrying in the background.",
                isWarning: true,
                retryTitle: "Retry Now",
                onRetry: {},
                onDismiss: {}
            )
        )
    }

    #Preview("Acquisition Review · Lifecycle · Button · Busy Label Matrix") {
        acquisitionLifecycleReviewBusyButtons()
    }

    private func acquisitionLifecycleReviewPhase(
        _ state: EntityMonitorState
    ) -> EntityAcquisitionPanelPhase {
        .content(EntityAcquisitionPanelSnapshot(state: state, latestAcquisition: nil))
    }

    @MainActor
    private func acquisitionLifecycleReviewRequestPanel(
        activeCommand: EntityAcquisitionCommand? = nil,
        mutationError: String? = nil,
        refreshError: String? = nil,
        failedCommand: EntityAcquisitionCommand? = nil
    ) -> some View {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                previewPhase: acquisitionLifecycleReviewPhase(
                    EntityAcquisitionPanelPreviewFixtures.activeLeafState
                ),
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.activeLeafState
                ),
                isMutating: activeCommand != nil,
                mutationError: mutationError,
                refreshError: refreshError,
                activeCommand: activeCommand,
                failedCommand: failedCommand
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
    private func acquisitionLifecycleReviewSurface(
        detail: RequestActivityAcquisitionDetail? = nil,
        transfer: RequestActivityTransfer? = nil,
        files: RequestActivityFiles? = nil,
        isLoading: Bool = false,
        loadErrorMessage: String? = nil,
        isActing: Bool = false,
        actionErrorMessage: String? = nil,
        refreshMessage: String? = nil,
        activeLifecycleAction: RequestActivityAcquisitionAction? = nil,
        failedLifecycleAction: RequestActivityAcquisitionAction? = nil,
        confirmsStartOver: Bool = false
    ) -> some View {
        ScrollView {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: EntityAcquisitionPanelPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .content),
                previewDetail: detail,
                previewTransfer: transfer,
                previewFiles: files,
                isLoading: isLoading,
                loadErrorMessage: loadErrorMessage,
                isActing: isActing,
                actionErrorMessage: actionErrorMessage,
                refreshMessage: refreshMessage,
                activeLifecycleAction: activeLifecycleAction,
                failedLifecycleAction: failedLifecycleAction,
                confirmsStartOver: confirmsStartOver
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
    private func acquisitionLifecycleReviewMessage(
        _ message: RequestActivityLifecycleMessage
    ) -> some View {
        message
            .frame(maxWidth: 720)
            .padding()
            .background(PrismediaBackdrop())
            .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
            .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
            .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionLifecycleReviewBusyButtons() -> some View {
        ScrollView {
            GlassEffectContainer(spacing: PrismediaSpacing.small) {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    PrismediaButton(
                        "Search for release",
                        systemImage: "magnifyingglass",
                        variant: .prominent,
                        primaryTint: PrismediaColor.spectrumCyan,
                        isLoading: true,
                        loadingTitle: "Searching…"
                    ) {}
                    PrismediaButton(
                        "Search Again",
                        systemImage: "arrow.clockwise",
                        variant: .prominent,
                        primaryTint: PrismediaColor.spectrumCyan,
                        isLoading: true,
                        loadingTitle: "Searching…"
                    ) {}
                    PrismediaButton(
                        "Cancel Acquisition",
                        systemImage: "xmark",
                        variant: .destructive,
                        isLoading: true,
                        loadingTitle: "Cancelling…"
                    ) {}
                    PrismediaButton(
                        "Retry Import",
                        systemImage: "arrow.down.doc",
                        variant: .prominent,
                        primaryTint: PrismediaColor.spectrumCyan,
                        isLoading: true,
                        loadingTitle: "Importing…"
                    ) {}
                    PrismediaButton(
                        "Import Anyway",
                        systemImage: "arrow.down.doc",
                        variant: .prominent,
                        primaryTint: PrismediaColor.spectrumCyan,
                        isLoading: true,
                        loadingTitle: "Importing…"
                    ) {}
                    PrismediaButton(
                        "Start Over",
                        systemImage: "arrow.counterclockwise",
                        variant: .destructive,
                        isLoading: true,
                        loadingTitle: "Starting Over…"
                    ) {}
                }
            }
            .prismediaCompactActionControlSize()
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: 720)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .preferredColorScheme(.dark)
    }
#endif
