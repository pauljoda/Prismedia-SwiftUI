#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct ReadiumEPUBReaderSheet: View {
        @Environment(\.dismiss) private var dismiss

        let initialRoute: EPUBReaderSheet
        let tableOfContents: [EPUBTableOfContentsItem]
        @Binding var searchResults: [EPUBSearchResult]
        @Binding var isSearching: Bool
        @Binding var bookmarksState: EPUBBookmarksState
        @Binding var preferences: EPUBReaderPreferences
        let canAddBookmark: Bool
        let onOpenTableOfContentsItem: (EPUBTableOfContentsItem) -> Void
        let onSearch: (String) async -> [EPUBSearchResult]
        let onOpenSearchResult: (EPUBSearchResult) async -> Void
        let onAddBookmark: () -> EPUBBookmark?
        let onOpenBookmark: (EPUBBookmark) async -> Bool

        var body: some View {
            NavigationStack {
                routeContent(initialRoute)
                    .navigationDestination(for: EPUBReaderSheet.self) { route in
                        routeContent(route)
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { dismiss() }
                        }
                    }
            }
            .accessibilityIdentifier("epub-reader.sheet")
        }

        @ViewBuilder
        private func routeContent(_ route: EPUBReaderSheet) -> some View {
            switch route {
            case .navigation:
                EPUBReaderNavigationPanel()
            case .contents:
                EPUBTableOfContentsPanel(
                    items: tableOfContents,
                    onSelect: onOpenTableOfContentsItem
                )
            case .search:
                EPUBSearchPanel(
                    results: $searchResults,
                    isSearching: $isSearching,
                    onSearch: onSearch,
                    onSelect: onOpenSearchResult
                )
            case .bookmarks:
                EPUBBookmarksPanel(
                    state: $bookmarksState,
                    canAddBookmark: canAddBookmark,
                    onAdd: onAddBookmark,
                    onOpen: onOpenBookmark
                )
            case .settings:
                EPUBReaderSettingsPanel(preferences: $preferences)
            case .audiobook:
                ContentUnavailableView("Nothing Playing", systemImage: "headphones")
            }
        }
    }
#endif
