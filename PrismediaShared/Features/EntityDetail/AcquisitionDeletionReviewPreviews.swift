#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Acquisition Review · Deletion · Menu · Persistent Actions") {
        acquisitionDeletionReviewManagement(
            detail: EntityAcquisitionPanelPreviewFixtures.downloadingDetail,
            transfer: RequestActivityPreviewFixtures.transfer,
            files: RequestActivityPreviewFixtures.files
        )
    }

    #Preview("Acquisition Review · Deletion · Attention · Visible Recovery") {
        acquisitionDeletionReviewManagement(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                statusMessage: "The imported file could not be finalized.",
                hasResumableImport: true
            )
        )
    }

    #Preview("Acquisition Review · Deletion · Cancel · Busy Inline Status") {
        acquisitionDeletionReviewManagement(
            detail: EntityAcquisitionPanelPreviewFixtures.downloadingDetail,
            transfer: RequestActivityPreviewFixtures.transfer,
            files: RequestActivityPreviewFixtures.files,
            isActing: true,
            activeLifecycleAction: .cancel
        )
    }

    #Preview("Acquisition Review · Deletion · Start Over · Confirmation Owner") {
        acquisitionDeletionReviewManagement(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                statusMessage: "The interrupted import can be resumed.",
                hasResumableImport: true
            ),
            confirmsStartOver: true
        )
    }

    #Preview("Acquisition Review · Deletion · Delete Files · Confirmation Owner") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.downloadingState,
            detail: EntityAcquisitionPanelPreviewFixtures.downloadingDetail,
            confirmsDeleteFiles: true
        )
    }

    #Preview("Acquisition Review · Deletion · Delete Files · Busy · Content Preserved") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.downloadingState,
            detail: EntityAcquisitionPanelPreviewFixtures.downloadingDetail,
            isMutating: true,
            activeCommand: .deleteFiles(EntityAcquisitionPanelPreviewFixtures.entityID)
        )
    }

    #Preview("Acquisition Review · Deletion · Delete Files · Monitor Locked") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.deletingFilesState
        )
    }

    #Preview("Acquisition Review · Deletion · Delete Files · Partial Failure · Retry") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.activeLeafState,
            mutationError: "The audiobook folder is in use.",
            failedCommand: .deleteFiles(EntityAcquisitionPanelPreviewFixtures.entityID),
            deletionResult: EntityDeleteResponse(
                deleted: 0,
                filesDeleted: 1,
                failures: [
                    EntityDeleteFailure(
                        id: EntityAcquisitionPanelPreviewFixtures.entityID,
                        message: "The audiobook folder is in use."
                    )
                ],
                reverted: 1
            )
        )
    }

    #Preview("Acquisition Review · Deletion · Delete Files · Saved · Refresh Failure") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.activeLeafState,
            refreshError: "The updated entity document is temporarily unavailable.",
            savedMutationCommand: .deleteFiles(EntityAcquisitionPanelPreviewFixtures.entityID)
        )
    }

    #Preview("Acquisition Review · Deletion · Delete Files · Reverted to Wanted") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.activeLeafState,
            deletionResult: EntityDeleteResponse(
                deleted: 0,
                filesDeleted: 2,
                reverted: 1
            )
        )
    }

    #Preview("Acquisition Review · Deletion · Unmonitor · Entity Confirmation") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.activeLeafState,
            confirmsUnmonitor: true
        )
    }

    #Preview("Acquisition Review · Deletion · Unmonitor · Audiobook Confirmation") {
        acquisitionDeletionReviewPanel(
            state: acquisitionDeletionReviewAudiobookState,
            confirmsUnmonitor: true
        )
    }

    #Preview("Acquisition Review · Deletion · Unmonitor · Cleanup Retry · Content Preserved") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.stoppingState
        )
    }

    #Preview("Acquisition Review · Deletion · Child Unmonitor · Confirmation Owner") {
        acquisitionDeletionReviewChildConfirmation
    }

    #Preview("Acquisition Review · Deletion · Remove Acquisition · Confirmation Owner") {
        RequestActivitySurface(
            section: .downloads,
            service: PreviewRequestActivityService(scenario: .content),
            previewDownloads: acquisitionDeletionReviewDownloads,
            pendingRemovalIDs: [EntityAcquisitionPanelPreviewFixtures.acquisitionID],
            selectedIDs: [EntityAcquisitionPanelPreviewFixtures.acquisitionID]
        )
        .frame(minWidth: 390, minHeight: 620)
        .preferredColorScheme(.dark)
    }

    #Preview("Acquisition Review · Deletion · Wanted Unmonitor · Confirmation Owner") {
        RequestActivitySurface(
            section: .missing,
            service: PreviewRequestActivityService(scenario: .content),
            previewDownloads: [],
            previewWantedPage: acquisitionDeletionReviewWantedPage,
            pendingUnmonitorTargets: [RequestActivityPreviewFixtures.wantedItem],
            selectedIDs: [RequestActivityPreviewFixtures.wantedItem.id]
        )
        .frame(minWidth: 390, minHeight: 620)
        .preferredColorScheme(.dark)
    }

    #Preview("Acquisition Review · Deletion · Adaptive · Wide") {
        acquisitionDeletionReviewPanel(
            state: EntityAcquisitionPanelPreviewFixtures.downloadingState,
            detail: EntityAcquisitionPanelPreviewFixtures.downloadingDetail
        )
        .frame(width: 920)
    }

    #Preview("Acquisition Review · Deletion · Accessibility Text") {
        acquisitionDeletionReviewManagement(
            detail: EntityAcquisitionPanelPreviewFixtures.lifecycleDetail(
                status: "failed",
                hasResumableImport: true
            )
        )
        .dynamicTypeSize(.accessibility4)
    }

    @MainActor
    private func acquisitionDeletionReviewPanel(
        state monitorState: EntityMonitorState,
        detail: RequestActivityAcquisitionDetail? = nil,
        isMutating: Bool = false,
        mutationError: String? = nil,
        refreshError: String? = nil,
        activeCommand: EntityAcquisitionCommand? = nil,
        failedCommand: EntityAcquisitionCommand? = nil,
        deletionResult: EntityDeleteResponse? = nil,
        savedMutationCommand: EntityAcquisitionCommand? = nil,
        confirmsUnmonitor: Bool = false,
        confirmsDeleteFiles: Bool = false
    ) -> some View {
        ScrollView {
            EntityAcquisitionPanel(
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                entityTitle: "Dune",
                entityKind: .book,
                hasOwnedContent: true,
                canDeleteFiles: true,
                previewPhase: .content(
                    EntityAcquisitionPanelSnapshot(
                        state: monitorState,
                        latestAcquisition: detail
                    )
                ),
                acquisitionService: PreviewEntityAcquisitionService(
                    snapshot: monitorState,
                    acquisitionDetail: detail
                ),
                requestActivityService: PreviewRequestActivityService(
                    scenario: detail == nil ? .content : .downloading
                ),
                isMutating: isMutating,
                mutationError: mutationError,
                refreshError: refreshError,
                activeCommand: activeCommand,
                failedCommand: failedCommand,
                deletionResult: deletionResult,
                savedMutationCommand: savedMutationCommand,
                confirmsUnmonitor: confirmsUnmonitor,
                confirmsDeleteFiles: confirmsDeleteFiles
            )
            .frame(maxWidth: 760)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionDeletionReviewManagement(
        detail: RequestActivityAcquisitionDetail,
        transfer: RequestActivityTransfer? = nil,
        files: RequestActivityFiles? = nil,
        isActing: Bool = false,
        activeLifecycleAction: RequestActivityAcquisitionAction? = nil,
        confirmsStartOver: Bool = false
    ) -> some View {
        ScrollView {
            RequestActivityAcquisitionManagementSections(
                acquisitionID: detail.summary.id,
                service: PreviewRequestActivityService(scenario: .downloading),
                previewDetail: detail,
                previewTransfer: transfer,
                previewFiles: files,
                isActing: isActing,
                activeLifecycleAction: activeLifecycleAction,
                confirmsStartOver: confirmsStartOver,
                showsDeleteFilesAction: true
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: 760)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private var acquisitionDeletionReviewChildConfirmation: some View {
        ScrollView {
            EntityChildMonitoringSection(
                title: "Episode Monitoring",
                previewItems: EntityAcquisitionPanelPreviewFixtures.childReviewItems,
                primaryAccent: PrismediaColor.spectrumCyan,
                service: EntityAcquisitionService(
                    port: PreviewEntityAcquisitionService(
                        snapshot: EntityAcquisitionPanelPreviewFixtures.groupingState,
                        additionalSnapshots: EntityAcquisitionPanelPreviewFixtures.childStates
                    )
                ),
                pendingConfirmation: .item(
                    EntityAcquisitionPanelPreviewFixtures.childReviewItems[1].id
                )
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(maxWidth: 760)
            .padding()
        }
        .background(PrismediaBackdrop())
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    private var acquisitionDeletionReviewAudiobookState: EntityMonitorState {
        EntityMonitorState(
            entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
            canMonitor: true,
            canRequest: true,
            trackableProviders: ["Audnexus"],
            discoversChildren: false,
            canSearchMissingChildren: false,
            missingChildEntityKind: nil,
            monitor: EntityMonitor(
                id: EntityAcquisitionPanelPreviewFixtures.monitorID,
                kind: .book,
                acquisitionID: EntityAcquisitionPanelPreviewFixtures.acquisitionID,
                status: .active,
                title: "Dune",
                author: "Frank Herbert",
                acquisitionStatus: nil,
                createdAt: EntityAcquisitionPanelPreviewFixtures.referenceDate,
                updatedAt: EntityAcquisitionPanelPreviewFixtures.referenceDate,
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                preset: "all",
                bookRendition: RequestActivityBookRendition(rawValue: "audiobook")
            ),
            latestAcquisition: nil
        )
    }

    private var acquisitionDeletionReviewDownloads: [RequestActivityDownload] {
        let json = """
            [
              {
                "acquisitionId":"\(EntityAcquisitionPanelPreviewFixtures.acquisitionID.uuidString)",
                "entityId":"\(EntityAcquisitionPanelPreviewFixtures.entityID.uuidString)",
                "kind":"book",
                "title":"Dune",
                "author":"Frank Herbert",
                "status":"downloading",
                "progress":0.64,
                "updatedAt":"2026-07-12T18:00:00Z"
              }
            ]
            """
        return try! PrismediaJSON.decoder().decode(
            [RequestActivityDownload].self,
            from: Data(json.utf8)
        )
    }

    private var acquisitionDeletionReviewWantedPage: RequestActivityWantedPage {
        let json = """
            {
              "items":[
                {
                  "monitorId":"\(RequestActivityPreviewFixtures.wantedItem.id.uuidString)",
                  "acquisitionId":"44444444-4444-4444-4444-444444444444",
                  "entityId":"cccccccc-cccc-cccc-cccc-cccccccccccc",
                  "kind":"book",
                  "title":"The Left Hand of Darkness",
                  "author":"Ursula K. Le Guin",
                  "monitorStatus":"active",
                  "lastSearchedAt":"2026-07-12T16:00:00Z",
                  "barrenSearches":2
                }
              ],
              "total":1
            }
            """
        return try! PrismediaJSON.decoder().decode(
            RequestActivityWantedPage.self,
            from: Data(json.utf8)
        )
    }
#endif
