import SwiftUI

struct FavoriteEntityGridView: View {
    @Environment(PrismediaAppRouter.self) private var router

    let section: FavoritesSectionDefinition
    let loader: any EntityGridLoading
    let detailDependencies: EntityDetailDependencies
    let actionPolicy: EntityGridActionPolicy
    let mutationService: (any EntityGridMutationServicing)?

    var body: some View {
        EntityGridView(
            configuration: EntityGridConfiguration.library(
                destinationID: section.destinationID,
                title: "Favorite \(section.title)",
                query: section.query,
                preferencesID: "favorites:\(section.kind.rawValue)"
            ),
            loader: loader,
            feedMediaDependencies: EntityMediaFeedDependencies(
                detailLoader: detailDependencies.detailLoader,
                sourceLoader: detailDependencies.imageSourceLoader,
                videoAspectRatioLoader: detailDependencies.imageVideoAspectRatioLoader
            ),
            onOpenFeedItem: { item, mediaSequence in
                router.open(
                    entity: item,
                    within: item.kind == .image ? mediaSequence : nil
                )
            },
            actionPolicy: actionPolicy,
            mutationService: mutationService,
            itemContent: { item, layout in
                EntityThumbnailNavigationSurface(item: item, layout: layout)
            }
        )
    }
}

#if DEBUG
    #Preview("Favorite Videos Grid") {
        let detailLoader = DashboardPreviewDetailLoader()
        PreviewShell(signedIn: true) {
            NavigationStack {
                FavoriteEntityGridView(
                    section: FavoritesCatalog.sections[0],
                    loader: StaticEntityGridLoader(items: PrismediaPreviewData.videos),
                    detailDependencies: EntityDetailDependencies(
                        detailLoader: detailLoader,
                        mutator: nil,
                        collectionItemsLoader: nil,
                        readerService: nil,
                        videoPlaybackService: nil,
                        onEntityMutated: {}
                    ),
                    actionPolicy: .disabled,
                    mutationService: nil
                )
            }
        }
    }
#endif
