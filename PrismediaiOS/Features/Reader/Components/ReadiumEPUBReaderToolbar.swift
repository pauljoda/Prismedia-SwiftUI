#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct ReadiumEPUBReaderToolbar: ToolbarContent {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        let hasToggleBookmark: Bool
        let isReturningFromToggleBookmark: Bool
        let onClose: () -> Void
        let onOpenContents: () -> Void
        let onOpenSearch: () -> Void
        let onOpenBookmarks: () -> Void
        let onOpenNavigation: () -> Void
        let onToggleBookmark: () -> Void
        let onOpenSettings: () -> Void
        let showsAudiobookControls: Bool
        let companionIsPlaying: Bool
        let onOpenAudiobook: () -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            ToolbarItem(placement: .cancellationAction) {
                ReaderCloseButton(accessibilityPrefix: "epub-reader", action: onClose)
            }

            if horizontalSizeClass == .compact {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    compactNavigationMenu
                    if hasToggleBookmark {
                        toggleBookmarkButton
                    }
                }
            } else {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    contentsButton
                    searchButton
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItemGroup(placement: .topBarTrailing) {
                    bookmarksButton
                    if hasToggleBookmark {
                        toggleBookmarkButton
                    }
                }
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            if showsAudiobookControls {
                ToolbarItem(placement: .topBarTrailing) {
                    ReaderAudiobookButton(
                        isPlaying: companionIsPlaying,
                        action: onOpenAudiobook
                    )
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Reader settings", systemImage: "textformat.size", action: onOpenSettings)
                    .prismediaToolbarActionLabelStyle()
                    .accessibilityIdentifier("epub-reader.settings-button")
            }
        }

        private var compactNavigationMenu: some View {
            Button("Navigate Book", systemImage: "text.book.closed", action: onOpenNavigation)
                .prismediaToolbarActionLabelStyle()
                .accessibilityIdentifier("epub-reader.navigation-menu")
        }

        private var contentsButton: some View {
            Button("Table of Contents", systemImage: "list.bullet.indent", action: onOpenContents)
                .prismediaToolbarActionLabelStyle()
                .accessibilityIdentifier("epub-reader.table-of-contents")
        }

        private var searchButton: some View {
            Button("Search book", systemImage: "magnifyingglass", action: onOpenSearch)
                .prismediaToolbarActionLabelStyle()
                .accessibilityIdentifier("epub-reader.search-button")
        }

        private var bookmarksButton: some View {
            Button("Bookmarks", systemImage: "bookmark", action: onOpenBookmarks)
                .prismediaToolbarActionLabelStyle()
                .accessibilityIdentifier("epub-reader.bookmarks-button")
        }

        private var toggleBookmarkButton: some View {
            Button(
                isReturningFromToggleBookmark
                    ? "Return from Toggle bookmark"
                    : "Jump to Toggle bookmark",
                systemImage: "arrow.left.arrow.right",
                action: onToggleBookmark
            )
            .prismediaToolbarActionLabelStyle()
            .accessibilityIdentifier("epub-reader.toggle-bookmark")
        }
    }

    #if DEBUG
        #Preview("Readium EPUB Reader Toolbar") {
            NavigationStack {
                Color.black
                    .ignoresSafeArea()
                    .toolbar {
                        ReadiumEPUBReaderToolbar(
                            hasToggleBookmark: true,
                            isReturningFromToggleBookmark: false,
                            onClose: {},
                            onOpenContents: {},
                            onOpenSearch: {},
                            onOpenBookmarks: {},
                            onOpenNavigation: {},
                            onToggleBookmark: {},
                            onOpenSettings: {},
                            showsAudiobookControls: true,
                            companionIsPlaying: true,
                            onOpenAudiobook: {}
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
