#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct ReadiumEPUBReaderToolbar: ToolbarContent {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Binding var preferences: EPUBReaderPreferences
        @Binding var navigationMenuPresented: Bool
        @Binding var settingsPresented: Bool
        @Binding var audiobookControlsPresented: Bool

        let hasToggleBookmark: Bool
        let isReturningFromToggleBookmark: Bool
        let onClose: () -> Void
        let onOpenContents: () -> Void
        let onOpenSearch: () -> Void
        let onOpenBookmarks: () -> Void
        let onNavigationMenuDismissed: () -> Void
        let onToggleBookmark: () -> Void
        let onOpenSettings: () -> Void
        let companionTrackTitle: String?
        let companionIsPlaying: Bool
        let companionPlaybackRate: Float
        let onToggleCompanionPlayback: () -> Void
        let onSetCompanionPlaybackRate: (Float) -> Void

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

            if let companionTrackTitle {
                ToolbarItem(placement: .topBarTrailing) {
                    ReaderAudiobookControlMenu(
                        isPresented: $audiobookControlsPresented,
                        trackTitle: companionTrackTitle,
                        isPlaying: companionIsPlaying,
                        playbackRate: companionPlaybackRate,
                        onTogglePlayback: onToggleCompanionPlayback,
                        onSetPlaybackRate: onSetCompanionPlaybackRate
                    )
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Reader settings", systemImage: "textformat.size", action: onOpenSettings)
                    .accessibilityIdentifier("epub-reader.settings-button")
                    .popover(isPresented: $settingsPresented, arrowEdge: .top) {
                        EPUBReaderSettingsPanel(preferences: $preferences)
                            .frame(minWidth: 320, idealWidth: 380, minHeight: 460)
                            .presentationCompactAdaptation(.popover)
                    }
            }
        }

        private var compactNavigationMenu: some View {
            Button("Navigate Book", systemImage: "text.book.closed") {
                navigationMenuPresented = true
            }
            .accessibilityIdentifier("epub-reader.navigation-menu")
            .popover(isPresented: $navigationMenuPresented, arrowEdge: .top) {
                EPUBReaderNavigationPanel(
                    onOpenContents: onOpenContents,
                    onOpenSearch: onOpenSearch,
                    onOpenBookmarks: onOpenBookmarks
                )
                .frame(minWidth: 280, idealWidth: 320, minHeight: 260)
                .presentationCompactAdaptation(.popover)
                .onDisappear(perform: onNavigationMenuDismissed)
            }
        }

        private var contentsButton: some View {
            Button("Table of Contents", systemImage: "list.bullet.indent", action: onOpenContents)
                .accessibilityIdentifier("epub-reader.table-of-contents")
        }

        private var searchButton: some View {
            Button("Search book", systemImage: "magnifyingglass", action: onOpenSearch)
                .accessibilityIdentifier("epub-reader.search-button")
        }

        private var bookmarksButton: some View {
            Button("Bookmarks", systemImage: "bookmark", action: onOpenBookmarks)
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
            .accessibilityIdentifier("epub-reader.toggle-bookmark")
        }
    }

    #if DEBUG
        #Preview("Readium EPUB Reader Toolbar") {
            @Previewable @State var preferences = EPUBReaderPreferences()
            @Previewable @State var navigationMenuPresented = false
            @Previewable @State var settingsPresented = false
            @Previewable @State var audiobookControlsPresented = false

            NavigationStack {
                Color.black
                    .ignoresSafeArea()
                    .toolbar {
                        ReadiumEPUBReaderToolbar(
                            preferences: $preferences,
                            navigationMenuPresented: $navigationMenuPresented,
                            settingsPresented: $settingsPresented,
                            audiobookControlsPresented: $audiobookControlsPresented,
                            hasToggleBookmark: true,
                            isReturningFromToggleBookmark: false,
                            onClose: {},
                            onOpenContents: {},
                            onOpenSearch: {},
                            onOpenBookmarks: {},
                            onNavigationMenuDismissed: {},
                            onToggleBookmark: {},
                            onOpenSettings: { settingsPresented = true },
                            companionTrackTitle: "Chapter 7",
                            companionIsPlaying: true,
                            companionPlaybackRate: 1.25,
                            onToggleCompanionPlayback: {},
                            onSetCompanionPlaybackRate: { _ in }
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
