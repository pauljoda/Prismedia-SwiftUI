import Foundation

extension EntityDetailView {
    var currentBookUsesNativeReader: Bool {
        guard case .content(let detail) = state.phase else { return false }
        return switch BookReaderFormatPolicy.route(
            for: detail.kind,
            format: detail.bookFormat
        ) {
        case .comic, .pdf, .epub:
            true
        case .unavailable, .unsupported:
            false
        }
    }

    func openReader(command: BookReaderCommand) {
        guard case .content(let detail) = state.phase,
            dependencies.readerService != nil
        else { return }
        #if os(iOS) || os(macOS)
            let unifiedTarget = command == .resume
                ? unifiedBookReadingTarget(for: detail)
                : nil
        #else
            let unifiedTarget: BookCombinedReadingTarget? = nil
        #endif
        let progress: EntityProgressCapability? = detail.capability()
        let initialEPUBLocation: String?
        let initialEPUBProgression: Double?
        switch unifiedTarget {
        case .savedLocation(let location):
            initialEPUBLocation = location ?? progress?.location
            initialEPUBProgression = nil
        case .chapter(let location, let progression):
            initialEPUBLocation = location
            initialEPUBProgression = progression
        case .entityChapter, nil:
            initialEPUBLocation = command == .resume ? progress?.location : nil
            initialEPUBProgression = nil
        }
        readerPresentation = .init(
            detail: detail,
            command: command,
            initialEPUBLocation: initialEPUBLocation,
            initialEPUBProgression: initialEPUBProgression
        )
    }

    func loadReadingState(for detail: EntityDetail) async {
        guard readingService.isAvailable,
            [.book, .bookVolume, .bookChapter].contains(detail.kind),
            detail.bookFormat != .audio
        else {
            readingState.reset()
            return
        }

        let request = readingState.beginLoad(entityID: detail.id)
        let outcome = await readingService.load(detail: detail)
        readingState.finishLoad(outcome, request: request)
    }

    func reloadReadingState() async {
        guard case .content(let detail) = state.phase,
            readingService.isAvailable,
            [.book, .bookVolume, .bookChapter].contains(detail.kind),
            detail.bookFormat != .audio
        else {
            readingState.reset()
            return
        }

        let request = readingState.beginLoad(entityID: detail.id)
        let outcome = await readingService.reload(detailID: detail.id, kind: detail.kind)
        readingState.finishLoad(outcome, request: request)
    }

    func startReadingOver(openReaderWhenReady: Bool = false) async {
        guard case .content(let detail) = state.phase,
            let manifest = readingState.manifest,
            let request = readingState.beginMutation()
        else { return }

        let outcome = await readingService.startOver(
            detail: detail,
            readerMode: manifest.readerMode
        )
        guard readingState.finishMutation(outcome, request: request) else { return }

        dependencies.onEntityMutated()
        guard openReaderWhenReady else { return }

        if case .singleFile(let refreshedDetail) = outcome {
            presentReader(detail: refreshedDetail, command: .resume)
        } else {
            openReader(command: .resume)
        }
    }

    func presentReader(detail: EntityDetail, command: BookReaderCommand) {
        guard dependencies.readerService != nil else { return }
        readerPresentation = .init(detail: detail, command: command)
    }

    func presentReader(
        detail: EntityDetail,
        location: String,
        progression: Double? = nil,
        companionAudiobookBookID: UUID?,
        companionAudiobookTrackID: UUID?,
        companionAudiobookStartSeconds: Double = 0
    ) {
        guard dependencies.readerService != nil else { return }
        readerPresentation = .init(
            detail: detail,
            command: .read,
            initialEPUBLocation: location,
            initialEPUBProgression: progression,
            companionAudiobookBookID: companionAudiobookBookID,
            companionAudiobookTrackID: companionAudiobookTrackID,
            companionAudiobookStartSeconds: companionAudiobookStartSeconds
        )
    }

    func toggleReadingCompletion(_ status: MediaProgressStatus) async {
        guard case .content(let detail) = state.phase,
            let manifest = readingState.manifest,
            let request = readingState.beginMutation()
        else { return }

        let outcome = await readingService.toggleCompletion(
            detail: detail,
            manifest: manifest,
            status: status
        )
        if readingState.finishMutation(outcome, request: request) {
            dependencies.onEntityMutated()
        }
    }

    func primaryActions(
        for detail: EntityDetail,
        fallback: [EntityDetailAction]
    ) -> [EntityDetailAction] {
        var actions = readingState.primaryActions(
            fallback: fallback,
            entityKind: detail.kind
        )

        let videoActions = videoPrimaryActions(for: detail)
        if !videoActions.isEmpty {
            actions.removeAll { $0.id == .play || $0.id == .resume }
            actions.insert(contentsOf: videoActions, at: 0)
        }

        #if os(iOS) || os(macOS)
            if detail.kind == .collection,
                dependencies.collectionItemsLoader != nil
            {
                actions.append(
                    EntityDetailAction(
                        id: .audio,
                        title: "Audio",
                        systemImage: "music.note.list",
                        isSelected: false,
                        isPrimary: true
                    )
                )
            }
        #endif

        if detail.bookFormat == .audio {
            actions.removeAll { $0.id == .read || $0.id == .resume }
        }

        #if os(iOS) || os(macOS)
            if let presentation = audiobookPresentation(for: detail) {
                actions.append(
                    EntityDetailAction(
                        id: .listen,
                        title: presentation.actionTitle,
                        systemImage: "headphones",
                        isSelected: musicPlayer.context?.playbackOwnerEntityID == detail.id,
                        isPrimary: true
                    )
                )
            }
        #endif
        return actions
    }

    func loadAudiobook(for detail: EntityDetail) async {
        #if os(iOS) || os(macOS)
            guard let baseProjection = AudiobookPlaybackProjection(detail: detail) else {
                audiobookProjection = nil
                refreshBookChapterMappings(for: detail)
                isAudiobookLoading = false
                audiobookErrorMessage = nil
                return
            }

            audiobookProjection = baseProjection
            refreshBookChapterMappings(for: detail)
            isAudiobookLoading = true
            let hydrated = await AudiobookQueueLoader(detailLoader: dependencies.detailLoader).load(detail: detail)
            guard case .content(let currentDetail) = state.phase,
                currentDetail.id == detail.id
            else { return }
            audiobookProjection = hydrated ?? baseProjection
            refreshBookChapterMappings(for: currentDetail)
            isAudiobookLoading = false
        #else
            audiobookProjection = nil
            isAudiobookLoading = false
        #endif
    }

    func loadBookChapters(for detail: EntityDetail) async {
        #if os(iOS) || os(macOS)
            guard BookChapterContentsLoadPolicy.canLoad(detail),
                let reader = dependencies.readerService
            else {
                readableBookChapters = []
                epubReadingProgressRanges = []
                areBookChaptersLoading = false
                bookChaptersErrorMessage = nil
                refreshBookChapterMappings(for: detail)
                return
            }

            areBookChaptersLoading = true
            bookChaptersErrorMessage = nil
            defer { areBookChaptersLoading = false }
            do {
                let storedLocation = dependencies.readerLocatorStore.load(bookID: detail.id)
                let contents = try await EPUBChapterContentsService(reader: reader).load(book: detail)
                guard case .content(let currentDetail) = state.phase,
                    currentDetail.id == detail.id
                else { return }
                readableBookChapters = contents.chapters
                epubReadingProgressRanges = contents.progressRanges
                refreshBookChapterMappings(for: currentDetail)
                await promoteStoredEPUBProgressIfNeeded(
                    for: currentDetail,
                    storedLocation: storedLocation
                )
            } catch is CancellationError {
                return
            } catch {
                readableBookChapters = []
                epubReadingProgressRanges = []
                bookChaptersErrorMessage = error.localizedDescription
                refreshBookChapterMappings(for: detail)
            }
        #else
            readableBookChapters = []
            mappedBookChapters = []
            epubReadingProgressRanges = []
            areBookChaptersLoading = false
            bookChaptersErrorMessage = nil
        #endif
    }

    #if os(iOS) || os(macOS)
        func promoteStoredEPUBProgressIfNeeded(
            for detail: EntityDetail,
            storedLocation: String?
        ) async {
            guard detail.bookFormat == .epub,
                let reader = dependencies.readerService,
                let request = EPUBStoredProgressPromotionResolver().request(
                    bookID: detail.id,
                    storedLocation: storedLocation,
                    ranges: epubReadingProgressRanges,
                    mode: readingState.manifest?.readerMode
                        ?? detail.capability(EntityProgressCapability.self)?.mode
                        ?? .paged,
                    progress: detail.capability()
                )
            else { return }

            do {
                try await reader.updateReadingProgress(id: detail.id, request: request)
            } catch is CancellationError {
                return
            } catch {
                return
            }

            await loadDetail()
            guard !Task.isCancelled,
                case .content(let refreshedDetail) = state.phase,
                refreshedDetail.id == detail.id
            else { return }
            await loadReadingState(for: refreshedDetail)
            refreshBookChapterMappings(for: refreshedDetail)
            dependencies.onEntityMutated()
        }
    #endif
}
