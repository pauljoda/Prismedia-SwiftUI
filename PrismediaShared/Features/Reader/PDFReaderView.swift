#if os(iOS) || os(macOS)
    import PDFKit
    import SwiftUI

    public struct PDFReaderView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var document: PDFDocument?
        @State private var currentPage = 0
        @State private var layoutMode: PDFReaderLayoutMode
        @State private var fitMode = PDFReaderFitMode.page
        @State private var fitRequestID = 0
        @State private var outlineItems: [PDFReaderOutlineItem] = []
        @State private var presentedSheet: PDFReaderSheet?
        @State private var searchQuery = ""
        @State private var searchMatches: [PDFSelection] = []
        @State private var selectedSearchResult: Int?
        @State private var searchTask: Task<Void, Never>?
        @State private var searchGeneration = 0
        @State private var isSearching = false
        @State private var errorMessage: String?
        @State private var progressWriter: BookReaderProgressWriter

        private let command: BookReaderCommand
        private let useCase: DocumentReaderUseCase

        public init(
            book: EntityDetail,
            command: BookReaderCommand,
            service: any BookReaderServicing
        ) {
            self.command = command
            let readerUseCase = DocumentReaderUseCase(book: book, service: service)
            useCase = readerUseCase
            _layoutMode = State(
                initialValue: command == .resume
                    ? PDFReaderLayoutMode(readerMode: readerUseCase.progress?.mode)
                    : .continuous
            )
            _progressWriter = State(initialValue: BookReaderProgressWriter(service: service))
        }

        public var body: some View {
            NavigationStack {
                content
                    .navigationTitle(useCase.book.title)
                    .prismediaInlineNavigationTitle()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            ReaderCloseButton(accessibilityPrefix: "pdf-reader", action: close)
                        }
                        if let document {
                            ToolbarItemGroup(placement: .primaryAction) {
                                tableOfContentsButton
                                searchButton
                                viewOptionsButton
                            }
                            ReaderPageNavigationToolbar(
                                status: readerProgressStatus(for: document),
                                accessibilityPrefix: "pdf-reader",
                                canGoPrevious: currentPage > 0,
                                canGoNext: currentPage < document.pageCount - 1,
                                onPrevious: showPreviousPage,
                                onNext: showNextPage
                            )
                        }
                    }
            }
            .sheet(item: $presentedSheet) { sheet in
                readerSheet(sheet)
            }
            .task { await load() }
            .onChange(of: currentPage) { _, _ in saveProgress() }
            .onChange(of: layoutMode) { _, _ in saveProgress() }
            .onChange(of: searchQuery) { _, query in
                guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                searchMatches = []
                selectedSearchResult = nil
            }
            .onDisappear {
                searchTask?.cancel()
                saveProgress()
                Task { await progressWriter.flush() }
            }
            .accessibilityIdentifier("pdf-reader.content")
        }

        @ViewBuilder
        private var content: some View {
            if let document {
                PDFKitDocumentView(
                    document: document,
                    pageIndex: currentPage,
                    layoutMode: layoutMode,
                    fitMode: fitMode,
                    fitRequestID: fitRequestID,
                    highlightedSelection: selectedSelection,
                    isSwipeDownEnabled: canSwipeDownToDismiss,
                    onPageChanged: { currentPage = $0 },
                    onSwipeDown: close
                )
                .accessibilityLabel("PDF reader")
                .accessibilityValue("Page \(currentPage + 1) of \(document.pageCount)")
                .accessibilityIdentifier("pdf-reader.page")
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t Open PDF", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") { Task { await load() } }
                }
            } else {
                PrismediaLoadingView("Opening PDF…")
            }
        }

        private func load() async {
            document = nil
            outlineItems = []
            clearSearch()
            errorMessage = nil
            do {
                let data = try await useCase.loadSourceData()
                guard !Task.isCancelled else { return }
                let loaded = try PDFDocumentLoader().load(data: data)
                let locations = (0..<loaded.pageCount).map(String.init)
                currentPage =
                    command == .resume
                    ? DocumentReaderProgressMapper.initialIndex(progress: useCase.progress, locations: locations)
                    : 0
                outlineItems = PDFOutlineBuilder().items(in: loaded)
                document = loaded
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private func saveProgress() {
            guard let document else { return }
            let request = DocumentReaderProgressMapper.request(
                bookID: useCase.book.id,
                index: currentPage,
                total: document.pageCount,
                unit: .page,
                mode: layoutMode.readerMode,
                location: nil
            )
            progressWriter.queue(bookID: useCase.book.id, request: request)
        }

        private var tableOfContentsButton: some View {
            Button("Table of Contents", systemImage: "list.bullet.indent") {
                presentedSheet = .contents
            }
            .accessibilityIdentifier("pdf-reader.table-of-contents")
        }

        private var searchButton: some View {
            Button("Search", systemImage: "magnifyingglass") {
                presentedSheet = .search
            }
            .accessibilityIdentifier("pdf-reader.search")
        }

        private var viewOptionsButton: some View {
            Button("View Options", systemImage: "textformat.size") {
                presentedSheet = .viewOptions
            }
            .accessibilityLabel("PDF view options")
            .accessibilityValue(layoutMode.label)
        }

        @ViewBuilder
        private func readerSheet(_ sheet: PDFReaderSheet) -> some View {
            switch sheet {
            case .contents:
                PDFTableOfContentsView(
                    items: outlineItems,
                    currentPage: currentPage,
                    onSelect: selectPage
                )
            case .search:
                PDFReaderSearchPanel(
                    query: $searchQuery,
                    selectedResult: selectedSearchResult,
                    resultCount: searchMatches.count,
                    isSearching: isSearching,
                    onSearch: performSearch,
                    onPrevious: showPreviousSearchResult,
                    onNext: showNextSearchResult
                )
            case .viewOptions:
                PDFReaderViewOptionsSheet(
                    layoutMode: $layoutMode,
                    fitMode: fitMode,
                    onSelectFitMode: requestFit
                )
            }
        }

        private var selectedSelection: PDFSelection? {
            guard let selectedSearchResult,
                searchMatches.indices.contains(selectedSearchResult)
            else { return nil }
            return searchMatches[selectedSearchResult]
        }

        private var canSwipeDownToDismiss: Bool {
            #if os(iOS)
                return layoutMode == .paged
                    && presentedSheet == nil
            #else
                return false
            #endif
        }

        private func readerProgressStatus(for document: PDFDocument) -> ReaderProgressStatus {
            ReaderProgressStatus(
                title: useCase.book.title,
                counterText: "\(currentPage + 1) / \(document.pageCount)",
                accessibilityLabel:
                    "\(useCase.book.title), page \(currentPage + 1) of \(document.pageCount)"
            )
        }

        private func showPreviousPage() {
            currentPage = max(0, currentPage - 1)
        }

        private func showNextPage() {
            guard let document else { return }
            currentPage = min(document.pageCount - 1, currentPage + 1)
        }

        private func selectPage(_ pageIndex: Int) {
            guard let document else { return }
            currentPage = max(0, min(pageIndex, document.pageCount - 1))
        }

        private func requestFit(_ mode: PDFReaderFitMode) {
            fitMode = mode
            fitRequestID &+= 1
        }

        private func performSearch() {
            guard let document else { return }
            searchTask?.cancel()
            searchGeneration &+= 1
            let generation = searchGeneration
            let query = searchQuery
            isSearching = true
            searchTask = Task {
                let matches = await PDFTextSearchService().matches(in: document, query: query)
                guard !Task.isCancelled, generation == searchGeneration, query == searchQuery else { return }
                searchMatches = matches
                selectedSearchResult = searchMatches.isEmpty ? nil : 0
                showSelectedSearchResult()
                isSearching = false
                searchTask = nil
            }
        }

        private func showPreviousSearchResult() {
            selectedSearchResult = PDFSearchResultNavigation.previousIndex(
                current: selectedSearchResult,
                count: searchMatches.count
            )
            showSelectedSearchResult()
        }

        private func showNextSearchResult() {
            selectedSearchResult = PDFSearchResultNavigation.nextIndex(
                current: selectedSearchResult,
                count: searchMatches.count
            )
            showSelectedSearchResult()
        }

        private func showSelectedSearchResult() {
            guard let document,
                let selection = selectedSelection,
                let page = selection.pages.first
            else { return }
            currentPage = document.index(for: page)
        }

        private func clearSearch() {
            searchTask?.cancel()
            searchTask = nil
            searchGeneration &+= 1
            isSearching = false
            searchQuery = ""
            searchMatches = []
            selectedSearchResult = nil
        }

        private func close() {
            Task {
                saveProgress()
                await progressWriter.flush()
                dismiss()
            }
        }
    }

    #if DEBUG
        #Preview("PDF Reader · Invalid Fixture") {
            let book = EntityDetail(
                id: ComicReaderPreviewData.bookID,
                kind: .book,
                title: "Signal in the Static",
                parentEntityID: nil,
                sortOrder: nil,
                bookType: "book",
                bookFormat: .pdf,
                hasSourceMedia: true,
                capabilities: [],
                childrenByKind: [],
                relationships: []
            )
            PDFReaderView(book: book, command: .read, service: ComicReaderPreviewData.service)
        }
    #endif
#endif
