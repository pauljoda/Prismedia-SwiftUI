#if os(macOS)
import SwiftUI

struct EntityDetailPlatformDestinationView<StandardContent: View>: View {
    let detail: EntityDetail
    let link: EntityLink
    let dependencies: EntityDetailDependencies
    let imageViewerSession: EntityImageViewerSession?
    let onAcquisitionMutated: @MainActor () async -> Void
    let onEntityPruned: @MainActor () -> Void
    @ViewBuilder let standardContent: (EntityDetail) -> StandardContent

    var body: some View {
        switch EntityDestinationPolicy.style(
            for: detail.kind,
            on: .current,
            intent: link.intent
        ) {
        case .nativeAlbum:
            MusicAlbumDetailView(
                detail: detail,
                preview: link.thumbnailPreview,
                sectionSupport: sectionSupport
            )
        case .nativeArtist:
            MusicArtistDetailView(
                detail: detail,
                sectionSupport: sectionSupport
            )
        case .nativeAudioCollection:
            if let collectionItemsLoader = dependencies.collectionItemsLoader {
                MusicCollectionDetailView(
                    detail: detail,
                    preview: link.thumbnailPreview,
                    loader: MusicCollectionQueueLoader(
                        collectionItemsLoader: collectionItemsLoader,
                        detailLoader: dependencies.detailLoader
                    ),
                    sectionSupport: sectionSupport
                )
            } else {
                standardContent(detail)
            }
        case .nativeImageViewer:
            if let imageViewerSession {
                EntityImageViewerView(
                    session: imageViewerSession,
                    initialDetail: detail,
                    dependencies: dependencies
                )
            } else {
                standardContent(detail)
            }
        default:
            standardContent(detail)
        }
    }

    private var sectionSupport: EntityDetailSectionSupport {
        EntityDetailSectionSupport(
            ownerLink: link,
            dependencies: dependencies,
            onAcquisitionMutated: onAcquisitionMutated,
            onEntityPruned: onEntityPruned
        )
    }
}

#if DEBUG
    #Preview("Mac Entity Detail Destination") {
        let detail = EntityDetailPreviewFixture.detail
        let dependencies = EntityDetailDependencies(
            detailLoader: PreviewEntityDetailLoader(detail: detail),
            mutator: nil,
            collectionItemsLoader: nil,
            readerService: nil,
            videoPlaybackService: nil,
            onEntityMutated: {}
        )
        EntityDetailPlatformDestinationView(
            detail: detail,
            link: EntityLink(entityID: detail.id, kind: detail.kind),
            dependencies: dependencies,
            imageViewerSession: nil,
            onAcquisitionMutated: {},
            onEntityPruned: {},
            standardContent: { Text($0.title).padding() }
        )
    }
#endif
#endif
