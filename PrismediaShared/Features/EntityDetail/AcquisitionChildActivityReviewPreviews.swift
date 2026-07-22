#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Acquisition Review · Child Activity · Loading") {
        acquisitionChildActivityReviewSection(
            items: [],
            hasLoaded: false
        )
    }

    #Preview("Acquisition Review · Child Activity · Quiet · Collapsed") {
        acquisitionChildActivityReviewSection(
            items: [EntityChildAcquisitionActivityPreviewFixtures.quietItem],
            isExpanded: false
        )
    }

    #Preview("Acquisition Review · Child Activity · Quiet · Expanded") {
        acquisitionChildActivityReviewSection(
            items: [EntityChildAcquisitionActivityPreviewFixtures.quietItem]
        )
    }

    #Preview("Acquisition Review · Child Activity · Active · iPhone") {
        acquisitionChildActivityReviewSection(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.importingItem,
            ],
            width: 390
        )
    }

    #Preview(
        "Acquisition Review · Child Activity · Simultaneous · iPad and Mac",
        traits: .fixedLayout(width: 1_000, height: 1_000)
    ) {
        acquisitionChildActivityReviewSection(
            items: EntityChildAcquisitionActivityPreviewFixtures.simultaneousItems,
            width: 760
        )
    }

    #Preview("Acquisition Review · Child Activity · Refresh Failure · Content Preserved") {
        acquisitionChildActivityReviewSection(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.failedItem,
            ],
            errorMessage: "The latest child states could not be loaded. Existing activity will remain visible."
        )
    }

    #Preview("Acquisition Review · Child Activity · Parent Monitoring Off") {
        acquisitionChildActivityParentReviewPanel()
    }

    #Preview("Acquisition Review · Child Activity · Row · Preparing Metadata") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.preparingItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Pending") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.pendingItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Searching") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.searchingItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Queued") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.queuedItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Choose Release") {
        acquisitionChildActivityReviewRow(
            EntityChildAcquisitionActivityPreviewFixtures.awaitingSelectionItem
        )
    }

    #Preview("Acquisition Review · Child Activity · Row · Downloading · Determinate") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.downloadingItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Importing · Determinate") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.importingItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Downloaded · Import Handoff") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.downloadedItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Imported") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.importedItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Failed") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.failedItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Manual Import Required") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.manualImportItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Cancelled") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.cancelledItem)
    }

    #Preview("Acquisition Review · Child Activity · Row · Unknown · Polling") {
        acquisitionChildActivityReviewRow(EntityChildAcquisitionActivityPreviewFixtures.unknownItem)
    }

    #Preview("Acquisition Review · Child Activity · Accessibility Dynamic Type") {
        acquisitionChildActivityReviewSection(
            items: [
                EntityChildAcquisitionActivityPreviewFixtures.downloadingItem,
                EntityChildAcquisitionActivityPreviewFixtures.manualImportItem,
            ]
        )
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    @MainActor
    private func acquisitionChildActivityReviewSection(
        items: [EntityChildAcquisitionActivityItem],
        isExpanded: Bool = true,
        hasLoaded: Bool = true,
        errorMessage: String? = nil,
        width: CGFloat = 620
    ) -> some View {
        PreviewShell {
            NavigationStack {
                ScrollView {
                    EntityChildAcquisitionActivitySection(
                        previewItems: items,
                        service: EntityChildAcquisitionActivityPreviewFixtures.service,
                        isExpanded: isExpanded,
                        hasLoaded: hasLoaded,
                        errorMessage: errorMessage
                    )
                    .padding(PrismediaSpacing.extraLarge)
                    .prismediaCard()
                    .frame(maxWidth: width)
                    .padding()
                }
                .background(PrismediaBackdrop())
            }
        }
        .environment(\.prismediaPageIsActive, false)
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionChildActivityReviewRow(
        _ item: EntityChildAcquisitionActivityItem
    ) -> some View {
        PreviewShell {
            NavigationStack {
                EntityChildAcquisitionActivityRow(item: item)
                    .padding(PrismediaSpacing.extraLarge)
                    .prismediaCard()
                    .frame(maxWidth: 620)
                    .padding()
                    .background(PrismediaBackdrop())
            }
        }
        .preferredColorScheme(.dark)
    }

    @MainActor
    private func acquisitionChildActivityParentReviewPanel() -> some View {
        PreviewShell {
            ScrollView {
                EntityAcquisitionPanel(
                    entityID: EntityChildAcquisitionActivityPreviewFixtures.parentID,
                    entityKind: .videoSeason,
                    childGroups: [EntityChildAcquisitionActivityPreviewFixtures.childGroup],
                    previewPhase: .content(
                        EntityAcquisitionPanelSnapshot(
                            state: EntityAcquisitionPanelPreviewFixtures.wantedState,
                            latestAcquisition: nil
                        )
                    ),
                    acquisitionService: PreviewEntityAcquisitionService(
                        snapshot: EntityAcquisitionPanelPreviewFixtures.wantedState,
                        additionalSnapshots: EntityChildAcquisitionActivityPreviewFixtures.childStates
                    )
                )
                .frame(maxWidth: 720)
                .padding()
            }
            .background(PrismediaBackdrop())
        }
        .environment(\.artworkPrimaryAccent, PrismediaColor.spectrumCyan)
        .environment(\.artworkSecondaryText, PrismediaColor.textSecondary)
        .preferredColorScheme(.dark)
    }
#endif
