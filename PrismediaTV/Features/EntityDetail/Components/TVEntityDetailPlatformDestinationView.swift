#if os(tvOS)
import SwiftUI

struct EntityDetailPlatformDestinationView<StandardContent: View>: View {
    let detail: EntityDetail
    let link: EntityLink
    let dependencies: EntityDetailDependencies
    let imageViewerSession: EntityImageViewerSession?
    @ViewBuilder let standardContent: (EntityDetail) -> StandardContent

    var body: some View {
        switch EntityDestinationPolicy.style(
            for: detail.kind,
            on: .current,
            intent: link.intent
        ) {
        case .televisionSeasons:
            TVSeasonsDetailView(
                rootDetail: detail,
                routeLink: link,
                dependencies: dependencies
            )
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
}

#Preview("TV Entity Detail Destination") {
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
        standardContent: { Text($0.title).padding(72) }
    )
}
#endif
