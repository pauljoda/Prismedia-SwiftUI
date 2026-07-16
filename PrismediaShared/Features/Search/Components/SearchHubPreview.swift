import SwiftUI

#if DEBUG
    struct SearchHubPreview: View {
        @State private var searchText: String
        @State private var filters: SearchHubFilterState

        let loader: SearchHubPreviewLoader
        let user: UserAccount
        let dynamicTypeSize: DynamicTypeSize?

        init(
            searchText: String = "",
            filters: SearchHubFilterState = SearchHubFilterState(),
            loader: SearchHubPreviewLoader = SearchHubPreviewLoader(),
            user: UserAccount = PrismediaPreviewData.user,
            dynamicTypeSize: DynamicTypeSize? = nil
        ) {
            _searchText = State(initialValue: searchText)
            _filters = State(initialValue: filters)
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
                filters: $filters,
                modes: ModeCatalog.modes(for: user),
                debounce: .milliseconds(10),
                onSelectMode: { _ in },
                onSelectDestination: { _, _ in }
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
