import SwiftUI

extension EntityDetailView {
    func failureView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Details", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent) {
                Task { await loadDetail() }
            }
        }
        .accessibilityIdentifier("entity-detail.failure")
    }

    func detailView(_ detail: EntityDetail) -> some View {
        EntityDetailPlatformDestinationView(
            detail: detail,
            link: link,
            dependencies: dependencies,
            imageViewerSession: imageViewerSession,
            onAcquisitionMutated: refreshAfterAcquisitionMutation,
            onEntityPruned: handlePrunedEntity,
            standardContent: standardDetailView
        )
    }

    func standardDetailView(_ detail: EntityDetail) -> some View {
        let presentation = EntityDetailPresentation(
            detail: detail,
            canEditMetadata: dependencies.metadataMutator != nil
        )

        return EntityDetailPlatformSurface(
            detail: detail,
            presentation: presentation,
            previewPath: link.thumbnailPreview?.artworkPath,
            palette: $artworkPalette,
            standardContent: {
                standardArtworkDetailView(detail, presentation: presentation)
            },
            backdropContent: {
                detailScrollView(
                    detail,
                    presentation: presentation,
                    showsHeroArtwork: false,
                    showsPageAtmosphere: false
                )
            }
        )
    }

    func standardArtworkDetailView(
        _ detail: EntityDetail,
        presentation: EntityDetailPresentation
    ) -> some View {
        let activePalette = artworkPalette

        return detailScrollView(detail, presentation: presentation)
            .environment(\.artworkPalette, activePalette)
            .environment(
                \.artworkPrimaryAccent,
                activePalette?.primary.color ?? PrismediaColor.accent
            )
            .environment(
                \.artworkSecondaryText,
                activePalette?.secondary.color ?? PrismediaColor.textSecondary
            )
    }
}
