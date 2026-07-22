#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Acquisition Review · Manual · Content · Empty · iPhone") {
        manualContentReviewSurface()
    }

    #Preview("Acquisition Review · Manual · Content · Owned Replacement Available") {
        manualEntityPanelReviewSurface(
            phase: .content(
                EntityAcquisitionPanelSnapshot(
                    state: EntityAcquisitionPanelPreviewFixtures.activeLeafState,
                    latestAcquisition: nil
                )
            ),
            hasOwnedContent: true
        )
    }

    #Preview("Acquisition Review · Manual · Content · Hidden During Download") {
        manualEntityPanelReviewSurface(
            phase: .content(
                EntityAcquisitionPanelSnapshot(
                    state: EntityAcquisitionPanelPreviewFixtures.downloadingState,
                    latestAcquisition: EntityAcquisitionPanelPreviewFixtures.downloadingDetail
                )
            ),
            hasOwnedContent: true
        )
    }

    #Preview(
        "Acquisition Review · Manual · Content · Empty Drop Target · iPad Mac",
        traits: .fixedLayout(width: 900, height: 700)
    ) {
        manualContentReviewSurface(width: 760)
    }

    #Preview("Acquisition Review · Manual · Content · Selected Files") {
        manualContentReviewSurface(files: manualContentReviewFiles)
    }

    #Preview("Acquisition Review · Manual · Content · Invalid Selection") {
        manualContentReviewSurface(
            files: [manualContentReviewFile("notes.txt", size: 12_000)],
            errorMessage: "The selection does not contain supported book content."
        )
    }

    #Preview("Acquisition Review · Manual · Content · Local Read Failure") {
        manualContentReviewSurface(
            errorMessage: "Dune.epub could not be read. Choose it again or select another file."
        )
    }

    #Preview("Acquisition Review · Manual · Content · Reading Files") {
        manualContentReviewSurface(isReadingSelection: true)
    }

    #Preview("Acquisition Review · Manual · Content · Preparing") {
        manualContentReviewSurface(files: manualContentReviewFiles, phase: .preparing)
    }

    #Preview("Acquisition Review · Manual · Content · Uploading") {
        manualContentReviewSurface(files: manualContentReviewFiles, phase: .uploading(0.64))
    }

    #Preview("Acquisition Review · Manual · Content · Starting Import") {
        manualContentReviewSurface(files: manualContentReviewFiles, phase: .finishing)
    }

    #Preview("Acquisition Review · Manual · Content · Upload Failure") {
        manualContentReviewSurface(
            files: manualContentReviewFiles,
            errorMessage: "The upload connection failed. Check the server and try again."
        )
    }

    #Preview("Acquisition Review · Manual · Torrent · Empty") {
        manualTorrentReviewSurface()
    }

    #Preview(
        "Acquisition Review · Manual · Torrent · Empty Drop Target · iPad Mac",
        traits: .fixedLayout(width: 900, height: 700)
    ) {
        manualTorrentReviewSurface(width: 760)
    }

    #Preview("Acquisition Review · Manual · Torrent · Selected") {
        manualTorrentReviewSurface(file: manualTorrentReviewFile)
    }

    #Preview("Acquisition Review · Manual · Torrent · Unsupported File") {
        manualTorrentReviewSurface(
            file: manualContentReviewFile("release.txt", size: 4_000),
            errorMessage: "Choose one non-empty .torrent file."
        )
    }

    #Preview("Acquisition Review · Manual · Torrent · Reading File") {
        manualTorrentReviewSurface(isReadingSelection: true)
    }

    #Preview("Acquisition Review · Manual · Torrent · Reading for Submit") {
        manualTorrentReviewSurface(file: manualTorrentReviewFile, phase: .preparing)
    }

    #Preview("Acquisition Review · Manual · Torrent · Sending to Client") {
        manualTorrentReviewSurface(file: manualTorrentReviewFile, phase: .uploading(0))
    }

    #Preview("Acquisition Review · Manual · Torrent · Starting Download") {
        manualTorrentReviewSurface(file: manualTorrentReviewFile, phase: .finishing)
    }

    #Preview("Acquisition Review · Manual · Torrent · Upload Failure") {
        manualTorrentReviewSurface(
            file: manualTorrentReviewFile,
            errorMessage: "No enabled torrent download client is configured."
        )
    }

    #Preview("Acquisition Review · Manual · Torrent · Success Handoff to Download") {
        manualLifecycleHandoffSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "queued",
                statusMessage: "Waiting for the configured download client."
            )
        )
    }

    #Preview("Acquisition Review · Manual · Content · Success Handoff to Import") {
        var filesState = RequestActivityFilesLoadState.initialLoading
        filesState.recordWaiting()
        return manualLifecycleHandoffSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "downloaded",
                statusMessage: "Upload complete; importing."
            ),
            filesState: filesState
        )
    }

    #Preview("Acquisition Review · Manual · Post Upload Refresh Delayed") {
        manualLifecycleHandoffSurface(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(status: "queued"),
            refreshMessage: "Prismedia will keep retrying live updates in the background."
        )
    }

    #Preview("Acquisition Review · Manual · Error Message") {
        manualReviewCanvas {
            RequestActivityManualErrorMessage(
                message: "The selected files exceed Prismedia’s 250 GiB acquisition upload limit."
            )
        }
    }

    #Preview("Acquisition Review · Manual · File Summary · Many Files") {
        manualReviewCanvas {
            RequestActivityManualFileSummary(
                files: manualContentReviewFiles + [
                    manualContentReviewFile("cover.jpg", size: 820_000),
                    manualContentReviewFile("metadata.opf", size: 8_000),
                    manualContentReviewFile("notes.txt", size: 2_000),
                ],
                onRemove: { _ in }
            )
        }
    }

    #Preview("Acquisition Review · Manual · Drop Target") {
        manualReviewCanvas {
            RequestActivityManualDropTarget(
                title: "Drop acquisition files",
                message: "Add one or more files. Folders are not accepted.",
                isDisabled: false,
                onDrop: { _ in }
            )
        }
    }

    #Preview("Acquisition Review · Manual · Accessibility Type") {
        manualContentReviewSurface(files: manualContentReviewFiles)
            .environment(\.dynamicTypeSize, .accessibility3)
    }

    @MainActor
    private func manualContentReviewSurface(
        files: [RequestActivityManualUploadFile] = [],
        phase: RequestActivityManualUploadPhase = .idle,
        errorMessage: String? = nil,
        isReadingSelection: Bool = false,
        width: CGFloat = 390
    ) -> some View {
        manualReviewCanvas(width: width) {
            EntityManualContentUploadSection(
                entityID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
                kind: .book,
                service: PreviewRequestActivityService(scenario: .content),
                previewFiles: files,
                previewPhase: phase,
                errorMessage: errorMessage,
                isReadingSelection: isReadingSelection
            )
        }
    }

    @MainActor
    private func manualTorrentReviewSurface(
        file: RequestActivityManualUploadFile? = nil,
        phase: RequestActivityManualUploadPhase = .idle,
        errorMessage: String? = nil,
        isReadingSelection: Bool = false,
        width: CGFloat = 390
    ) -> some View {
        manualReviewCanvas(width: width) {
            RequestActivityManualTorrentSection(
                acquisitionID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                service: PreviewRequestActivityService(scenario: .releases),
                previewFile: file,
                previewPhase: phase,
                errorMessage: errorMessage,
                isReadingSelection: isReadingSelection
            )
        }
    }

    @MainActor
    private func manualEntityPanelReviewSurface(
        phase: EntityAcquisitionPanelPhase,
        hasOwnedContent: Bool
    ) -> some View {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                entityKind: .book,
                hasOwnedContent: hasOwnedContent,
                previewPhase: phase,
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: EntityAcquisitionPanelPreviewFixtures.activeLeafState
                ),
                requestActivityService: PreviewRequestActivityService(scenario: .content)
            )
            .frame(maxWidth: 620)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func manualLifecycleHandoffSurface(
        detail: RequestActivityAcquisitionDetail,
        filesState: RequestActivityFilesLoadState = .initialLoading,
        refreshMessage: String? = nil
    ) -> some View {
        ScrollView {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: detail.summary.id,
                service: PreviewRequestActivityService(scenario: .content),
                previewDetail: detail,
                previewFilesLoadState: filesState,
                refreshMessage: refreshMessage
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: 620)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func manualReviewCanvas<Content: View>(
        width: CGFloat = 390,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            content()
                .padding(PrismediaSpacing.extraLarge)
                .prismediaCard()
                .frame(maxWidth: width)
                .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .preferredColorScheme(.dark)
    }

    private var manualContentReviewFiles: [RequestActivityManualUploadFile] {
        [
            manualContentReviewFile("Dune.epub", size: 4_200_000),
            manualContentReviewFile("Dune.m4b", size: 628_000_000),
        ]
    }

    private var manualTorrentReviewFile: RequestActivityManualUploadFile {
        manualContentReviewFile("Dune.1965.Retail.torrent", size: 84_000)
    }

    private func manualContentReviewFile(
        _ name: String,
        size: Int64
    ) -> RequestActivityManualUploadFile {
        RequestActivityManualUploadFile(
            url: URL(fileURLWithPath: "/preview/\(name)"),
            fileName: name,
            sizeBytes: size
        )
    }
#endif
