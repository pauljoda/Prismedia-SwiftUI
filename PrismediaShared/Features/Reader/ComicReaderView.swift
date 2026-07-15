#if os(iOS) || os(macOS)
    import SwiftUI

    public struct ComicReaderView: View {
        @Environment(\.dismiss) private var dismiss

        @State private var screenState: BookReaderScreenState = .loading
        @State private var currentIndex = 0
        @State private var readerMode: ReaderMode = .paged
        @State private var pageOptions = ComicReaderOptions()
        @State private var chrome = ReaderChromeState()
        @State private var presentedSheet: ComicReaderSheet?
        @State private var isAdvancingChapter = false
        @State private var webtoonNavigationRequestID = 0
        @State private var chromeTask: Task<Void, Never>?
        @State private var pageCache: BookReaderPageCache
        @State private var progressWriter: BookReaderProgressWriter

        private let useCase: BookReaderUseCase
        private let onDismiss: () -> Void

        public init(
            selected: EntityDetail,
            command: BookReaderCommand,
            service: any BookReaderServicing,
            onDismiss: @escaping () -> Void = {}
        ) {
            useCase = BookReaderUseCase(selected: selected, command: command, service: service)
            _pageCache = State(initialValue: BookReaderPageCache(service: service))
            _progressWriter = State(initialValue: BookReaderProgressWriter(service: service))
            self.onDismiss = onDismiss
        }

        public var body: some View {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    content
                        .ignoresSafeArea()
                }
                .foregroundStyle(PrismediaColor.onMedia)
                .toolbar {
                    ComicReaderToolbar(
                        onClose: close,
                        onOpenSettings: openSettings
                    )
                    ReaderPageNavigationToolbar(
                        status: readerProgressStatus,
                        accessibilityPrefix: "comic-reader",
                        canGoPrevious: canGoPrevious,
                        canGoNext: canGoNext,
                        onOpenContents: openContents,
                        onPrevious: goPrevious,
                        onNext: goNext
                    )
                }
                #if os(iOS)
                    .toolbarVisibility(
                        chrome.isVisible ? .visible : .hidden,
                        for: .navigationBar, .bottomBar
                    )
                #else
                    .toolbarVisibility(chrome.isVisible ? .visible : .hidden)
                #endif
            }
            .sheet(item: $presentedSheet) { sheet in
                readerSheet(sheet)
            }
            .accessibilityIdentifier("comic-reader.content")
            .task {
                await load()
                scheduleChromeHide()
            }
            .onChange(of: chrome.isVisible) {
                scheduleChromeHide()
            }
            .onChange(of: currentIndex) {
                scheduleChromeHide()
            }
            .onChange(of: presentedSheet) {
                updateChromePin()
            }
            .onDisappear {
                chromeTask?.cancel()
                Task { await progressWriter.flush() }
            }
        }

        @ViewBuilder
        private var content: some View {
            switch screenState {
            case .loading:
                PrismediaLoadingView("Opening reader…")
            case .failure(let message):
                ContentUnavailableView {
                    Label("Couldn’t Open Reader", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Close", action: close)
                }
            case .content(let manifest):
                if readerMode == .webtoon {
                    ComicWebtoonReader(
                        manifest: manifest,
                        currentIndex: currentIndex,
                        navigationRequestID: webtoonNavigationRequestID,
                        counterText: counterText,
                        pageCache: pageCache,
                        isAdvancingChapter: isAdvancingChapter,
                        onMove: move,
                        onToggleControls: contentTapped,
                        onEndAction: { handleEndAction(for: manifest) }
                    )
                } else {
                    ComicPagedReader(
                        manifest: manifest,
                        currentIndex: currentIndex,
                        options: pageOptions,
                        showingEndPage: showingEndPage,
                        counterText: counterText,
                        pageCache: pageCache,
                        isAdvancingChapter: isAdvancingChapter,
                        onGesture: handleGesture,
                        onTap: handleTap,
                        onEndAction: { handleEndAction(for: manifest) }
                    )
                }
            }
        }

        private var manifest: BookReaderManifest? {
            guard case .content(let manifest) = screenState else { return nil }
            return manifest
        }

        private var showingEndPage: Bool {
            guard let manifest else { return false }
            return readerMode == .paged && currentIndex == manifest.pages.count
        }

        private var currentPosition: BookReaderPosition? {
            manifest?.position(at: currentIndex)
        }

        private var currentChapterID: UUID? {
            currentPosition?.chapterID
        }

        private var currentChapterTitle: String {
            guard let manifest,
                let chapterID = currentPosition?.chapterID,
                let chapter = manifest.chapters.first(where: { $0.id == chapterID })
            else { return manifest?.title ?? "Reader" }
            return chapter.title
        }

        private var counterText: String {
            guard let manifest else { return "" }

            let spread = ComicReaderNavigation.spread(
                index: currentIndex,
                total: manifest.pages.count,
                options: readerMode == .webtoon ? ComicReaderOptions() : pageOptions
            )
            let positions = spread.compactMap(manifest.position(at:))
            guard let first = positions.first else { return "" }
            if positions.count == 2,
                let last = positions.last,
                last.chapterID == first.chapterID
            {
                return "\(first.pageIndex + 1)–\(last.pageIndex + 1) / \(first.pageCount)"
            }
            return "\(first.pageIndex + 1) / \(first.pageCount)"
        }

        private var readerProgressStatus: ReaderProgressStatus {
            let counter = counterText.isEmpty ? "– / –" : counterText
            return ReaderProgressStatus(
                title: currentChapterTitle,
                counterText: counter,
                accessibilityLabel: "\(currentChapterTitle), \(counter)"
            )
        }

        private var canGoPrevious: Bool {
            manifest != nil && (showingEndPage || currentIndex > 0)
        }

        private var canGoNext: Bool {
            guard let manifest else { return false }
            if readerMode == .webtoon {
                return currentIndex < manifest.pages.count - 1
            }
            return !showingEndPage && !manifest.pages.isEmpty
        }

        private func load() async {
            screenState = .loading
            do {
                install(try await useCase.loadManifest(), preservingMode: nil)
            } catch is CancellationError {
                return
            } catch {
                screenState = .failure(error.localizedDescription)
            }
        }

        private func install(_ manifest: BookReaderManifest, preservingMode: ReaderMode?) {
            screenState = .content(manifest)
            currentIndex = manifest.initialIndex
            readerMode = preservingMode ?? manifest.readerMode
            revealChrome()
        }

        private func goNext() {
            guard let manifest else { return }
            if readerMode == .webtoon {
                let nextIndex = min(currentIndex + 1, manifest.pages.count - 1)
                guard nextIndex != currentIndex else { return }
                move(to: nextIndex)
                webtoonNavigationRequestID &+= 1
                return
            }
            if showingEndPage {
                Task { await performEndAction() }
                return
            }

            let visiblePages = ComicReaderNavigation.spread(
                index: currentIndex,
                total: manifest.pages.count,
                options: pageOptions
            )
            if visiblePages.last == manifest.pages.count - 1 {
                currentIndex = manifest.pages.count
                return
            }

            move(
                to: ComicReaderNavigation.nextIndex(
                    from: currentIndex,
                    total: manifest.pages.count,
                    options: pageOptions
                ))
        }

        private func goPrevious() {
            guard let manifest else { return }
            if readerMode == .webtoon {
                let previousIndex = max(0, currentIndex - 1)
                guard previousIndex != currentIndex else { return }
                move(to: previousIndex)
                webtoonNavigationRequestID &+= 1
                return
            }
            if showingEndPage {
                currentIndex = max(0, manifest.pages.count - 1)
                return
            }

            move(
                to: ComicReaderNavigation.previousIndex(
                    from: currentIndex,
                    total: manifest.pages.count,
                    options: pageOptions
                ))
        }

        private func move(to index: Int) {
            guard let manifest, !manifest.pages.isEmpty else { return }
            let nextIndex = max(0, min(index, manifest.pages.count - 1))
            guard nextIndex != currentIndex else { return }
            currentIndex = nextIndex
            queueProgressSave()
        }

        private func setReaderMode(_ mode: ReaderMode) {
            guard mode != readerMode else { return }
            readerMode = mode
            if mode == .webtoon, let manifest, currentIndex >= manifest.pages.count {
                currentIndex = max(0, manifest.pages.count - 1)
            }
            queueProgressSave()
        }

        private func handleTap(x: CGFloat, width: CGFloat) {
            switch ComicReaderNavigation.tapZone(x: x, width: width) {
            case .previous: goPrevious()
            case .controls: contentTapped()
            case .next: goNext()
            }
        }

        private func handleGesture(_ gesture: ComicReaderGesture) {
            switch gesture {
            case .previous: goPrevious()
            case .next: goNext()
            case .dismiss: close()
            case .none: break
            }
        }

        private func queueProgressSave(
            completed: Bool? = nil,
            reset: Bool = false,
            allowAutomaticCompletion: Bool = true
        ) {
            guard let manifest,
                let request = useCase.progressRequest(
                    in: manifest,
                    index: currentIndex,
                    mode: readerMode,
                    completed: completed,
                    reset: reset,
                    allowAutomaticCompletion: allowAutomaticCompletion
                )
            else { return }

            progressWriter.queue(bookID: manifest.bookID, request: request)
        }

        private func handleEndAction(for manifest: BookReaderManifest) {
            if manifest.nextChapter == nil {
                close()
                return
            }
            Task { await performEndAction() }
        }

        private func performEndAction() async {
            guard let manifest else { return }
            guard let nextChapter = manifest.nextChapter else {
                queueProgressSave(completed: true)
                await progressWriter.flush()
                return
            }
            guard !isAdvancingChapter else { return }

            isAdvancingChapter = true
            defer { isAdvancingChapter = false }
            queueProgressSave(allowAutomaticCompletion: false)
            await progressWriter.flush()

            do {
                let nextManifest = try await useCase.loadFollowingManifest(chapterID: nextChapter.id)
                install(nextManifest, preservingMode: readerMode)
            } catch is CancellationError {
                return
            } catch {
                screenState = .failure(error.localizedDescription)
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
            chrome.setPinned(presentedSheet != nil)
            scheduleChromeHide()
        }

        private func scheduleChromeHide() {
            chromeTask?.cancel()
            guard chrome.shouldScheduleHide, manifest != nil else { return }
            chromeTask = Task { @MainActor in
                try? await Task.sleep(for: ReaderChromeState.autoHideDelay)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.2)) { chrome.hide() }
                chromeTask = nil
            }
        }

        private func openSettings() {
            revealChrome()
            presentedSheet = .settings
        }

        private func openContents() {
            revealChrome()
            presentedSheet = .contents
        }

        @ViewBuilder
        private func readerSheet(_ sheet: ComicReaderSheet) -> some View {
            switch sheet {
            case .contents:
                ComicReaderTableOfContentsSheet(
                    chapters: manifest?.tableOfContents ?? [],
                    currentChapterID: currentChapterID,
                    onSelect: selectChapter
                )
            case .settings:
                ComicReaderSettingsSheet(
                    readerMode: readerMode,
                    pageOptions: $pageOptions,
                    onSetMode: setReaderMode
                )
            }
        }

        private func selectChapter(_ chapterID: UUID) {
            guard chapterID != currentChapterID else { return }
            Task { await loadChapter(chapterID) }
        }

        private func loadChapter(_ chapterID: UUID) async {
            guard !isAdvancingChapter else { return }
            isAdvancingChapter = true
            defer { isAdvancingChapter = false }

            queueProgressSave(allowAutomaticCompletion: false)
            await progressWriter.flush()

            do {
                let selectedManifest = try await useCase.loadChapterManifest(
                    chapterID: chapterID,
                    command: .read
                )
                install(selectedManifest, preservingMode: readerMode)
            } catch is CancellationError {
                return
            } catch {
                screenState = .failure(error.localizedDescription)
            }
        }

        private func close() {
            Task {
                queueProgressSave()
                await progressWriter.flush()
                onDismiss()
                dismiss()
            }
        }
    }

    #if DEBUG

        #Preview("Comic Reader · Paged") {
            ComicReaderView(
                selected: ComicReaderPreviewData.book,
                command: .read,
                service: ComicReaderPreviewData.service
            )
        }
    #endif
#endif
