#if os(iOS) && canImport(ReadiumNavigator)
    import Foundation
    @preconcurrency import ReadiumNavigator
    @preconcurrency import ReadiumShared
    @preconcurrency import ReadiumStreamer
    import WebKit

    /// Bridges Readium's EPUB navigator to Prismedia's reader: loading, navigation, search,
    /// bookmarks, and reading-progress persistence.
    ///
    /// Exact paragraph positions are decided by ``EPUBExactLocationTracker``; this adapter only
    /// forwards navigator, input, and script events to it and persists what it accepts.
    @MainActor
    final class ReadiumEPUBReaderSession: NSObject {
        // MARK: - Static Variables

        private static let paragraphRestoreAttempts = 8
        private static let paragraphRestoreRetryDelay = Duration.milliseconds(150)
        private static let preferenceLayoutSettleDelay = Duration.milliseconds(350)

        // MARK: - Variables

        let host = ReadiumEPUBNavigatorHostController()
        private(set) var preferences: EPUBReaderPreferences

        var onProgressionChange: ((Double) -> Void)?
        var onExactLocationChange: ((String) -> Void)?
        var onChapterProgressChange: ((EPUBChapterProgress) -> Void)?
        var onPageNavigationAvailabilityChange: ((Bool, Bool) -> Void)?
        var onToggleReturnAvailabilityChange: ((Bool) -> Void)?
        var onError: ((String) -> Void)?
        var onContentTap: (() -> Void)?

        private let book: EntityDetail
        private let command: BookReaderCommand
        private let service: any BookReaderServicing
        private let preferencesStore: ReaderPreferencesStore
        private let locatorStore: EPUBLocatorStore
        private let initialLocation: String?
        private let initialProgression: Double?
        private let initialUpdatedAt: Date?
        private let progressRanges: [EPUBReadingProgressRange]
        private let readingReportFormat: BookReadingReportFormat
        private let progressWriter: BookReaderProgressWriter
        private var publication: Publication?
        private var navigator: EPUBNavigatorViewController?
        private var readingOrder: [Link] = []
        private var chapterTitlesByResource: [String: String] = [:]
        private var chapterLocationsByResource: [String: String] = [:]
        private var searchLocators: [String: Locator] = [:]
        private var exactLocation = EPUBExactLocationTracker()
        private var toggleNavigation = EPUBToggleBookmarkNavigation()
        private var captureTask: Task<Void, Never>?
        private var restoreTask: Task<Void, Never>?
        private var activeResourceKey: String?
        private var pendingChapterRestoreResourceKey: String?
        private var explicitNavigationResourceKey: String?
        private var scrollFocusResourceKey: String?
        private var searchGeneration = 0
        private var preferenceApplyGeneration = 0
        private var progression = 0.0
        private var resourceProgression = 0.0
        private var isSettlingPreferences = false
        private var isToggleNavigationInFlight = false

        var isToggleReturnAvailable: Bool {
            toggleNavigation.isReturnAvailable
        }

        private var shouldPersistReadingLocation: Bool {
            !isToggleNavigationInFlight && toggleNavigation.shouldRecordProgress
        }

        private var readiumBackgroundColor: Color? {
            switch preferences.theme {
            case .system, .light, .sepia: nil
            case .paper: Color(hex: "#F7F5EE")
            case .gray: Color(hex: "#E8E8E6")
            case .dark: Color(hex: "#121212")
            }
        }

        private var readiumTextColor: Color? {
            switch preferences.theme {
            case .system, .light, .sepia: nil
            case .paper, .gray: Color(hex: "#202020")
            case .dark: Color(hex: "#E7E2D7")
            }
        }

        // MARK: - Initializers

        init(
            book: EntityDetail,
            command: BookReaderCommand,
            service: any BookReaderServicing,
            preferencesStore: ReaderPreferencesStore,
            locatorStore: EPUBLocatorStore,
            initialLocation: String? = nil,
            initialProgression: Double? = nil,
            initialUpdatedAt: Date? = nil,
            progressRanges: [EPUBReadingProgressRange] = [],
            readingReportFormat: BookReadingReportFormat = .legacyCursor
        ) {
            self.book = book
            self.command = command
            self.service = service
            self.preferencesStore = preferencesStore
            self.locatorStore = locatorStore
            self.initialLocation = initialLocation
            self.initialProgression = initialProgression
            self.initialUpdatedAt = initialUpdatedAt
            self.progressRanges = progressRanges
            self.readingReportFormat = readingReportFormat
            progressWriter = BookReaderProgressWriter(service: service)
            preferences = preferencesStore.loadEPUB()
        }

        // MARK: - Actions - Loading

        func load(
            useDarkSystemTheme: Bool
        ) async throws -> [EPUBTableOfContentsItem] {
            cancelExactLocationWork()
            exactLocation.reset()
            let data = try await service.loadSourceData(id: book.id)
            try Task.checkCancellation()
            let fileURL = try cache(data)
            let httpClient = DefaultHTTPClient()
            let retriever = AssetRetriever(httpClient: httpClient)
            guard let readiumURL = FileURL(url: fileURL) else {
                throw EPUBReaderError.invalidArchive
            }
            let asset = try await retriever.retrieve(
                url: readiumURL,
                hints: FormatHints(mediaType: .epub, fileExtension: .epub)
            ).get()
            let opener = PublicationOpener(
                parser: DefaultPublicationParser(
                    httpClient: httpClient,
                    assetRetriever: retriever,
                    pdfFactory: DefaultPDFDocumentFactory()
                )
            )
            let opened = try await opener.open(
                asset: asset,
                allowUserInteraction: false
            ).get()
            guard !opened.isRestricted else { throw EPUBReaderError.unsupportedDRM }
            try Task.checkCancellation()

            let tableOfContentsLinks = try await opened.tableOfContents().get()
            readingOrder = opened.readingOrder
            chapterTitlesByResource = chapterTitles(in: tableOfContentsLinks)

            let initialLocation = await restoreLocation(
                in: opened,
                tableOfContentsLinks: tableOfContentsLinks
            )
            let controller = try EPUBNavigatorViewController(
                publication: opened,
                initialLocation: initialLocation,
                config: .init(
                    preferences: readiumPreferences(useDarkSystemTheme: useDarkSystemTheme),
                    preloadPreviousPositionCount: 2,
                    preloadNextPositionCount: 6
                )
            )
            controller.delegate = self
            controller.addObserver(
                ReadiumEPUBInputActivityObserver { [weak self] in
                    self?.recordUserInput()
                }
            )
            publication = opened
            navigator = controller
            let tableOfContents = tableOfContentsLinks.map(tableOfContentsItem)
            host.install(controller)
            // A saved paragraph is placed from the first reported location, after Readium has
            // positioned the chapter; placing it earlier would be undone by Readium's own scroll.
            if let currentLocation = controller.currentLocation {
                activeResourceKey = resourceKey(currentLocation.href)
                updateLocation(currentLocation)
            }
            return tableOfContents
        }

        private func cache(_ data: Data) throws -> URL {
            let root =
                FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let directory =
                root
                .appending(path: "Prismedia", directoryHint: .isDirectory)
                .appending(path: "Readium", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appending(path: "\(book.id.uuidString.lowercased()).epub")
            try data.write(to: url, options: .atomic)
            return url
        }

        private func restoreLocation(
            in publication: Publication,
            tableOfContentsLinks: [Link]
        ) async -> Locator? {
            let checkpoint = command == .resume
                ? locatorStore.loadCheckpoint(bookID: book.id)
                : nil
            let source = EPUBReaderResumeSourceResolver().resolve(
                explicitLocation: initialLocation,
                explicitProgression: initialProgression,
                explicitUpdatedAt: initialUpdatedAt,
                deviceLocation: checkpoint?.locator,
                deviceUpdatedAt: checkpoint?.savedAt
            )
            switch source {
            case .explicitLocator(let location), .device(let location):
                guard let locator = locator(from: location),
                    let resolved = await publication.locate(locator)
                else { return nil }
                beginParagraphRestore(of: location, at: resolved)
                return resolved
            case .explicit(let target):
                guard
                    let link = findLink(
                        target.location,
                        in: tableOfContentsLinks + publication.readingOrder
                    ),
                    let locator = await publication.locate(link)
                else { return nil }
                return locator.copy(locations: {
                    $0.progression = target.progression
                })
            case nil:
                return nil
            }
        }

        // MARK: - Actions - Preferences

        func apply(_ preferences: EPUBReaderPreferences, useDarkSystemTheme: Bool) {
            preferenceApplyGeneration &+= 1
            let generation = preferenceApplyGeneration
            self.preferences = preferences
            preferencesStore.save(preferences)
            let restoresParagraph = beginRestoreOfAcceptedParagraph()
            isSettlingPreferences = restoresParagraph
            navigator?.submitPreferences(readiumPreferences(useDarkSystemTheme: useDarkSystemTheme))
            Task {
                await applyScrollFocus()
                guard restoresParagraph else { return }
                try? await Task.sleep(for: Self.preferenceLayoutSettleDelay)
                guard generation == preferenceApplyGeneration else { return }
                isSettlingPreferences = false
                guard let currentLocation = navigator?.currentLocation else { return }
                restorePendingParagraph(in: currentLocation)
            }
        }

        private func readiumPreferences(useDarkSystemTheme: Bool) -> EPUBPreferences {
            let theme: Theme =
                switch preferences.theme {
                case .system: useDarkSystemTheme ? .dark : .light
                case .paper, .light, .gray: .light
                case .sepia: .sepia
                case .dark: .dark
                }
            let family: FontFamily? =
                switch preferences.fontFamily {
                case .publisher: nil
                case .serif: .iowanOldStyle
                case .literary: .athelas
                case .sansSerif: .seravek
                case .accessible: .accessibleDfA
                case .openDyslexic: .openDyslexic
                case .monospaced: .iaWriterDuospace
                }
            let columnCount: ColumnCount =
                switch preferences.columnCount {
                case .automatic: .auto
                case .one: .one
                case .two: .two
                }
            let textAlignment: TextAlignment? =
                switch preferences.textAlignment {
                case .automatic: nil
                case .leading: .start
                case .justified: .justify
                }
            return EPUBPreferences(
                backgroundColor: readiumBackgroundColor,
                columnCount: columnCount,
                fontFamily: family,
                fontSize: preferences.fontScale,
                fontWeight: preferences.fontWeight,
                hyphens: preferences.hyphenationEnabled,
                letterSpacing: preferences.letterSpacing,
                lineHeight: preferences.lineHeight,
                pageMargins: preferences.pageMargins,
                paragraphIndent: preferences.paragraphIndent,
                paragraphSpacing: preferences.paragraphSpacing,
                publisherStyles: preferences.usesPublisherStyles,
                scroll: preferences.flow == .scrolled,
                textAlign: textAlignment,
                textColor: readiumTextColor,
                textNormalization: preferences.textNormalizationEnabled,
                theme: theme,
                wordSpacing: preferences.wordSpacing
            )
        }

        private func applyScrollFocus() async {
            guard let navigator else { return }
            _ = await navigator.evaluateJavaScript(
                EPUBScrollFocusScript.update(preferences: preferences)
            )
        }

        // MARK: - Actions - Navigation

        func openTableOfContentsItem(_ item: EPUBTableOfContentsItem) async {
            guard let publication, let location = item.location else { return }
            saveBeforeNavigation()
            if let savedLocation = savedChapterLocation(for: location),
                let locator = await resolvedLocator(savedLocation)
            {
                _ = await navigateExplicitly(to: locator, restoring: savedLocation)
                return
            }
            let links = (try? await publication.tableOfContents().get()) ?? []
            guard let link = findLink(location, in: links) else { return }
            recordNavigation()
            _ = await navigator?.go(to: link, options: .animated)
        }

        @discardableResult
        func openReadingTarget(_ target: BookReaderLocationTarget) async -> Bool {
            guard
                let publication,
                let link = findLink(target.location, in: readingOrder),
                let chapterLocator = await publication.locate(link)
            else { return false }
            let locator = chapterLocator.copy(locations: {
                $0.progression = target.progression
            })
            return await navigateExplicitly(to: locator)
        }

        func goBackward() async {
            saveBeforeNavigation()
            recordNavigation()
            _ = await navigator?.goBackward(options: .animated)
        }

        func goForward() async {
            saveBeforeNavigation()
            recordNavigation()
            _ = await navigator?.goForward(options: .animated)
        }

        /// Moves to a destination the reader chose. A `location` carrying a paragraph anchor is
        /// restored exactly and protected from the settle that follows it.
        private func navigateExplicitly(
            to locator: Locator,
            restoring location: String? = nil
        ) async -> Bool {
            saveBeforeNavigation()
            let restoresParagraph = location.map { beginParagraphRestore(of: $0, at: locator) } ?? false
            if !restoresParagraph {
                recordNavigation()
            }
            let destinationResourceKey = resourceKey(locator.href)
            explicitNavigationResourceKey = destinationResourceKey
            let didNavigate = await navigator?.go(to: locator, options: .animated) ?? false
            if didNavigate {
                restorePendingParagraph(in: locator)
            } else if let currentLocation = navigator?.currentLocation {
                // The reader stayed put; follow the page that is still showing.
                recordNavigation()
                trackLocation(currentLocation)
            }
            if explicitNavigationResourceKey == destinationResourceKey {
                explicitNavigationResourceKey = nil
            }
            return didNavigate
        }

        /// Saves the accepted location for the current chapter before the reader navigates away.
        private func saveBeforeNavigation() {
            guard
                shouldPersistReadingLocation,
                let locator = navigator?.currentLocation
            else { return }
            activeResourceKey = resourceKey(locator.href)
            updateLocation(locator)
            persistAcceptedLocation()
        }

        // MARK: - Actions - Search

        func search(_ query: String) async -> [EPUBSearchResult] {
            searchGeneration &+= 1
            let generation = searchGeneration
            let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
            searchLocators = [:]
            guard !query.isEmpty, let publication, publication.isSearchable else { return [] }
            guard case .success(let iterator) = await publication.search(query: query) else { return [] }

            var results: [EPUBSearchResult] = []
            var locators: [String: Locator] = [:]
            while !Task.isCancelled, results.count < 100 {
                guard case .success(let collection) = await iterator.next(), let collection else { break }
                for locator in collection.locators {
                    let location = (try? locator.jsonString()) ?? locator.description
                    let text = locator.text.sanitized()
                    let result = EPUBSearchResult(
                        id: location,
                        title: chapterTitle(for: locator),
                        before: text.before,
                        highlight: text.highlight,
                        after: text.after,
                        chapterPage: nil,
                        chapterPageCount: nil,
                        location: location
                    )
                    results.append(result)
                    locators[result.id] = locator
                }
            }
            guard generation == searchGeneration else { return [] }
            searchLocators = locators
            return results
        }

        func openSearchResult(_ result: EPUBSearchResult) async {
            guard let locator = searchLocators[result.id] else { return }
            _ = await navigateExplicitly(to: locator)
        }

        // MARK: - Actions - Bookmarks

        func currentBookmark(createdAt: Date = Date()) -> EPUBBookmark? {
            guard
                let locator = navigator?.currentLocation,
                let location = currentExactLocation(for: locator)
            else { return nil }

            guard
                let chapterProgress = chapterProgress(
                    for: locator,
                    viewport: navigator?.viewport
                )
            else { return nil }
            return EPUBBookmark(
                id: UUID(),
                locator: location,
                chapterTitle: chapterProgress.chapterTitle,
                chapterPage: chapterProgress.pageNumber,
                chapterPageCount: chapterProgress.pageCount,
                createdAt: createdAt
            )
        }

        @discardableResult
        func openBookmark(_ bookmark: EPUBBookmark) async -> Bool {
            guard let locator = await resolvedLocator(bookmark.locator) else { return false }

            let previousNavigation = toggleNavigation
            toggleNavigation.reset()
            let didNavigate = await navigateExplicitly(to: locator, restoring: bookmark.locator)
            if !didNavigate {
                toggleNavigation = previousNavigation
                return false
            }
            notifyToggleReturnAvailabilityChange(from: previousNavigation)
            return didNavigate
        }

        @discardableResult
        func toggleBookmark(_ bookmark: EPUBBookmark) async -> Bool {
            guard !isToggleNavigationInFlight else { return false }
            isToggleNavigationInFlight = true
            defer { isToggleNavigationInFlight = false }

            guard
                let currentLocator = navigator?.currentLocation,
                let currentLocation = currentExactLocation(for: currentLocator)
            else { return false }

            let previousNavigation = toggleNavigation
            let destination = toggleNavigation.destination(
                toggleBookmarkLocator: bookmark.locator,
                currentLocator: currentLocation
            )
            guard let locator = await resolvedLocator(destination) else {
                toggleNavigation = previousNavigation
                return false
            }

            let didNavigate = await navigateExplicitly(to: locator, restoring: destination)
            if !didNavigate {
                toggleNavigation = previousNavigation
                return false
            }
            notifyToggleReturnAvailabilityChange(from: previousNavigation)
            return didNavigate
        }

        func resetToggleBookmarkNavigation() {
            let previousNavigation = toggleNavigation
            toggleNavigation.reset()
            isToggleNavigationInFlight = false
            notifyToggleReturnAvailabilityChange(from: previousNavigation)
        }

        private func notifyToggleReturnAvailabilityChange(
            from previousNavigation: EPUBToggleBookmarkNavigation
        ) {
            guard previousNavigation.isReturnAvailable != toggleNavigation.isReturnAvailable else {
                return
            }
            onToggleReturnAvailabilityChange?(toggleNavigation.isReturnAvailable)
        }

        // MARK: - Actions - Progress

        /// Saves the last accepted location. Closing never re-reads a paragraph from the page: it
        /// freezes the exact-location tracker, cancels pending measurements, and saves what the
        /// reader last chose.
        func flush(closing: Bool) async {
            if closing {
                cancelExactLocationWork()
                exactLocation.close()
            }
            if shouldPersistReadingLocation, closing || !exactLocation.isClosed {
                saveProgress(closing: closing, stoppingActivity: closing)
            }
            await progressWriter.flush()
        }

        func beginActivity() {
            progressWriter.beginActivity(bookID: book.id)
        }

        func heartbeat() {
            persistAcceptedLocation()
        }

        func pauseActivity() async {
            if shouldPersistReadingLocation, !exactLocation.isClosed {
                saveProgress(closing: false, stoppingActivity: true)
            }
            await progressWriter.flush()
        }

        private func persistAcceptedLocation() {
            guard shouldPersistReadingLocation, !exactLocation.isClosed else { return }
            saveProgress(closing: false)
        }

        private func saveProgress(closing: Bool, stoppingActivity: Bool = false) {
            rememberAcceptedChapterLocation()
            let currentLocation = navigator?.currentLocation
            let mappedProgression = currentLocation.flatMap {
                DocumentReaderProgressMapper.epubBookProgression(
                    resourceLocation: $0.href.string,
                    ranges: progressRanges,
                    resourceProgression: resourceProgression
                )
            }
            let request = DocumentReaderProgressMapper.epubRequest(
                bookID: book.id,
                progression: mappedProgression ?? progression,
                mode: preferences.flow,
                location: exactLocation.acceptedLocation,
                closing: closing,
                format: readingReportFormat
            )
            progressWriter.queue(
                bookID: book.id,
                request: request,
                stoppingActivity: stoppingActivity
            )
        }

        private func rememberAcceptedChapterLocation() {
            guard
                let location = exactLocation.acceptedLocation,
                let chapterLocation = exactLocation.acceptedResourceKey
            else { return }
            chapterLocationsByResource[chapterLocation] = location
            locatorStore.save(
                location,
                bookID: book.id,
                chapterLocation: chapterLocation
            )
        }

        private func savedChapterLocation(for chapterLocation: String) -> String? {
            let chapterLocation = resourceKey(chapterLocation)
            return chapterLocationsByResource[chapterLocation]
                ?? locatorStore.load(
                    bookID: book.id,
                    chapterLocation: chapterLocation
                )
        }

        private func updateProgression(_ progression: Double) {
            self.progression = min(max(progression, 0), 1)
            onProgressionChange?(self.progression)
        }

        // MARK: - Actions - Location

        private func updateLocation(
            _ locator: Locator,
            viewport: NavigatorViewport? = nil
        ) {
            let resourceKey = resourceKey(locator.href)
            let currentViewport = viewport ?? navigator?.viewport
            if resourceKey != scrollFocusResourceKey {
                scrollFocusResourceKey = resourceKey
                Task { await applyScrollFocus() }
            }
            if let visibleResource = currentViewport?.resources.first(where: {
                self.resourceKey($0.href) == resourceKey
            }) {
                resourceProgression = min(max(visibleResource.progression.lowerBound, 0), 1)
            } else if let locatorProgression = locator.locations.progression {
                resourceProgression = min(max(locatorProgression, 0), 1)
            }
            if let totalProgression = locator.locations.totalProgression {
                updateProgression(totalProgression)
            }
            if let chapterProgress = chapterProgress(
                for: locator,
                viewport: currentViewport
            ) {
                onChapterProgressChange?(chapterProgress)
                if let resourceIndex = resourceIndex(for: locator.href) {
                    onPageNavigationAvailabilityChange?(
                        resourceIndex > 0 || chapterProgress.pageNumber > 1,
                        resourceIndex < readingOrder.count - 1
                            || chapterProgress.pageNumber < chapterProgress.pageCount
                    )
                }
            }
        }

        private func recordLocationChange(_ locator: Locator) {
            activeResourceKey = resourceKey(locator.href)
            updateLocation(locator)
            trackLocation(locator)
            restorePendingParagraph(in: locator)
        }

        private func restoreChapterPositionIfAvailable(
            afterOpening locator: Locator
        ) -> Bool {
            let destinationResourceKey = resourceKey(locator.href)
            guard
                let activeResourceKey,
                activeResourceKey != destinationResourceKey,
                let savedLocation = savedChapterLocation(
                    for: destinationResourceKey
                )
            else { return false }

            pendingChapterRestoreResourceKey = destinationResourceKey
            Task {
                guard
                    let restoredLocator = await resolvedLocator(savedLocation),
                    pendingChapterRestoreResourceKey == destinationResourceKey
                else {
                    pendingChapterRestoreResourceKey = nil
                    recordLocationChange(locator)
                    return
                }
                if !beginParagraphRestore(of: savedLocation, at: restoredLocator) {
                    recordNavigation()
                }
                let didRestore = await navigator?.go(
                    to: restoredLocator,
                    options: .init()
                ) ?? false
                guard !didRestore,
                    pendingChapterRestoreResourceKey == destinationResourceKey
                else { return }
                pendingChapterRestoreResourceKey = nil
                recordLocationChange(locator)
            }
            return true
        }

        // MARK: - Actions - Exact Location

        /// Applies one tracker event and publishes the accepted location when it changes.
        @discardableResult
        private func trackExactLocation<Result>(
            persisting: Bool,
            _ event: (inout EPUBExactLocationTracker) -> Result
        ) -> Result {
            let previousLocation = exactLocation.acceptedLocation
            let result = event(&exactLocation)
            guard let acceptedLocation = exactLocation.acceptedLocation,
                acceptedLocation != previousLocation
            else { return result }
            onExactLocationChange?(acceptedLocation)
            if persisting {
                persistAcceptedLocation()
            }
            return result
        }

        /// Reports a Readium position to the tracker and measures its paragraph when asked.
        private func trackLocation(_ locator: Locator) {
            guard let location = try? locator.jsonString() else { return }
            let resourceKey = resourceKey(locator.href)
            let request = trackExactLocation(persisting: true) {
                $0.recordLocation(location, in: resourceKey)
            }
            guard let request else { return }
            captureTask?.cancel()
            captureTask = Task { await captureParagraph(for: request) }
        }

        private func captureParagraph(for request: EPUBParagraphCaptureRequest) async {
            guard let navigator, isShowing(request.resourceKey) else { return }
            let result = await navigator.evaluateJavaScript(
                EPUBScrollFocusScript.currentParagraphViewport
            )
            guard !Task.isCancelled else { return }
            let viewport: EPUBParagraphViewport? =
                switch result {
                case .success(let value) where isShowing(request.resourceKey):
                    EPUBParagraphViewport(scriptResult: value)
                case .success, .failure:
                    nil
                }
            trackExactLocation(persisting: true) {
                $0.recordCapture(viewport, for: request)
            }
        }

        private func recordUserInput() {
            exactLocation.recordUserInput()
        }

        private func recordNavigation() {
            cancelExactLocationWork()
            exactLocation.recordNavigation()
        }

        /// Starts restoring `location` when it names a paragraph in `locator`'s chapter.
        /// - Returns: `false` when the location has no paragraph anchor.
        @discardableResult
        private func beginParagraphRestore(of location: String, at locator: Locator) -> Bool {
            guard EPUBParagraphLocator.anchor(from: location) != nil else { return false }
            cancelExactLocationWork()
            let resourceKey = resourceKey(locator.href)
            return trackExactLocation(persisting: false) {
                $0.beginRestore(of: location, in: resourceKey)
            }
        }

        /// Protects the accepted paragraph while a preference change lays the chapter out again.
        private func beginRestoreOfAcceptedParagraph() -> Bool {
            guard
                let location = exactLocation.acceptedLocation,
                let resourceKey = exactLocation.acceptedResourceKey,
                resourceKey == activeResourceKey,
                EPUBParagraphLocator.anchor(from: location) != nil
            else { return false }
            cancelExactLocationWork()
            return exactLocation.beginRestore(of: location, in: resourceKey)
        }

        private func restorePendingParagraph(in locator: Locator) {
            let resourceKey = resourceKey(locator.href)
            guard
                restoreTask == nil,
                !isSettlingPreferences,
                exactLocation.restoreAnchor(in: resourceKey) != nil
            else { return }
            restoreTask = Task { await restoreParagraph(in: resourceKey) }
        }

        private func restoreParagraph(in resourceKey: String) async {
            defer {
                if !Task.isCancelled {
                    restoreTask = nil
                }
            }
            for attempt in 1...Self.paragraphRestoreAttempts {
                guard
                    !Task.isCancelled,
                    let anchor = exactLocation.restoreAnchor(in: resourceKey)
                else { return }
                if let landing = await scrollToParagraph(anchor, in: resourceKey) {
                    guard !Task.isCancelled else { return }
                    exactLocation.finishRestore(in: resourceKey, landing: landing)
                    return
                }
                if attempt < Self.paragraphRestoreAttempts {
                    try? await Task.sleep(for: Self.paragraphRestoreRetryDelay)
                }
            }
            guard !Task.isCancelled else { return }
            exactLocation.abandonRestore(in: resourceKey)
        }

        private func scrollToParagraph(
            _ anchor: EPUBParagraphAnchor,
            in resourceKey: String
        ) async -> EPUBParagraphViewport? {
            guard let navigator, isShowing(resourceKey) else { return nil }
            let result = await navigator.evaluateJavaScript(
                EPUBScrollFocusScript.restoreParagraphAnchor(anchor)
            )
            guard case .success(let value) = result, isShowing(resourceKey) else { return nil }
            return EPUBParagraphViewport(scriptResult: value)
        }

        private func cancelExactLocationWork() {
            captureTask?.cancel()
            captureTask = nil
            restoreTask?.cancel()
            restoreTask = nil
        }

        /// The accepted exact location when it belongs to `locator`'s chapter, otherwise Readium's locator.
        private func currentExactLocation(for locator: Locator) -> String? {
            if exactLocation.acceptedResourceKey == resourceKey(locator.href),
                let acceptedLocation = exactLocation.acceptedLocation
            {
                return acceptedLocation
            }
            return try? locator.jsonString()
        }

        private func isShowing(_ resourceKey: String) -> Bool {
            navigator?.currentLocation.map { self.resourceKey($0.href) } == resourceKey
        }

        // MARK: - Actions - Publication

        private func tableOfContentsItem(_ link: Link) -> EPUBTableOfContentsItem {
            let title = link.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return EPUBTableOfContentsItem(
                title: title.isEmpty ? "Untitled" : title,
                location: link.href,
                children: link.children.map(tableOfContentsItem)
            )
        }

        private func findLink(_ href: String, in links: [Link]) -> Link? {
            let candidates = flattenedLinks(links)
            guard
                let matchedHref = EPUBResourceLocationMatcher().bestMatch(
                    for: href,
                    candidates: candidates.map(\.href)
                )
            else { return nil }
            return candidates.first { $0.href == matchedHref }
        }

        private func flattenedLinks(_ links: [Link]) -> [Link] {
            links.flatMap { [$0] + flattenedLinks($0.children) }
        }

        private func chapterTitles(in links: [Link]) -> [String: String] {
            var titles: [String: String] = [:]
            collectChapterTitles(in: links, into: &titles)
            return titles
        }

        private func collectChapterTitles(
            in links: [Link],
            into titles: inout [String: String]
        ) {
            for link in links {
                let title = link.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !title.isEmpty {
                    titles[resourceKey(link.url()), default: title] = title
                }
                collectChapterTitles(in: link.children, into: &titles)
            }
        }

        private func chapterProgress(
            for locator: Locator,
            viewport: NavigatorViewport?
        ) -> EPUBChapterProgress? {
            guard
                let resource = viewport?.resources.first(where: {
                    resourceKey($0.href) == resourceKey(locator.href)
                })
            else { return nil }

            return EPUBChapterProgress(
                chapterTitle: chapterTitle(for: locator),
                visibleProgression: resource.progression
            )
        }

        private func chapterTitle(for locator: Locator) -> String {
            guard let resourceIndex = resourceIndex(for: locator.href) else {
                return normalizedTitle(locator.title) ?? "Chapter"
            }
            return normalizedTitle(locator.title)
                ?? chapterTitlesByResource[resourceKey(locator.href)]
                ?? normalizedTitle(readingOrder[resourceIndex].title)
                ?? "Chapter \(resourceIndex + 1)"
        }

        private func resourceIndex(for href: AnyURL) -> Int? {
            let key = resourceKey(href)
            return readingOrder.firstIndex { resourceKey($0.url()) == key }
        }

        private func resourceKey(_ href: AnyURL) -> String {
            String(href.string.split(separator: "#", maxSplits: 1).first ?? "")
        }

        private func resourceKey(_ href: String) -> String {
            String(href.split(separator: "#", maxSplits: 1).first ?? "")
        }

        private func normalizedTitle(_ title: String?) -> String? {
            let title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return title.isEmpty ? nil : title
        }

        private func resolvedLocator(_ location: String) async -> Locator? {
            guard
                let publication,
                let locator = locator(from: location)
            else { return nil }
            return await publication.locate(locator)
        }

        /// Parses a saved location into a Readium locator without Prismedia's paragraph anchor.
        private func locator(from serializedLocation: String) -> Locator? {
            let readiumLocation = EPUBParagraphLocator.removingAnchor(from: serializedLocation)
                ?? serializedLocation
            return try? Locator(jsonString: readiumLocation)
        }
    }

    extension ReadiumEPUBReaderSession: EPUBNavigatorDelegate {
        func navigator(
            _ navigator: EPUBNavigatorViewController,
            setupUserScripts userContentController: WKUserContentController
        ) {
            userContentController.addUserScript(
                WKUserScript(
                    source: EPUBScrollFocusScript.install(preferences: preferences),
                    injectionTime: .atDocumentEnd,
                    forMainFrameOnly: true
                )
            )
        }

        func navigator(_ navigator: VisualNavigator, didTapAt point: CGPoint) {
            onContentTap?()
        }

        func navigator(_ navigator: VisualNavigator, shouldNavigateToLink link: Link) -> Bool {
            recordNavigation()
            return true
        }

        func navigator(
            _ navigator: Navigator,
            shouldNavigateToNoteAt link: Link,
            content: String,
            referrer: String?
        ) -> Bool {
            recordNavigation()
            return true
        }

        func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
            let destinationResourceKey = resourceKey(locator.href)
            if explicitNavigationResourceKey == destinationResourceKey {
                explicitNavigationResourceKey = nil
                pendingChapterRestoreResourceKey = nil
                recordLocationChange(locator)
                return
            }
            if pendingChapterRestoreResourceKey == destinationResourceKey {
                pendingChapterRestoreResourceKey = nil
                recordLocationChange(locator)
                return
            }
            guard !restoreChapterPositionIfAvailable(afterOpening: locator) else { return }
            recordLocationChange(locator)
        }

        func navigator(
            _ navigator: any ViewportObservingNavigator,
            viewportDidChange viewport: NavigatorViewport?
        ) {
            guard pendingChapterRestoreResourceKey == nil else { return }
            guard let locator = self.navigator?.currentLocation else { return }
            let destinationResourceKey = resourceKey(locator.href)
            guard destinationResourceKey == activeResourceKey
                || destinationResourceKey == explicitNavigationResourceKey
            else { return }
            updateLocation(locator, viewport: viewport)
            trackLocation(locator)
        }

        func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
            onError?("This protected publication does not allow that action.")
        }
    }
#endif
