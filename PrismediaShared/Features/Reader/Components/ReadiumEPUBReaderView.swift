#if os(iOS) && canImport(ReadiumNavigator)
    import SwiftUI

    struct ReadiumEPUBReaderView: View {
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.dismiss) private var dismiss
        @State private var session: ReadiumEPUBReaderSession
        @State private var preferences: EPUBReaderPreferences
        @State private var presentedInspector = EPUBReaderInspector.contents
        @State private var inspectorPresented = false
        @State private var searchPresented = false
        @State private var settingsPresented = false
        @State private var isLoading = true
        @State private var errorMessage: String?
        @State private var tableOfContents: [EPUBTableOfContentsItem] = []
        @State private var searchResults: [EPUBSearchResult] = []
        @State private var isSearching = false
        @State private var chapterProgress: EPUBChapterProgress?
        @State private var canGoPrevious = false
        @State private var canGoNext = false
        @State private var bookmarksState = EPUBBookmarksState()
        @State private var isToggleReturnAvailable = false
        @State private var navigationMenuPresented = false
        @State private var audiobookControlsPresented = false
        @State private var pendingNavigationAction: EPUBReaderNavigationAction?
        @State private var isClosing = false
        @State private var hasSignaledReady = false
        @State private var chrome = ReaderChromeState()
        @State private var chromeTask: Task<Void, Never>?

        private let bookID: UUID
        private let bookmarkStore: any EPUBBookmarkStoring
        private let companionPlayer: MusicPlayerController?
        private let onReady: () -> Void

        init(
            book: EntityDetail,
            command: BookReaderCommand,
            service: any BookReaderServicing,
            preferencesStore: ReaderPreferencesStore = .standard,
            locatorStore: EPUBLocatorStore = .standard,
            bookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.disabled,
            initialLocation: String? = nil,
            initialProgression: Double? = nil,
            companionPlayer: MusicPlayerController? = nil,
            onReady: @escaping () -> Void = {}
        ) {
            let session = ReadiumEPUBReaderSession(
                book: book,
                command: command,
                service: service,
                preferencesStore: preferencesStore,
                locatorStore: locatorStore,
                initialLocation: initialLocation,
                initialProgression: initialProgression
            )
            _session = State(initialValue: session)
            _preferences = State(initialValue: session.preferences)
            bookID = book.id
            self.bookmarkStore = bookmarkStore
            self.companionPlayer = companionPlayer
            self.onReady = onReady
        }

        var body: some View {
            NavigationStack {
                ZStack {
                    readerBackground.ignoresSafeArea()
                    readerContent
                        .ignoresSafeArea()
                }
                .toolbar {
                    ReadiumEPUBReaderToolbar(
                        preferences: $preferences,
                        navigationMenuPresented: $navigationMenuPresented,
                        settingsPresented: $settingsPresented,
                        audiobookControlsPresented: $audiobookControlsPresented,
                        hasToggleBookmark: toggleBookmark != nil,
                        isReturningFromToggleBookmark: isToggleReturnAvailable,
                        onClose: close,
                        onOpenContents: openContents,
                        onOpenSearch: openSearch,
                        onOpenBookmarks: openBookmarks,
                        onNavigationMenuDismissed: completeNavigationMenuAction,
                        onToggleBookmark: toggleQuickBookmark,
                        onOpenSettings: openSettings,
                        companionTrackTitle: activeCompanionPlayer?.currentTrack?.title,
                        companionIsPlaying: activeCompanionPlayer?.isPlaying ?? false,
                        companionPlaybackRate: activeCompanionPlayer?.playbackRate ?? 1,
                        onToggleCompanionPlayback: toggleCompanionPlayback,
                        onSetCompanionPlaybackRate: setCompanionPlaybackRate
                    )
                    ReaderPageNavigationToolbar(
                        status: readerProgressStatus,
                        accessibilityPrefix: "epub-reader",
                        canGoPrevious: canGoPrevious,
                        canGoNext: canGoNext,
                        onPrevious: previousPage,
                        onNext: nextPage
                    )
                }
                .toolbarVisibility(
                    chrome.isVisible ? .visible : .hidden,
                    for: .navigationBar, .bottomBar
                )
            }
            .inspector(isPresented: $inspectorPresented) {
                readerInspector(presentedInspector)
                    .inspectorColumnWidth(min: 280, ideal: 340, max: 460)
            }
            .sheet(isPresented: $searchPresented) {
                EPUBSearchPanel(
                    results: $searchResults,
                    isSearching: $isSearching,
                    onSearch: { query in await session.search(query) },
                    onSelect: { result in await session.openSearchResult(result) }
                )
            }
            .task {
                bookmarksState = bookmarkStore.load(bookID: bookID)
                session.onChapterProgressChange = { chapterProgress = $0 }
                session.onPageNavigationAvailabilityChange = {
                    canGoPrevious = $0
                    canGoNext = $1
                }
                session.onToggleReturnAvailabilityChange = { isToggleReturnAvailable = $0 }
                session.onError = { errorMessage = $0 }
                session.onContentTap = { contentTapped() }
                await load()
                scheduleChromeHide()
            }
            .onChange(of: preferences) { _, value in
                session.apply(value, useDarkSystemTheme: colorScheme == .dark)
            }
            .onChange(of: colorScheme) {
                guard preferences.theme == .system else { return }
                session.apply(preferences, useDarkSystemTheme: colorScheme == .dark)
            }
            .onChange(of: chrome.isVisible) {
                scheduleChromeHide()
            }
            .onChange(of: inspectorPresented) {
                updateChromePin()
            }
            .onChange(of: searchPresented) {
                updateChromePin()
            }
            .onChange(of: settingsPresented) {
                updateChromePin()
            }
            .onChange(of: navigationMenuPresented) {
                updateChromePin()
            }
            .onChange(of: audiobookControlsPresented) {
                updateChromePin()
            }
            .onChange(of: bookmarksState) { _, value in
                bookmarkStore.save(value, bookID: bookID)
            }
            .onChange(of: bookmarksState.toggleBookmarkID) {
                session.resetToggleBookmarkNavigation()
                isToggleReturnAvailable = false
            }
            .onDisappear {
                chromeTask?.cancel()
                guard !isClosing else { return }
                Task { await session.flush(closing: true) }
            }
            .accessibilityIdentifier("epub-reader.content")
        }

        @ViewBuilder
        private var readerContent: some View {
            ZStack {
                ReadiumEPUBNavigatorView(
                    host: session.host,
                    isSwipeDownEnabled: canSwipeDownToDismiss,
                    onSwipeDown: close
                )
                .ignoresSafeArea()
                .accessibilityIdentifier("epub-reader.page")

                if isLoading {
                    PrismediaLoadingView("Opening EPUB…")
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn’t Open EPUB", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button("Try Again") {
                            Task { await load() }
                        }
                    }
                }
            }
        }

        private var readerBackground: Color {
            switch preferences.theme {
            case .system: colorScheme == .dark ? .black : .white
            case .light: .white
            case .sepia: Color(red: 250 / 255, green: 244 / 255, blue: 232 / 255)
            case .dark: .black
            }
        }

        private var toggleBookmark: EPUBBookmark? {
            guard let toggleBookmarkID = bookmarksState.toggleBookmarkID else { return nil }
            return bookmarksState.bookmarks.first { $0.id == toggleBookmarkID }
        }

        private var readerProgressStatus: ReaderProgressStatus {
            guard let chapterProgress else {
                return ReaderProgressStatus(
                    title: "Opening chapter…",
                    counterText: "– / –",
                    accessibilityLabel: "Reading location unavailable"
                )
            }
            return ReaderProgressStatus(
                title: chapterProgress.chapterTitle,
                counterText: chapterProgress.counterText,
                accessibilityLabel:
                    "\(chapterProgress.chapterTitle), page \(chapterProgress.pageNumber) of \(chapterProgress.pageCount)"
            )
        }

        private var canSwipeDownToDismiss: Bool {
            preferences.flow == .paged
                && !inspectorPresented
                && !searchPresented
                && !settingsPresented
                && !navigationMenuPresented
                && !audiobookControlsPresented
                && !isLoading
                && errorMessage == nil
        }

        private func close() {
            guard !isClosing else { return }
            isClosing = true
            Task {
                await session.flush(closing: true)
                dismiss()
            }
        }

        private func load() async {
            isLoading = true
            errorMessage = nil
            do {
                let contents = try await session.load(useDarkSystemTheme: colorScheme == .dark)
                guard !Task.isCancelled else { return }
                tableOfContents = contents
                isLoading = false
                await signalReady()
            } catch is CancellationError {
                return
            } catch {
                isLoading = false
                errorMessage = "This EPUB could not be opened. It may be damaged or protected."
            }
        }

        private func openContents() {
            guard !deferNavigationMenuAction(.contents) else { return }
            endNavigationMenuInteraction()
            revealChrome()
            presentedInspector = .contents
            inspectorPresented = true
        }

        private func openSearch() {
            guard !deferNavigationMenuAction(.search) else { return }
            endNavigationMenuInteraction()
            revealChrome()
            searchPresented = true
        }

        private func openBookmarks() {
            guard !deferNavigationMenuAction(.bookmarks) else { return }
            endNavigationMenuInteraction()
            revealChrome()
            presentedInspector = .bookmarks
            inspectorPresented = true
        }

        private func openSettings() {
            revealChrome()
            settingsPresented = true
        }

        private func toggleCompanionPlayback() {
            guard let companionPlayer = activeCompanionPlayer else { return }
            if companionPlayer.isPlaying {
                companionPlayer.pause()
            } else {
                companionPlayer.resume()
            }
            revealChrome()
        }

        private func setCompanionPlaybackRate(_ rate: Float) {
            activeCompanionPlayer?.setPlaybackRate(rate)
            revealChrome()
        }

        private var activeCompanionPlayer: MusicPlayerController? {
            guard let companionPlayer,
                companionPlayer.context?.playbackOwnerEntityID == bookID,
                companionPlayer.context?.playbackOwnerEntityKind == .book
            else { return nil }
            return companionPlayer
        }

        private var isReaderPresentationActive: Bool {
            inspectorPresented
                || searchPresented
                || settingsPresented
                || navigationMenuPresented
                || audiobookControlsPresented
        }

        private func signalReady() async {
            guard !hasSignaledReady else { return }
            hasSignaledReady = true
            await Task.yield()
            onReady()
        }

        private func previousPage() {
            revealChrome()
            Task { await session.goBackward() }
        }

        private func nextPage() {
            revealChrome()
            Task { await session.goForward() }
        }

        private func openBookmark(_ bookmark: EPUBBookmark) async -> Bool {
            guard await session.openBookmark(bookmark) else { return false }
            revealChrome()
            return true
        }

        private func toggleQuickBookmark() {
            guard let toggleBookmark else { return }
            revealChrome()
            Task {
                _ = await session.toggleBookmark(toggleBookmark)
            }
        }

        private func contentTapped() {
            withAnimation(.easeOut(duration: 0.2)) {
                chrome.contentTapped()
            }
        }

        private func revealChrome() {
            chromeTask?.cancel()
            chrome.reveal()
            scheduleChromeHide()
        }

        private func updateChromePin() {
            chromeTask?.cancel()
            chrome.setPinned(isReaderPresentationActive)
            scheduleChromeHide()
        }

        private func endNavigationMenuInteraction() {
            navigationMenuPresented = false
        }

        private func deferNavigationMenuAction(_ action: EPUBReaderNavigationAction) -> Bool {
            guard navigationMenuPresented else { return false }
            pendingNavigationAction = action
            navigationMenuPresented = false
            return true
        }

        private func completeNavigationMenuAction() {
            guard let pendingNavigationAction else { return }
            self.pendingNavigationAction = nil
            Task { @MainActor in
                await Task.yield()
                switch pendingNavigationAction {
                case .contents: openContents()
                case .search: openSearch()
                case .bookmarks: openBookmarks()
                }
            }
        }

        @ViewBuilder
        private func readerInspector(_ inspector: EPUBReaderInspector) -> some View {
            switch inspector {
            case .contents:
                EPUBTableOfContentsPanel(
                    items: tableOfContents,
                    onSelect: { item in
                        Task { await session.openTableOfContentsItem(item) }
                    },
                    onClose: { inspectorPresented = false }
                )
            case .bookmarks:
                EPUBBookmarksPanel(
                    state: $bookmarksState,
                    canAddBookmark: chapterProgress != nil,
                    onAdd: { session.currentBookmark() },
                    onOpen: openBookmark,
                    onClose: { inspectorPresented = false }
                )
            }
        }

        private func scheduleChromeHide() {
            chromeTask?.cancel()
            guard chrome.shouldScheduleHide,
                !isReaderPresentationActive,
                !isLoading,
                errorMessage == nil
            else { return }
            chromeTask = Task { @MainActor in
                try? await Task.sleep(for: ReaderChromeState.autoHideDelay)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    chrome.hide()
                }
                chromeTask = nil
            }
        }
    }

    #if DEBUG
        #Preview("Readium EPUB Reader") {
            ReadiumEPUBReaderView(
                book: ComicReaderPreviewData.book,
                command: .read,
                service: ComicReaderPreviewData.service,
                preferencesStore: .disabled,
                locatorStore: .disabled,
                bookmarkStore: EPUBBookmarkStore.disabled
            )
        }
    #endif
#endif
