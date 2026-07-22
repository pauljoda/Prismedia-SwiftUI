#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Acquisition Review · Files · Initial Loading") {
        acquisitionFilesReviewSurface(.initialLoading)
    }

    #Preview("Acquisition Review · Files · Initial Failure · Retry") {
        var state = RequestActivityFilesLoadState.initialLoading
        state.recordInitialFailure("The file results endpoint could not be reached.")
        return acquisitionFilesReviewSurface(state)
    }

    #Preview("Acquisition Review · Files · Downloaded Sources · Compact") {
        acquisitionFilesReviewSurface(.loaded(acquisitionFilesFixture(phase: .downloaded, statuses: [.downloaded, .downloaded])))
    }

    #Preview("Acquisition Review · Files · Importing · Count Progress") {
        acquisitionFilesReviewSurface(.loaded(acquisitionFilesFixture(phase: .importing, statuses: [.imported, .importing, .pendingImport])))
    }

    #Preview("Acquisition Review · Files · Complete · Collapsed") {
        acquisitionFilesReviewSurface(.loaded(acquisitionFilesFixture(phase: .imported, statuses: [.imported, .imported])))
    }

    #Preview("Acquisition Review · Files · Complete · Expanded") {
        acquisitionFilesReviewSurface(
            .loaded(acquisitionFilesFixture(phase: .imported, statuses: [.imported, .imported])),
            expansionOverride: true
        )
    }

    #Preview("Acquisition Review · Files · Partial · Skipped · Expanded") {
        acquisitionFilesReviewSurface(.loaded(acquisitionFilesFixture(phase: .imported, statuses: [.imported, .skipped])))
    }

    #Preview("Acquisition Review · Files · Detailed Mapped Companion Skipped Failed") {
        acquisitionFilesReviewSurface(.loaded(acquisitionDetailedFilesFixture()))
    }

    #Preview("Acquisition Review · Files · Active Waiting") {
        var state = RequestActivityFilesLoadState.initialLoading
        state.recordWaiting()
        return acquisitionFilesReviewSurface(state)
    }

    #Preview("Acquisition Review · Files · Active Empty") {
        var state = RequestActivityFilesLoadState.initialLoading
        state.recordEmpty()
        return acquisitionFilesReviewSurface(state)
    }

    #Preview("Acquisition Review · Files · Imported Information Unavailable") {
        var state = RequestActivityFilesLoadState.initialLoading
        state.recordUnavailable()
        return acquisitionFilesReviewSurface(state)
    }

    #Preview("Acquisition Review · Files · Saved Data · Stale Refresh") {
        var state = RequestActivityFilesLoadState.loaded(acquisitionFilesFixture(phase: .importing, statuses: [.imported, .pendingImport]))
        state.recordRefreshFailure(); state.recordRefreshFailure(); state.recordRefreshFailure()
        return acquisitionFilesReviewSurface(state)
    }

    #Preview("Acquisition Review · Files · Manual Import Boundary · Hidden") {
        acquisitionFilesBoundarySurface(status: "manual-import-required", hasResumableImport: true)
    }

    #Preview("Acquisition Review · Files · Failed Resumable Boundary · Hidden") {
        acquisitionFilesBoundarySurface(status: "failed", hasResumableImport: true)
    }

    #Preview("Acquisition Review · Files · Wide iPad Mac", traits: .fixedLayout(width: 1_000, height: 760)) {
        acquisitionFilesReviewSurface(.loaded(acquisitionDetailedFilesFixture()), width: 820)
    }

    #Preview("Acquisition Review · Files · Long Paths Errors · Accessibility Type") {
        acquisitionFilesReviewSurface(.loaded(acquisitionDetailedFilesFixture()), width: 390)
            .environment(\.dynamicTypeSize, .accessibility3)
    }

    @MainActor
    private func acquisitionFilesReviewSurface(
        _ state: RequestActivityFilesLoadState,
        expansionOverride: Bool? = nil,
        width: CGFloat = 390
    ) -> some View {
        ScrollView {
            RequestActivityFilesSection(loadState: state, expansionOverride: expansionOverride) {}
                .padding(PrismediaSpacing.extraLarge)
                .prismediaCard()
                .frame(maxWidth: width)
                .padding()
        }
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionFilesBoundarySurface(status: String, hasResumableImport: Bool) -> some View {
        ScrollView {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: EntityAcquisitionPanelPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .content),
                previewDetail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                    status: status,
                    statusMessage: "The import needs attention.",
                    hasResumableImport: hasResumableImport
                ),
                previewFilesLoadState: .loaded(acquisitionDetailedFilesFixture())
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: 390)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    private func acquisitionFilesFixture(
        phase: RequestActivityImportPhase.Value,
        statuses: [RequestActivityFileStatus.Value]
    ) -> RequestActivityFiles {
        RequestActivityFiles(
            imported: phase == .imported,
            phase: .init(value: phase),
            files: statuses.enumerated().map { index, status in
                RequestActivityFile(
                    id: "review-file-\(index)",
                    name: index == 0 ? "Dune.1965.Retail.epub" : "cover-artwork.jpg",
                    sizeBytes: index == 0 ? 4_200_000 : 310_000,
                    progress: status == .imported || status == .skipped ? 1 : 0,
                    sourceRelativePath: "Dune Retail/\(index == 0 ? "Dune.1965.Retail.epub" : "cover-artwork.jpg")",
                    destinationRelativePath: status == .pendingImport ? nil : "Books/Frank Herbert/Dune/\(index == 0 ? "Dune.epub" : "cover.jpg")",
                    role: .init(value: index == 0 ? .media : .companion),
                    contentKind: .init(value: index == 0 ? .book : .image),
                    status: .init(value: status),
                    decision: .init(value: status == .skipped ? .skipExisting : .placeNew),
                    technicalError: nil
                )
            }
        )
    }

    private func acquisitionDetailedFilesFixture() -> RequestActivityFiles {
        let longSource = "A very long release folder/Dune.1965.Special.Illustrated.Retail.Edition/Companion Material/cover-final-high-resolution.jpg"
        return RequestActivityFiles(
            imported: true,
            phase: .init(value: .imported),
            files: [
                RequestActivityFile(
                    id: "mapped", name: "Dune.epub", sizeBytes: 4_200_000, progress: 1,
                    sourceRelativePath: "Dune Retail/Dune.1965.Retail.epub",
                    destinationRelativePath: "Books/Frank Herbert/Dune/Dune.epub",
                    role: .init(value: .media), contentKind: .init(value: .book),
                    status: .init(value: .imported), decision: .init(value: .placeNew), technicalError: nil
                ),
                RequestActivityFile(
                    id: "companion", name: "cover-final-high-resolution.jpg", sizeBytes: 8_100_000, progress: 1,
                    sourceRelativePath: longSource,
                    destinationRelativePath: "Books/Frank Herbert/Dune/Artwork/cover-final-high-resolution.jpg",
                    role: .init(value: .companion), contentKind: .init(value: .image),
                    status: .init(value: .skipped), decision: .init(value: .skipExisting), technicalError: nil
                ),
                RequestActivityFile(
                    id: "failed", name: "notes.txt", sizeBytes: 12_000, progress: 0,
                    sourceRelativePath: "Dune Retail/notes.txt", destinationRelativePath: nil,
                    role: .init(value: .unknown), contentKind: .init(value: .other),
                    status: .init(value: .failed), decision: .init(value: .unsupported),
                    technicalError: "The companion file could not be placed because its normalized destination conflicted with an existing managed file. No server path or credential is included in this message."
                ),
            ]
        )
    }
#endif
