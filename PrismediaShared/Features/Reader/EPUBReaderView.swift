#if os(iOS) || os(macOS)
    import SwiftUI

    public struct EPUBReaderView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var publication: EPUBPublication?
        @State private var currentChapter = 0
        @State private var currentChapterProgress = 0.0
        @State private var errorMessage: String?
        @State private var progressWriter: BookReaderProgressWriter
        @State private var progressSaveTask: Task<Void, Never>?
        @State private var audiobookControlsPresented = false
        @State private var hasSignaledReady = false

        private let command: BookReaderCommand
        private let service: any BookReaderServicing
        private let useCase: DocumentReaderUseCase
        private let bookmarkStore: any EPUBBookmarkStoring
        private let locatorStore: EPUBLocatorStore
        private let initialLocation: String?
        private let initialProgression: Double?
        private let companionPlayer: MusicPlayerController?
        private let onReady: () -> Void

        public init(
            book: EntityDetail,
            command: BookReaderCommand,
            service: any BookReaderServicing,
            bookmarkStore: any EPUBBookmarkStoring = EPUBBookmarkStore.disabled,
            locatorStore: EPUBLocatorStore = .disabled,
            initialLocation: String? = nil,
            initialProgression: Double? = nil,
            companionPlayer: MusicPlayerController? = nil,
            onReady: @escaping () -> Void = {}
        ) {
            self.command = command
            self.service = service
            self.bookmarkStore = bookmarkStore
            self.locatorStore = locatorStore
            self.initialLocation = initialLocation
            self.initialProgression = initialProgression
            self.companionPlayer = companionPlayer
            self.onReady = onReady
            useCase = DocumentReaderUseCase(book: book, service: service)
            _progressWriter = State(initialValue: BookReaderProgressWriter(service: service))
        }

        @ViewBuilder
        public var body: some View {
            #if os(iOS) && canImport(ReadiumNavigator)
                ReadiumEPUBReaderView(
                    book: useCase.book,
                    command: command,
                    service: service,
                    locatorStore: locatorStore,
                    bookmarkStore: bookmarkStore,
                    initialLocation: initialLocation,
                    initialProgression: initialProgression,
                    companionPlayer: companionPlayer,
                    onReady: onReady
                )
            #else
                NavigationStack {
                    content
                        .navigationTitle(publication?.title ?? useCase.book.title)
                        .prismediaInlineNavigationTitle()
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Close", systemImage: "xmark", action: close)
                            }
                            if let companionPlayer = activeCompanionPlayer,
                                let currentTrack = companionPlayer.currentTrack
                            {
                                ToolbarItem(placement: .primaryAction) {
                                    ReaderAudiobookControlMenu(
                                        isPresented: $audiobookControlsPresented,
                                        trackTitle: currentTrack.title,
                                        isPlaying: companionPlayer.isPlaying,
                                        playbackRate: companionPlayer.playbackRate,
                                        onTogglePlayback: {
                                            if companionPlayer.isPlaying {
                                                companionPlayer.pause()
                                            } else {
                                                companionPlayer.resume()
                                            }
                                        },
                                        onSetPlaybackRate: companionPlayer.setPlaybackRate
                                    )
                                }
                            }
                            if let publication {
                                ToolbarItemGroup(placement: .primaryAction) {
                                    Button("Previous Chapter", systemImage: "chevron.left") {
                                        selectChapter(max(0, currentChapter - 1))
                                    }
                                    .disabled(currentChapter == 0)

                                    chapterMenu(publication)

                                    Button("Next Chapter", systemImage: "chevron.right") {
                                        selectChapter(min(publication.chapters.count - 1, currentChapter + 1))
                                    }
                                    .disabled(currentChapter >= publication.chapters.count - 1)
                                }
                            }
                        }
                }
                .task { await load() }
                .onDisappear {
                    progressSaveTask?.cancel()
                    saveProgress()
                    Task { await progressWriter.flush() }
                }
                .accessibilityIdentifier("epub-reader.content")
            #endif
        }

        @ViewBuilder
        private var content: some View {
            if let publication,
                publication.chapters.indices.contains(currentChapter)
            {
                EPUBWebDocumentView(
                    chapter: publication.chapters[currentChapter],
                    rootURL: publication.rootURL,
                    initialScrollProgress: currentChapterProgress,
                    onLocalNavigation: openLocalURL,
                    onScrollProgress: recordScrollProgress
                )
                .accessibilityLabel("EPUB reader")
                .accessibilityValue("Chapter \(currentChapter + 1) of \(publication.chapters.count)")
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t Open EPUB", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Try Again") { Task { await load() } }
                }
            } else {
                PrismediaLoadingView("Opening EPUB…")
            }
        }

        private func chapterMenu(_ publication: EPUBPublication) -> some View {
            Menu {
                ForEach(Array(publication.chapters.enumerated()), id: \.element.id) { index, _ in
                    Button("Chapter \(index + 1)") { selectChapter(index) }
                }
            } label: {
                Text("\(currentChapter + 1) of \(publication.chapters.count)")
                    .monospacedDigit()
            }
            .accessibilityLabel("Choose chapter")
            .accessibilityValue("Chapter \(currentChapter + 1) of \(publication.chapters.count)")
        }

        private func load() async {
            publication = nil
            errorMessage = nil
            do {
                let data = try await useCase.loadSourceData()
                guard !Task.isCancelled else { return }
                let destination = epubCacheDirectory(bookID: useCase.book.id)
                let title = useCase.book.title
                let loaded = try await Task.detached(priority: .userInitiated) {
                    try EPUBPublicationLoader().load(
                        data: data,
                        fallbackTitle: title,
                        destination: destination
                    )
                }.value
                guard !Task.isCancelled else { return }
                let locations = loaded.chapters.map(\.location)
                if let initialLocation,
                    let initialIndex = locations.firstIndex(where: {
                        documentResource($0) == documentResource(initialLocation)
                    })
                {
                    currentChapter = initialIndex
                    currentChapterProgress = min(max(0, initialProgression ?? 0), 1)
                } else {
                    currentChapter =
                        command == .resume
                        ? DocumentReaderProgressMapper.initialIndex(progress: useCase.progress, locations: locations)
                        : 0
                    currentChapterProgress =
                        command == .resume
                        ? DocumentReaderProgressMapper.epubProgress(from: useCase.progress?.location) ?? 0
                        : 0
                }
                publication = loaded
                await signalReady()
            } catch is CancellationError {
                return
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        private func epubCacheDirectory(bookID: UUID) -> URL {
            let root =
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            return
                root
                .appending(path: "Prismedia", directoryHint: .isDirectory)
                .appending(path: "EPUB", directoryHint: .isDirectory)
                .appending(path: bookID.uuidString.lowercased(), directoryHint: .isDirectory)
        }

        private func openLocalURL(_ url: URL) {
            guard let publication,
                let index = publication.chapters.firstIndex(where: {
                    $0.fileURL.standardizedFileURL == documentURL(url)
                })
            else { return }
            selectChapter(index)
        }

        private func documentURL(_ url: URL) -> URL {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return url.standardizedFileURL
            }
            components.fragment = nil
            components.query = nil
            return components.url?.standardizedFileURL ?? url.standardizedFileURL
        }

        private func documentResource(_ location: String) -> String {
            let path = location.split(separator: "#", maxSplits: 1).first.map(String.init) ?? location
            return (path.removingPercentEncoding ?? path).lowercased()
        }

        private var activeCompanionPlayer: MusicPlayerController? {
            guard let companionPlayer,
                companionPlayer.context?.playbackOwnerEntityID == useCase.book.id,
                companionPlayer.context?.playbackOwnerEntityKind == .book
            else { return nil }
            return companionPlayer
        }

        private func signalReady() async {
            guard !hasSignaledReady else { return }
            hasSignaledReady = true
            await Task.yield()
            onReady()
        }

        private func saveProgress() {
            guard let publication,
                publication.chapters.indices.contains(currentChapter)
            else { return }
            let request = DocumentReaderProgressMapper.request(
                bookID: useCase.book.id,
                index: currentChapter,
                total: publication.chapters.count,
                unit: .cfi,
                mode: .scrolled,
                location: DocumentReaderProgressMapper.epubLocation(
                    chapterLocation: publication.chapters[currentChapter].location,
                    progress: currentChapterProgress
                ),
                completesAtEnd: false
            )
            progressWriter.queue(bookID: useCase.book.id, request: request)
        }

        private func selectChapter(_ index: Int) {
            guard index != currentChapter else { return }
            currentChapter = index
            currentChapterProgress = 0
            saveProgress()
        }

        private func recordScrollProgress(_ progress: Double) {
            currentChapterProgress = min(max(progress, 0), 1)
            progressSaveTask?.cancel()
            progressSaveTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                guard !Task.isCancelled else { return }
                saveProgress()
                progressSaveTask = nil
            }
        }

        private func close() {
            Task {
                progressSaveTask?.cancel()
                saveProgress()
                await progressWriter.flush()
                dismiss()
            }
        }
    }

    #if DEBUG
        #Preview("EPUB Reader · Invalid Fixture") {
            let book = EntityDetail(
                id: ComicReaderPreviewData.bookID,
                kind: .book,
                title: "Signal in the Static",
                parentEntityID: nil,
                sortOrder: nil,
                bookType: "book",
                bookFormat: .epub,
                hasSourceMedia: true,
                capabilities: [],
                childrenByKind: [],
                relationships: []
            )
            EPUBReaderView(book: book, command: .read, service: ComicReaderPreviewData.service)
        }
    #endif
#endif
