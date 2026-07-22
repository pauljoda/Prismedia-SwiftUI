#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    // Deterministic visual review catalog for release discovery and candidate selection.
    // Keep this pass separate from the Monitor and Lifecycle review catalogs.
    #Preview("Acquisition Review · Release Picker · Loading") {
        acquisitionReleasePickerReviewSection(candidates: [], isLoading: true)
    }

    #Preview("Acquisition Review · Release Picker · Empty") {
        acquisitionReleasePickerReviewSection(candidates: [])
    }

    #Preview("Acquisition Review · Release Picker · Compact Cards") {
        acquisitionReleasePickerReviewSection(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates
        )
    }

    #Preview(
        "Acquisition Review · Release Picker · Wide Rows",
        traits: .fixedLayout(width: 1_180, height: 800)
    ) {
        acquisitionReleasePickerReviewSection(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates,
            width: 1_080
        )
    }

    #Preview("Acquisition Review · Release Picker · Candidate · Eligible") {
        acquisitionReleasePickerReviewCandidate(RequestActivityPreviewFixtures.categoryCandidate)
    }

    #Preview("Acquisition Review · Release Picker · Candidate · Download Anyway") {
        acquisitionReleasePickerReviewCandidate(RequestActivityPreviewFixtures.rejectedCandidate)
    }

    #Preview("Acquisition Review · Release Picker · Candidate · Unavailable") {
        acquisitionReleasePickerReviewCandidate(RequestActivityPreviewFixtures.unavailableCandidate)
    }

    #Preview("Acquisition Review · Release Picker · Candidate · Blocked") {
        acquisitionReleasePickerReviewCandidate(RequestActivityPreviewFixtures.blockedCandidate)
    }

    #Preview("Acquisition Review · Release Picker · Candidate · Soulseek Category and Link") {
        acquisitionReleasePickerReviewCandidate(RequestActivityPreviewFixtures.soulseekCandidate)
    }

    #Preview("Acquisition Review · Release Picker · Candidate · Unknown Protocol") {
        acquisitionReleasePickerReviewCandidate(
            RequestActivityPreviewFixtures.unknownProtocolCandidate
        )
    }

    #Preview("Acquisition Review · Release Picker · Rejected Revealed") {
        acquisitionReleasePickerReviewSection(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates,
            showsOnlyRelevant: false
        )
    }

    #Preview("Acquisition Review · Release Picker · No Eligible Results") {
        acquisitionReleasePickerReviewSection(
            candidates: [
                RequestActivityPreviewFixtures.rejectedCandidate,
                RequestActivityPreviewFixtures.unavailableCandidate,
                RequestActivityPreviewFixtures.blockedCandidate,
            ]
        )
    }

    #Preview("Acquisition Review · Release Picker · Blocked Revealed") {
        acquisitionReleasePickerReviewSection(
            candidates: [
                RequestActivityPreviewFixtures.categoryCandidate,
                RequestActivityPreviewFixtures.blockedCandidate,
            ],
            showsOnlyRelevant: false
        )
    }

    #Preview("Acquisition Review · Release Picker · Download Busy") {
        acquisitionReleasePickerReviewSection(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates,
            isBusy: true,
            activeAction: .download(RequestActivityPreviewFixtures.categoryCandidate.id)
        )
    }

    #Preview("Acquisition Review · Release Picker · Blocklist Busy") {
        acquisitionReleasePickerReviewSection(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates,
            isBusy: true,
            activeAction: .blocklist(RequestActivityPreviewFixtures.categoryCandidate.id)
        )
    }

    #Preview("Acquisition Review · Release Picker · Blocklist Confirmation") {
        acquisitionReleasePickerReviewSection(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates,
            candidatePendingBlocklist: RequestActivityPreviewFixtures.categoryCandidate
        )
    }

    #Preview("Acquisition Review · Release Picker · Mutation Failure") {
        acquisitionReleasePickerReviewManagement(
            candidates: RequestActivityPreviewFixtures.releasePickerCandidates,
            actionErrorMessage: "The selected release could not be downloaded."
        )
    }

    #Preview("Acquisition Review · Release Picker · Accessibility Dynamic Type") {
        acquisitionReleasePickerReviewSection(
            candidates: [
                RequestActivityPreviewFixtures.categoryCandidate,
                RequestActivityPreviewFixtures.rejectedCandidate,
            ]
        )
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    @MainActor
    private func acquisitionReleasePickerReviewSection(
        candidates: [RequestActivityReleaseCandidate],
        isLoading: Bool = false,
        isBusy: Bool = false,
        activeAction: RequestActivityCandidateAction? = nil,
        showsOnlyRelevant: Bool = true,
        candidatePendingBlocklist: RequestActivityReleaseCandidate? = nil,
        width: CGFloat = 390
    ) -> some View {
        ScrollView {
            RequestActivityReleasesSection(
                previewCandidates: candidates,
                isLoading: isLoading,
                isBusy: isBusy,
                activeAction: activeAction,
                showsOnlyRelevant: showsOnlyRelevant,
                candidatePendingBlocklist: candidatePendingBlocklist
            )
            .frame(maxWidth: width)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionReleasePickerReviewCandidate(
        _ candidate: RequestActivityReleaseCandidate
    ) -> some View {
        RequestActivityCandidateRow(
            candidate: candidate,
            layout: .card,
            isDisabled: false,
            activeAction: nil,
            onDownload: { _ in },
            onRequestBlocklist: { _ in }
        )
        .frame(width: 390)
        .padding()
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionReleasePickerReviewManagement(
        candidates: [RequestActivityReleaseCandidate],
        actionErrorMessage: String? = nil
    ) -> some View {
        let baseDetail = EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
            status: "awaiting-selection"
        )
        let detail = RequestActivityAcquisitionDetail(
            summary: baseDetail.summary,
            candidates: candidates
        )

        return ScrollView {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: EntityAcquisitionPanelPreviewFixtures.acquisitionID,
                service: PreviewRequestActivityService(scenario: .content),
                previewDetail: detail,
                actionErrorMessage: actionErrorMessage
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
#endif
