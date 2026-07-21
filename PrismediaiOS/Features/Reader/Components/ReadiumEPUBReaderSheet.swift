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

    #if DEBUG
        #Preview("Readium EPUB Reader Sheet") {
            @Previewable @State var searchResults: [EPUBSearchResult] = []
            @Previewable @State var isSearching = false
            @Previewable @State var bookmarksState = EPUBBookmarksState()
            @Previewable @State var preferences = EPUBReaderPreferences()

            ReadiumEPUBReaderSheet(
                initialRoute: .navigation,
                tableOfContents: [
                    EPUBTableOfContentsItem(
                        title: "Chapter One",
                        location: "Text/chapter-one.xhtml"
                    )
                ],
                searchResults: $searchResults,
                isSearching: $isSearching,
                bookmarksState: $bookmarksState,
                preferences: $preferences,
                canAddBookmark: true,
                onOpenTableOfContentsItem: { _ in },
                onSearch: { _ in [] },
                onOpenSearchResult: { _ in },
                onAddBookmark: { nil },
                onOpenBookmark: { _ in true }
            )
        }
    #endif
#endif
