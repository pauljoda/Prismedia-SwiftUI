#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Acquisition Review · Failed Parent · Integration · Initial Child Load") {
        acquisitionFailedParentReviewPanel()
    }

    #Preview("Acquisition Review · Failed Parent · Active · iPhone · Collapsed") {
        acquisitionFailedParentReviewSurface(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.importingItem,
            ],
            width: 390
        )
    }

    #Preview("Acquisition Review · Failed Parent · Active · Parent Expanded · Search Again") {
        acquisitionFailedParentReviewSurface(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.searchingItem,
            ],
            parentExpanded: true
        )
    }

    #Preview("Acquisition Review · Failed Parent · Active · Parent Expanded · Resumable Import") {
        acquisitionFailedParentReviewSurface(
            items: [EntityChildAcquisitionActivityPreviewFixtures.downloadingItem],
            parentDetail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                statusMessage: "The season-pack import stopped after saving its recovery plan.",
                hasResumableImport: true
            ),
            parentExpanded: true
        )
    }

    #Preview("Acquisition Review · Failed Parent · Mixed Active Attention Completed") {
        acquisitionFailedParentReviewSurface(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.failedItem,
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.importedItem,
                EntityChildAcquisitionActivityPreviewFixtures.manualImportItem,
                EntityChildAcquisitionActivityPreviewFixtures.searchingItem,
            ]
        )
    }

    #Preview("Acquisition Review · Failed Parent · Track Fallback") {
        acquisitionFailedParentReviewSurface(
            items: EntityChildAcquisitionActivityPreviewFixtures.mixedShapeItems.filter {
                $0.entity.kind == .audioTrack
            }
        )
    }

    #Preview("Acquisition Review · Failed Parent · Child Refresh Failure · Content Preserved") {
        acquisitionFailedParentReviewSurface(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.failedItem,
            ],
            childErrorMessage: "Child activity could not refresh. Existing progress remains visible."
        )
    }

    #Preview("Acquisition Review · Failed Parent · Parent Expanded · Initial Loading") {
        acquisitionFailedParentReviewSurface(
            items: [EntityChildAcquisitionActivityPreviewFixtures.downloadingItem],
            parentDetail: nil,
            parentExpanded: true,
            parentIsLoading: true
        )
    }

    #Preview("Acquisition Review · Failed Parent · Parent Action Failure · Scoped Retry") {
        acquisitionFailedParentReviewSurface(
            items: [EntityChildAcquisitionActivityPreviewFixtures.downloadingItem],
            parentExpanded: true,
            parentActionError: "The parent search could not be restarted.",
            failedLifecycleAction: .research
        )
    }

    #Preview("Acquisition Review · Failed Parent · Parent Live Refresh Failure · Scoped Retry") {
        acquisitionFailedParentReviewSurface(
            items: [EntityChildAcquisitionActivityPreviewFixtures.downloadingItem],
            parentExpanded: true,
            parentRefreshMessage: "Live updates are failing. Prismedia will keep retrying in the background."
        )
    }

    #Preview("Acquisition Review · Failed Parent · Completion · Parent Restored") {
        acquisitionFailedParentReviewSurface(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.failedItem,
                EntityChildAcquisitionActivityPreviewFixtures.importedItem,
                EntityChildAcquisitionActivityPreviewFixtures.cancelledItem,
            ]
        )
    }

    #Preview(
        "Acquisition Review · Failed Parent · Active · Wide iPad and Mac",
        traits: .fixedLayout(width: 1_000, height: 1_000)
    ) {
        acquisitionFailedParentReviewSurface(
            items: EntityChildAcquisitionActivityPreviewFixtures.simultaneousItems,
            width: 760
        )
    }

    #Preview("Acquisition Review · Failed Parent · Accessibility Dynamic Type") {
        acquisitionFailedParentReviewSurface(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.manualImportItem,
            ],
            parentExpanded: true,
            width: 390
        )
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    @MainActor
    private func acquisitionFailedParentReviewPanel() -> some View {
        PreviewShell {
            ScrollView {
                EntityAcquisitionPanel(
                    entityID: EntityChildAcquisitionActivityPreviewFixtures.parentID,
                    entityKind: .videoSeason,
                    childGroups: [EntityChildAcquisitionActivityPreviewFixtures.childGroup],
                    previewPhase: .content(
                        EntityAcquisitionPanelSnapshot(
                            state: EntityAcquisitionPanelPreviewFixtures.groupingState,
                            latestAcquisition: acquisitionFailedParentReviewDetail()
                        )
                    ),
                    acquisitionService: PreviewEntityAcquisitionService(
                        snapshot: EntityAcquisitionPanelPreviewFixtures.groupingState,
                        additionalSnapshots: EntityChildAcquisitionActivityPreviewFixtures.childStates
                    ),
                    requestActivityService: PreviewRequestActivityService(scenario: .content)
                )
                .frame(maxWidth: 720)
                .padding()
            }
            .background(PrismediaBackdrop())
        }
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionFailedParentReviewSurface(
        items: [EntityChildAcquisitionActivityItem],
        parentDetail: RequestActivityAcquisitionDetail? = acquisitionFailedParentReviewDetail(),
        parentExpanded: Bool = false,
        childHasLoaded: Bool = true,
        childErrorMessage: String? = nil,
        parentIsLoading: Bool = false,
        parentActionError: String? = nil,
        failedLifecycleAction: RequestActivityAcquisitionAction? = nil,
        parentRefreshMessage: String? = nil,
        width: CGFloat = 620
    ) -> some View {
        let eligibleChildren = items.map(\.entity)
        let activeChildren = eligibleChildren.filter { child in
            [child.wantedStatus, child.latestAcquisitionStatus]
                .compactMap { $0 }
                .contains { RequestActivityStatusPolicy.shouldPoll($0) }
        }
        let demotesParent = EntityFailedParentAcquisitionPolicy.shouldDemoteParent(
            status: parentDetail?.summary.status,
            activeChildren: activeChildren
        )

        return PreviewShell {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                        EntityChildAcquisitionActivitySection(
                            previewItems: items,
                            service: EntityChildAcquisitionActivityPreviewFixtures.service,
                            isExpanded: true,
                            hasLoaded: childHasLoaded,
                            errorMessage: childErrorMessage
                        )

                        Divider()

                        if demotesParent {
                            EntityFailedParentAcquisitionSection(
                                activeSummary: EntityFailedParentAcquisitionPolicy.activeSummary(
                                    activeChildren: activeChildren,
                                    eligibleChildren: eligibleChildren
                                ),
                                isExpanded: parentExpanded
                            ) {
                                acquisitionFailedParentReviewManagement(
                                    detail: parentDetail,
                                    isLoading: parentIsLoading,
                                    actionError: parentActionError,
                                    failedLifecycleAction: failedLifecycleAction,
                                    refreshMessage: parentRefreshMessage
                                )
                            }
                        } else {
                            acquisitionFailedParentReviewManagement(
                                detail: parentDetail,
                                isLoading: parentIsLoading,
                                actionError: parentActionError,
                                failedLifecycleAction: failedLifecycleAction,
                                refreshMessage: parentRefreshMessage
                            )
                        }
                    }
                    .padding(PrismediaSpacing.extraLarge)
                    .prismediaCard()
                    .frame(maxWidth: width)
                    .padding()
                }
                .background(PrismediaBackdrop())
            }
        }
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionFailedParentReviewManagement(
        detail: RequestActivityAcquisitionDetail?,
        isLoading: Bool,
        actionError: String?,
        failedLifecycleAction: RequestActivityAcquisitionAction?,
        refreshMessage: String?
    ) -> some View {
        RequestActivityAcquisitionManagementSections(
            acquisitionID: EntityAcquisitionPanelPreviewFixtures.acquisitionID,
            service: PreviewRequestActivityService(scenario: .content),
            previewDetail: detail,
            isLoading: isLoading,
            actionErrorMessage: actionError,
            refreshMessage: refreshMessage,
            failedLifecycleAction: failedLifecycleAction
        )
    }

    private func acquisitionFailedParentReviewDetail() -> RequestActivityAcquisitionDetail {
        EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
            status: "failed",
            statusMessage: "The season-pack release failed, so Prismedia started child fallback searches."
        )
    }
#endif
