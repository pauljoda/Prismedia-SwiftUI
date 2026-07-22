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
        readerPresentation = .init(detail: detail, command: command)
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
        if readingState.progressPresentation?.canResume == true {
            actions.removeAll { $0.id == .read || $0.id == .resume }
        }
        if detail.bookFormat == .audio {
            actions.removeAll { $0.id == .read || $0.id == .resume }
        }

        #if os(iOS) || os(macOS)
            if let presentation = audiobookPresentation(for: detail),
                presentation.actionTitle != "Continue Listening"
            {
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
            guard detail.kind == .book,
                detail.bookFormat == .epub,
                let reader = dependencies.readerService
            else {
                readableBookChapters = []
                mappedBookChapters = []
                currentReadableChapterID = nil
                areBookChaptersLoading = false
                bookChaptersErrorMessage = nil
                return
            }

            areBookChaptersLoading = true
            bookChaptersErrorMessage = nil
            defer { areBookChaptersLoading = false }
            do {
                let contents = try await EPUBChapterContentsService(reader: reader).load(
                    book: detail,
                    storedLocation: dependencies.readerLocatorStore.load(bookID: detail.id)
                )
                guard case .content(let currentDetail) = state.phase,
                    currentDetail.id == detail.id
                else { return }
                readableBookChapters = contents.chapters
                if detail.capability(EntityProgressCapability.self)?.completedAt != nil {
                    currentReadableChapterID = nil
                } else if let currentChapterID = contents.currentChapterID {
                    currentReadableChapterID = currentChapterID
                } else if !contents.chapters.contains(where: { $0.id == currentReadableChapterID }) {
                    currentReadableChapterID = nil
                }
                refreshBookChapterMappings(for: currentDetail)
            } catch is CancellationError {
                return
            } catch {
                readableBookChapters = []
                mappedBookChapters = []
                currentReadableChapterID = nil
                bookChaptersErrorMessage = error.localizedDescription
            }
        #else
            readableBookChapters = []
            mappedBookChapters = []
            currentReadableChapterID = nil
            areBookChaptersLoading = false
            bookChaptersErrorMessage = nil
        #endif
    }
}
