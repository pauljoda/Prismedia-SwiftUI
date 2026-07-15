#if os(iOS) && canImport(ReadiumNavigator)
    import Foundation
    @preconcurrency import ReadiumNavigator
    @preconcurrency import ReadiumShared
    @preconcurrency import ReadiumStreamer

    @MainActor
    final class ReadiumEPUBReaderSession: NSObject {
        private(set) var preferences: EPUBReaderPreferences

        var onProgressionChange: ((Double) -> Void)?
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
        private let progressWriter: BookReaderProgressWriter
        private var publication: Publication?
        private var navigator: EPUBNavigatorViewController?
        private var readingOrder: [Link] = []
        private var chapterTitlesByResource: [String: String] = [:]
        private var searchLocators: [String: Locator] = [:]
        private var searchGeneration = 0
        private var progression = 0.0
        private var toggleNavigation = EPUBToggleBookmarkNavigation()
        private var isToggleNavigationInFlight = false

        let host = ReadiumEPUBNavigatorHostController()

        init(
            book: EntityDetail,
            command: BookReaderCommand,
            service: any BookReaderServicing,
            preferencesStore: ReaderPreferencesStore,
            locatorStore: EPUBLocatorStore,
            initialLocation: String? = nil,
            initialProgression: Double? = nil
        ) {
            self.book = book
            self.command = command
            self.service = service
            self.preferencesStore = preferencesStore
            self.locatorStore = locatorStore
            self.initialLocation = initialLocation
            self.initialProgression = initialProgression
            progressWriter = BookReaderProgressWriter(service: service)
            preferences = preferencesStore.loadEPUB()
        }

        func load(
            useDarkSystemTheme: Bool
        ) async throws -> [EPUBTableOfContentsItem] {
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
            publication = opened
            navigator = controller
            let tableOfContents = tableOfContentsLinks.map(tableOfContentsItem)
            host.install(controller)
            if let currentLocation = controller.currentLocation {
                updateLocation(currentLocation)
            }
            return tableOfContents
        }

        func apply(_ preferences: EPUBReaderPreferences, useDarkSystemTheme: Bool) {
            self.preferences = preferences
            preferencesStore.save(preferences)
            navigator?.submitPreferences(readiumPreferences(useDarkSystemTheme: useDarkSystemTheme))
        }

        func openTableOfContentsItem(_ item: EPUBTableOfContentsItem) async {
            guard let publication, let location = item.location else { return }
            let links = (try? await publication.tableOfContents().get()) ?? []
            guard let link = findLink(location, in: links) else { return }
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
            return await navigator?.go(to: locator, options: .animated) ?? false
        }

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
            _ = await navigator?.go(to: locator, options: .animated)
        }

        func currentBookmark(createdAt: Date = Date()) -> EPUBBookmark? {
            guard
                let locator = navigator?.currentLocation,
                let location = try? locator.jsonString()
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
            let didNavigate = await navigator?.go(to: locator, options: .animated) ?? false
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
                let currentLocation = try? currentLocator.jsonString()
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

            let didNavigate = await navigator?.go(to: locator, options: .animated) ?? false
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

        var isToggleReturnAvailable: Bool {
            toggleNavigation.isReturnAvailable
        }

        func goBackward() async {
            _ = await navigator?.goBackward(options: .animated)
        }

        func goForward() async {
            _ = await navigator?.goForward(options: .animated)
        }

        func flush(closing: Bool) async {
            if shouldPersistReadingLocation {
                saveProgress(closing: closing)
            }
            await progressWriter.flush()
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
            if let initialLocation,
                let link = findLink(
                    initialLocation,
                    in: tableOfContentsLinks + publication.readingOrder
                )
            {
                guard let locator = await publication.locate(link) else { return nil }
                guard let initialProgression else { return locator }
                return locator.copy(locations: {
                    $0.progression = min(max(0, initialProgression), 1)
                })
            }
            guard command == .resume, let progress = progressCapability else { return nil }
            if let location = locatorStore.load(bookID: book.id) ?? readiumMigrationLocation,
                let locator = try? Locator(jsonString: location),
                let normalized = await publication.locate(locator)
            {
                locatorStore.save(location, bookID: book.id)
                return normalized
            }
            let total = max(1, progress.total)
            let progression = min(max(Double(progress.index) / Double(total), 0), 1)
            updateProgression(progression)
            return await publication.locate(progression: progression)
        }

        private var progressCapability: EntityProgressCapability? {
            book.capabilities.lazy.compactMap { capability in
                guard case .progress(let progress) = capability else { return nil }
                return progress
            }.first
        }

        private var readiumMigrationLocation: String? {
            guard let location = progressCapability?.location,
                location.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{")
            else { return nil }
            return location
        }

        private func readiumPreferences(useDarkSystemTheme: Bool) -> EPUBPreferences {
            let theme: Theme =
                switch preferences.theme {
                case .system: useDarkSystemTheme ? .dark : .light
                case .light: .light
                case .sepia: .sepia
                case .dark: .dark
                }
            let family: FontFamily? =
                switch preferences.fontFamily {
                case .publisher: nil
                case .serif: .serif
                case .sansSerif: .sansSerif
                }
            return EPUBPreferences(
                fontFamily: family,
                fontSize: preferences.fontScale,
                lineHeight: preferences.lineHeight,
                pageMargins: preferences.pageMargins,
                publisherStyles: preferences.fontFamily == .publisher,
                scroll: preferences.flow == .scrolled,
                theme: theme
            )
        }

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

        private func normalizedTitle(_ title: String?) -> String? {
            let title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return title.isEmpty ? nil : title
        }

        private func resolvedLocator(_ location: String) async -> Locator? {
            guard
                let publication,
                let locator = try? Locator(jsonString: location)
            else { return nil }
            return await publication.locate(locator)
        }

        private var shouldPersistReadingLocation: Bool {
            !isToggleNavigationInFlight && toggleNavigation.shouldRecordProgress
        }

        private func notifyToggleReturnAvailabilityChange(
            from previousNavigation: EPUBToggleBookmarkNavigation
        ) {
            guard previousNavigation.isReturnAvailable != toggleNavigation.isReturnAvailable else {
                return
            }
            onToggleReturnAvailabilityChange?(toggleNavigation.isReturnAvailable)
        }

        private func saveProgress(closing: Bool) {
            let request = DocumentReaderProgressMapper.epubRequest(
                bookID: book.id,
                progression: progression,
                mode: preferences.flow,
                location: nil,
                closing: closing
            )
            progressWriter.queue(bookID: book.id, request: request)
        }

        private func updateProgression(_ progression: Double) {
            self.progression = min(max(progression, 0), 1)
            onProgressionChange?(self.progression)
        }

        private func updateLocation(
            _ locator: Locator,
            viewport: NavigatorViewport? = nil
        ) {
            if let totalProgression = locator.locations.totalProgression {
                updateProgression(totalProgression)
            }
            if let chapterProgress = chapterProgress(
                for: locator,
                viewport: viewport ?? navigator?.viewport
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
    }

    extension ReadiumEPUBReaderSession: EPUBNavigatorDelegate {
        func navigator(_ navigator: VisualNavigator, didTapAt point: CGPoint) {
            onContentTap?()
        }

        func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
            updateLocation(locator)
            guard shouldPersistReadingLocation else { return }
            if let locationDescription = try? locator.jsonString() {
                locatorStore.save(locationDescription, bookID: book.id)
            }
            saveProgress(closing: false)
        }

        func navigator(
            _ navigator: any ViewportObservingNavigator,
            viewportDidChange viewport: NavigatorViewport?
        ) {
            guard let locator = self.navigator?.currentLocation else { return }
            updateLocation(locator, viewport: viewport)
        }

        func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
            onError?("This protected publication does not allow that action.")
        }
    }
#endif
