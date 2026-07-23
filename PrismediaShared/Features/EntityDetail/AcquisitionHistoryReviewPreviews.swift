#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Acquisition Review · History · Collapsed · Latest Events") {
        acquisitionHistoryReviewSection(
            entries: RequestActivityPreviewFixtures.historyEntries,
            loadState: .loaded,
            isInitiallyExpanded: false
        )
    }

    #Preview("Acquisition Review · History · Expanded · Event Taxonomy") {
        acquisitionHistoryReviewSection(
            entries: RequestActivityPreviewFixtures.historyEntries,
            loadState: .loaded
        )
    }

    #Preview("Acquisition Review · History · Loading") {
        acquisitionHistoryReviewSection(
            entries: [],
            loadState: .loading
        )
    }

    #Preview("Acquisition Review · History · Empty") {
        acquisitionHistoryReviewSection(
            entries: [],
            loadState: .loaded
        )
    }

    #Preview("Acquisition Review · History · Initial Error · Retry") {
        acquisitionHistoryReviewSection(
            entries: [],
            loadState: .failed("The acquisition history service could not be reached.")
        )
    }

    #Preview("Acquisition Review · History · Latest 50 · Limit Disclosure") {
        acquisitionHistoryReviewSection(
            entries: RequestActivityPreviewFixtures.historyLimitEntries,
            loadState: .loaded,
            width: 560
        )
    }

    #Preview("Acquisition Review · History · Technical Detail · Compact") {
        ScrollView {
            EntityAcquisitionHistoryRow(
                entry: RequestActivityPreviewFixtures.historyEntries[5],
                referenceDate: RequestActivityPreviewFixtures.referenceDate
            )
            .padding(PrismediaSpacing.extraLarge)
            .prismediaCard()
            .frame(width: 340)
            .padding()
        }
        .background(PrismediaBackdrop())
        .preferredColorScheme(.dark)
    }

    #Preview(
        "Acquisition Review · History · Adaptive · Wide",
        traits: .fixedLayout(width: 1_000, height: 900)
    ) {
        acquisitionHistoryReviewSection(
            entries: RequestActivityPreviewFixtures.historyEntries,
            loadState: .loaded,
            width: 820
        )
    }

    #Preview("Acquisition Review · History · Accessibility Text") {
        acquisitionHistoryReviewSection(
            entries: Array(RequestActivityPreviewFixtures.historyEntries.prefix(3)),
            loadState: .loaded
        )
        .environment(\.dynamicTypeSize, .accessibility4)
    }

    @MainActor
    private func acquisitionHistoryReviewSection(
        entries: [RequestActivityHistoryEntry],
        loadState: EntityAcquisitionHistoryLoadState,
        isInitiallyExpanded: Bool = true,
        width: CGFloat = 390
    ) -> some View {
        ScrollView {
            EntityAcquisitionHistorySection(
                entries: entries,
                loadState: loadState,
                entityID: EntityAcquisitionPanelPreviewFixtures.entityID,
                service: EntityAcquisitionService(
                    port: PreviewEntityAcquisitionService(
                        snapshot: EntityAcquisitionPanelPreviewFixtures.downloadingState
                    )
                ),
                referenceDate: RequestActivityPreviewFixtures.referenceDate,
                isInitiallyExpanded: isInitiallyExpanded,
                onRetry: {}
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
