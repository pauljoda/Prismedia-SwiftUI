#if os(iOS) || os(macOS)
import Foundation

extension EntityDetailView {
    func refreshBookChapterMappings(for detail: EntityDetail) {
        var chapters = BookChapterMappingBuilder().build(
            readableChapters: readableBookChapters,
            audioTracks: audiobookProjection?.tracks ?? []
        )
        let mappings = BookProgressMappingBuilder().build(
            bookID: detail.id,
            chapters: chapters,
            readerMode: readingState.manifest?.readerMode
                ?? detail.capability(EntityProgressCapability.self)?.mode,
            hasReadableRendition: detail.bookFormat != .audio
        )
        let currentChapterID = BookProgressMappingResolver().currentChapterID(
            bookID: detail.id,
            chapters: chapters,
            mappings: mappings,
            progress: detail.capability()
        )
        if let index = chapters.firstIndex(where: { $0.id == currentChapterID }) {
            chapters[index].isCurrentProgress = true
        }
        mappedBookChapters = chapters
    }

    func bookProgressMappings(for detail: EntityDetail) -> [BookProgressTrackMapping] {
        BookProgressMappingBuilder().build(
            bookID: detail.id,
            chapters: mappedBookChapters,
            readerMode: readingState.manifest?.readerMode
                ?? detail.capability(EntityProgressCapability.self)?.mode,
            hasReadableRendition: detail.bookFormat != .audio
        )
    }

    func bookChapterProgressLabel(for detail: EntityDetail) -> String? {
        if let progress = readingState.progressPresentation {
            if let positionLabel = progress.positionLabel { return positionLabel }
            if progress.status == .completed { return "Complete" }
            return "\(progress.percent)% read"
        }
        return audiobookPresentation(for: detail)?.progress.positionLabel
    }

    func combinedProgressPresentation(
        for detail: EntityDetail
    ) -> BookCombinedProgressPresentation? {
        guard detail.kind == .book,
            detail.bookFormat != .audio,
            AudiobookPlaybackProjection(detail: detail) != nil
        else { return nil }
        let mappingsAreReady = !bookProgressMappings(for: detail).isEmpty
        let currentChapter = mappedBookChapters.first(where: \.isCurrentProgress)
        return BookCombinedProgressPresentation(
            progress: detail.capability(),
            reading: readingState.progressPresentation,
            chapterLabel: currentChapter?.title,
            activitySeconds: detail.capability(EntityConsumptionCapability.self)?.activeSeconds,
            isLoading: bookProgressLoadingState.isLoading,
            isBusy: readingState.isMutating || isListeningMutating || isAudiobookLoading
                || bookProgressLoadingState.isLoading || !mappingsAreReady
        )
    }

    func combinedResumeTarget(
        for detail: EntityDetail
    ) -> BookCombinedResumeTarget? {
        return BookCombinedResumeResolver().resolveContinuation(
            chapters: mappedBookChapters,
            mappings: bookProgressMappings(for: detail),
            progress: detail.capability()
        )
    }

    func unifiedBookReadingTarget(
        for detail: EntityDetail
    ) -> BookCombinedReadingTarget? {
        combinedResumeTarget(for: detail)?.readingTarget
    }

    func promoteLegacyAudiobookProgressIfNeeded(for detail: EntityDetail) async {
        guard detail.kind == .book,
            let projection = audiobookProjection,
            projection.bookID == detail.id,
            let legacyPlayback: EntityConsumptionCapability = detail.capability(),
            legacyPlayback.resumeSeconds > 0
        else { return }

        let mappings = bookProgressMappings(for: detail)
        guard let request = BookProgressMappingResolver().legacyProgressPromotionRequest(
            tracks: projection.tracks,
            mappings: mappings,
            legacyResumeSeconds: legacyPlayback.resumeSeconds,
            progress: detail.capability()
        ) else { return }

        do {
            if let playbackService = dependencies.audioPlaybackService {
                try await playbackService.updateEntityProgress(id: detail.id, request: request)
            } else if let readerService = dependencies.readerService {
                try await readerService.updateReadingProgress(id: detail.id, request: request)
            } else {
                return
            }
        } catch is CancellationError {
            return
        } catch {
            // A later refresh can retry the idempotent, forward-only promotion.
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

    func currentAudiobookReadingTarget(
        for detail: EntityDetail
    ) -> BookReaderLocationTarget? {
        guard let track = musicPlayer.currentTrack else { return nil }
        return BookCombinedResumeResolver().resolveReadingTarget(
            chapters: mappedBookChapters,
            trackID: track.id,
            trackOffsetSeconds: musicPlayer.elapsedTime
        )
    }

    func openBookChapter(_ chapter: BookChapterMapping, combined: Bool) {
        guard case .content(let detail) = state.phase,
            let readTarget = chapter.readTarget
        else { return }

        if combined {
            guard
                let target = BookCombinedResumeResolver().resolveChapter(
                    chapter,
                    mappings: bookProgressMappings(for: detail),
                    progress: detail.capability()
                )
            else { return }
            let isCurrentBook =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrentBook, musicPlayer.isPlaying { musicPlayer.pause() }
            presentCombinedReader(detail: detail, target: target)
            return
        }

        switch readTarget {
        case .epub(let location):
            presentReader(
                detail: detail,
                location: location,
                companionAudiobookBookID: nil,
                companionAudiobookTrackID: nil
            )
        case .entityChapter(let chapterID):
            Task { await presentEntityChapterReader(chapterID: chapterID, command: .read) }
        }
    }

    func openCombinedReader(for detail: EntityDetail) {
        guard let target = combinedResumeTarget(for: detail) else { return }
        let isCurrentBook =
            musicPlayer.context?.playbackOwnerEntityID == detail.id
            && musicPlayer.context?.playbackOwnerEntityKind == .book
        if isCurrentBook, musicPlayer.isPlaying { musicPlayer.pause() }
        presentCombinedReader(detail: detail, target: target)
    }

    func presentCombinedReader(
        detail: EntityDetail,
        target: BookCombinedResumeTarget
    ) {
        switch target.readingTarget {
        case .savedLocation(let location):
            readerPresentation = .init(
                detail: detail,
                command: .resume,
                initialEPUBLocation: location,
                companionAudiobookBookID: detail.id,
                companionAudiobookTrackID: target.audioTrackID,
                companionAudiobookStartSeconds: target.audioStartSeconds
            )
        case .chapter(let location, let progression):
            presentReader(
                detail: detail,
                location: location,
                progression: progression,
                companionAudiobookBookID: detail.id,
                companionAudiobookTrackID: target.audioTrackID,
                companionAudiobookStartSeconds: target.audioStartSeconds
            )
        case .entityChapter(let chapterID):
            Task {
                guard let chapter = try? await dependencies.detailLoader.loadEntity(id: chapterID) else {
                    return
                }
                readerPresentation = .init(
                    detail: chapter,
                    command: .read,
                    companionAudiobookBookID: detail.id,
                    companionAudiobookTrackID: target.audioTrackID,
                    companionAudiobookStartSeconds: target.audioStartSeconds
                )
            }
        }
    }

    func presentEntityChapterReader(
        chapterID: UUID,
        command: BookReaderCommand
    ) async {
        guard let chapter = try? await dependencies.detailLoader.loadEntity(id: chapterID) else {
            return
        }
        presentReader(detail: chapter, command: command)
    }

    func beginCombinedPlayback(for presentation: EntityReaderPresentation) {
        pendingCombinedPlaybackTask?.cancel()
        pendingCombinedPlaybackTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                return
            }
            guard !Task.isCancelled,
                readerPresentation == presentation,
                let bookID = presentation.companionAudiobookBookID,
                let trackID = presentation.companionAudiobookTrackID,
                let projection = audiobookProjection,
                projection.bookID == bookID,
                projection.tracks.contains(where: { $0.id == trackID })
            else { return }

            play(
                projection,
                startingAt: trackID,
                startSeconds: presentation.companionAudiobookStartSeconds
            )
            refreshBookChapterMappings(for: presentation.detail)
            pendingCombinedPlaybackTask = nil
        }
    }
}
#endif
