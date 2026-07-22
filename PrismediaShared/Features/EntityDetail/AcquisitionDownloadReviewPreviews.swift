#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    // Deterministic visual review catalog for the entity Acquisition transfer pass.
    // Keep this pass separate from Monitor, Lifecycle, Release Picker, and Files.
    #Preview("Acquisition Review · Download · Preparing Client Handoff") {
        acquisitionDownloadReviewSurface(
            status: "queued",
            transfer: nil,
            loadState: .preparing
        )
    }

    #Preview("Acquisition Review · Download · Active · Compact") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.transfer)
    }

    #Preview(
        "Acquisition Review · Download · Active · Wide",
        traits: .fixedLayout(width: 1_000, height: 760)
    ) {
        acquisitionDownloadReviewSurface(
            transfer: RequestActivityPreviewFixtures.transfer,
            width: 760
        )
    }

    #Preview("Acquisition Review · Download · Stalled · No Peers") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.stalledTransfer)
    }

    #Preview("Acquisition Review · Download · Paused") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.pausedTransfer)
    }

    #Preview("Acquisition Review · Download · Client Error") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.failedTransfer)
    }

    #Preview("Acquisition Review · Download · No Swarm Telemetry") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.noSwarmTransfer)
    }

    #Preview("Acquisition Review · Download · Unknown Client State") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.unknownStateTransfer)
    }

    #Preview("Acquisition Review · Download · Complete · Import Handoff") {
        acquisitionDownloadReviewSurface(transfer: RequestActivityPreviewFixtures.completedTransfer)
    }

    #Preview("Acquisition Review · Download · Transfer Unavailable") {
        acquisitionDownloadReviewSurface(
            transfer: nil,
            loadState: .unavailable
        )
    }

    #Preview("Acquisition Review · Download · Saved Progress · Refresh Failure") {
        acquisitionDownloadReviewSurface(
            transfer: RequestActivityPreviewFixtures.transfer,
            loadState: .stale,
            refreshMessage: "Live updates are failing. Prismedia will keep retrying in the background."
        )
    }

    #Preview("Acquisition Review · Download · Piece Availability") {
        RequestActivityPieceStateBar(
            pieces: Array(repeating: 2, count: 72)
                + Array(repeating: 1, count: 18)
                + Array(repeating: 0, count: 70)
        )
        .padding(PrismediaSpacing.extraLarge)
        .prismediaPanel()
        .frame(width: 390)
        .padding()
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }

    #Preview("Acquisition Review · Download · Accessibility Dynamic Type") {
        acquisitionDownloadReviewSurface(
            transfer: RequestActivityPreviewFixtures.transfer
        )
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    @MainActor
    private func acquisitionDownloadReviewSurface(
        status: String = "downloading",
        transfer: RequestActivityTransfer?,
        loadState: RequestActivityTransferLoadState = .current,
        refreshMessage: String? = nil,
        width: CGFloat = 390
    ) -> some View {
        ScrollView {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: EntityAcquisitionPanelPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .content),
                previewDetail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                    status: status,
                    statusMessage: status == "queued"
                        ? "Waiting for the download client to accept the release."
                        : "Downloading the selected release.",
                    progress: transfer?.progress
                ),
                previewTransfer: transfer,
                previewTransferLoadState: loadState,
                refreshMessage: refreshMessage
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: width)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }
#endif
