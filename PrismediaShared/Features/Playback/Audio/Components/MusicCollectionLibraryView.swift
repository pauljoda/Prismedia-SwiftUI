#if os(iOS) || os(macOS)
    import SwiftUI

    struct MusicCollectionLibraryView: View {
        let configuration: EntityGridConfiguration
        let loader: MusicCollectionCatalogLoader

        var body: some View {
            EntityGridView(
                configuration: configuration,
                loader: loader
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
                    )
                )
            }
        }
    #endif
#endif
