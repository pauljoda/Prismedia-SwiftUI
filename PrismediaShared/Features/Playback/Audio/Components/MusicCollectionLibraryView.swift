#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicCollectionLibraryView: View {
        let configuration: EntityGridConfiguration
        let loader: MusicCollectionCatalogLoader
        let actionPolicy: EntityGridActionPolicy
        let mutationService: (any EntityGridMutationServicing)?

        var body: some View {
            EntityGridView(
                configuration: configuration,
                loader: loader,
                actionPolicy: actionPolicy,
                mutationService: mutationService
            ) { item, layout in
                EntityThumbnailNavigationSurface(
                    item: item,
                    layout: layout,
                    intent: .audioCollection
                )
            }
        }
    }

    #if DEBUG
        #Preview("Music Collections") {
            let preview = MusicCollectionPreviewLoader()
            PreviewShell(signedIn: true) {
                MusicCollectionLibraryView(
                    configuration: EntityGridConfiguration(
                        title: "Collections",
                        query: EntityListQuery(kind: .collection)
                    ),
                    loader: MusicCollectionCatalogLoader(
                        catalogLoader: MusicLibraryPreviewLoader(
                            items: [MusicCollectionPreviewLoader.collection]
                        ),
                        collectionItemsLoader: preview
                    ),
                    actionPolicy: .disabled,
                    mutationService: nil
                )
            }
        }
    #endif
#endif
