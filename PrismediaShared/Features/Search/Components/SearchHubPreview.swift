import SwiftUI

#if DEBUG
    struct SearchHubPreview: View {
        @State private var searchText: String

        let loader: SearchHubPreviewLoader
        let user: UserAccount
        let dynamicTypeSize: DynamicTypeSize?

        init(
            searchText: String = "",
            loader: SearchHubPreviewLoader = SearchHubPreviewLoader(),
            user: UserAccount = PrismediaPreviewData.user,
            dynamicTypeSize: DynamicTypeSize? = nil
        ) {
            _searchText = State(initialValue: searchText)
            self.loader = loader
            self.user = user
            self.dynamicTypeSize = dynamicTypeSize
        }

        var body: some View {
            let detailLoader = SearchHubPreviewDetailLoader()
            SearchHubView(
                loader: loader,
                detailDependencies: EntityDetailDependencies(
                    detailLoader: detailLoader,
                    mutator: nil,
                    collectionItemsLoader: nil,
                    readerService: nil,
                    videoPlaybackService: nil,
                    onEntityMutated: {}
                ),
                searchText: $searchText,
                user: user,
                modes: ModeCatalog.modes(for: user),
                allowsNsfwContent: false,
                debounce: .milliseconds(10),
                onSelectMode: { _ in },
                onSelectDestination: { _, _ in },
                onSetAllowsNsfwContent: { _ in },
                onSignOut: {}
            )
            .environment(\.dynamicTypeSize, dynamicTypeSize ?? .large)
        }
    }

#endif
#if DEBUG
    #Preview("Search Hub") {
        SearchHubPreview()
    }
#endif
