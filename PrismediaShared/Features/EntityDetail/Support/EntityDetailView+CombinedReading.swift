#if os(iOS) || os(macOS)
import Foundation

extension EntityDetailView {
    func refreshBookChapterMappings(for detail: EntityDetail) {
        guard detail.kind == .book, detail.bookFormat == .epub else {
            mappedBookChapters = []
            return
        }
        guard !readableBookChapters.isEmpty else {
            mappedBookChapters = []
            return
        }
        mappedBookChapters = BookChapterMappingBuilder().build(
            readableChapters: readableBookChapters,
            audioTracks: audiobookProjection?.tracks ?? [],
            currentReadableID: currentReadableChapterID,
            currentAudioTrackID: currentAudiobookTrackID(for: detail)
        )
    }

    func currentAudiobookTrackID(for detail: EntityDetail) -> UUID? {
        guard let projection = audiobookProjection else { return nil }
        let isCurrent =
            musicPlayer.context?.playbackOwnerEntityID == detail.id
            && musicPlayer.context?.playbackOwnerEntityKind == .book
        if isCurrent { return musicPlayer.currentTrack?.id }
        let playback = detail.capability(EntityPlaybackCapability.self)
        guard playback?.completedAt == nil else { return nil }
        let savedResume = playback?.resumeSeconds ?? 0
        guard savedResume > 0 else { return nil }
        return projection.resumePoint(at: savedResume)?.trackID
    }

    var readingChapterProgressLabel: String? {
        guard let progress = readingState.progressPresentation else { return nil }
        if let positionLabel = progress.positionLabel { return positionLabel }
        return progress.status == .completed ? "Complete" : "\(progress.percent)% read"
    }

    func listeningChapterProgressLabel(for detail: EntityDetail) -> String? {
        guard let progress = audiobookPresentation(for: detail)?.progress else { return nil }
        if let positionLabel = progress.positionLabel { return positionLabel }
        return progress.status == .completed ? "Complete" : "\(progress.percent)% listened"
    }

    func combinedProgressPresentation(
        for detail: EntityDetail
    ) -> BookCombinedProgressPresentation? {
        guard detail.kind == .book,
            detail.bookFormat == .epub,
            audiobookProjection?.bookID == detail.id,
            let target = combinedResumeTarget(for: detail),
            readingCheckpoint(for: detail) != nil || listeningCheckpoint(for: detail) != nil
        else { return nil }
        return BookCombinedProgressPresentation(
            reading: readingState.progressPresentation,
            listening: audiobookPresentation(for: detail),
            combinedUsesReadingPosition: target.readingTarget == .savedLocation,
            isBusy: readingState.isMutating || isListeningMutating || isAudiobookLoading
        )
    }

    func combinedResumeTarget(
        for detail: EntityDetail
    ) -> BookCombinedResumeTarget? {
        BookCombinedResumeResolver().resolveContinuation(
            chapters: mappedBookChapters,
            reading: readingCheckpoint(for: detail),
            listening: listeningCheckpoint(for: detail)
        )
    }

    func currentAudiobookReadingTarget(
        for detail: EntityDetail
    ) -> BookReaderLocationTarget? {
        guard let listening = listeningCheckpoint(for: detail) else { return nil }
        return BookCombinedResumeResolver().resolveReadingTarget(
            chapters: mappedBookChapters,
            listening: listening
        )
    }

    func readingCheckpoint(for detail: EntityDetail) -> BookReadingCheckpoint? {
        let progress: EntityProgressCapability? =
            readingState.manifest?.progress
            ?? detail.capability()
        guard progress?.completedAt == nil else { return nil }
        let serialized =
            dependencies.readerLocatorStore.load(bookID: detail.id)
            ?? progress?.location
        guard let serialized,
            let location = EPUBProgressLocation(serialized: serialized)
        else { return nil }
        let publicationProgression =
            location.totalProgression
            ?? {
                guard let progress else { return 0 }
                return Double(max(0, progress.index)) / Double(max(1, progress.total))
            }()
        return BookReadingCheckpoint(
            chapterLocation: location.href,
            chapterProgression: location.resourceProgression,
            publicationProgression: publicationProgression
        )
    }

    func listeningCheckpoint(for detail: EntityDetail) -> BookListeningCheckpoint? {
        guard let projection = audiobookProjection,
            projection.bookID == detail.id,
            detail.capability(EntityPlaybackCapability.self)?.completedAt == nil
        else { return nil }
        let isCurrent =
            musicPlayer.context?.playbackOwnerEntityID == detail.id
            && musicPlayer.context?.playbackOwnerEntityKind == .book
        let resume: AudiobookResumePoint?
        if isCurrent, let track = musicPlayer.currentTrack {
            resume = AudiobookResumePoint(
                trackID: track.id,
                trackOffsetSeconds: musicPlayer.elapsedTime
            )
        } else {
            let saved = detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
            guard saved > 0 else { return nil }
            resume = projection.resumePoint(at: saved)
        }
        guard let resume else { return nil }
        let absolute = projection.absoluteTime(
            trackID: resume.trackID,
            trackOffsetSeconds: resume.trackOffsetSeconds
        )
        return BookListeningCheckpoint(
            trackID: resume.trackID,
            trackOffsetSeconds: resume.trackOffsetSeconds,
            publicationProgression: projection.totalDuration > 0
                ? absolute / projection.totalDuration
                : 0
        )
    }

    func openBookChapter(_ chapter: BookChapterMapping, combined: Bool) {
        guard case .content(let detail) = state.phase,
            case .some(.epub(let location)) = chapter.readTarget
        else { return }

        currentReadableChapterID =
            readableBookChapters.first {
                guard case .epub(let candidateLocation) = $0.target else { return false }
                return candidateLocation == location
            }?.id
        refreshBookChapterMappings(for: detail)

        if combined {
            guard
                let target = BookCombinedResumeResolver().resolveChapter(
                    chapter,
                    reading: readingCheckpoint(for: detail),
                    listening: listeningCheckpoint(for: detail)
                )
            else { return }
            let isCurrentBook =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrentBook, musicPlayer.isPlaying { musicPlayer.pause() }
            presentCombinedReader(detail: detail, target: target)
            return
        }

        presentReader(
            detail: detail,
            location: location,
            companionAudiobookBookID: nil,
            companionAudiobookTrackID: nil
        )
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
        case .savedLocation:
            readerPresentation = .init(
                detail: detail,
                command: .resume,
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
        }
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
