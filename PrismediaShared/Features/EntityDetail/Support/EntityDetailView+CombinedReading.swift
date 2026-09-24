#if os(iOS) || os(macOS)
    import Foundation

    extension EntityDetailView {
        // MARK: - Actions - Chapter Rows

        /// Rebuilds the chapter rows: the server's alignment rows when it serves them, otherwise the
        /// rows built from an older server's chapter map.
        func refreshBookChapterRows(for detail: EntityDetail) {
            guard let alignment = bookAlignmentState.alignment else {
                refreshLegacyBookChapterRows(for: detail)
                return
            }
            let tracksByID = Dictionary(
                (audiobookProjection?.tracks ?? []).map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let currentRowID = alignment.resume?.continueTarget?.rowID
            mappedBookChapters = alignment.rows.map { row in
                BookChapterMapping(row: row, tracksByID: tracksByID, isCurrentProgress: row.id == currentRowID)
            }
        }

        func bookChapterProgressLabel(for detail: EntityDetail) -> String? {
            if let progress = readingState.progressPresentation {
                if let positionLabel = progress.positionLabel { return positionLabel }
                if progress.status == .completed { return "Complete" }
                return "\(progress.percent)% read"
            }
            return audiobookPresentation(for: detail)?.progress.positionLabel
        }

        // MARK: - Actions - Progress Card

        func combinedProgressPresentation(
            for detail: EntityDetail
        ) -> BookCombinedProgressPresentation? {
            guard hasCombinedProgressCard(for: detail) else { return nil }
            guard let alignment = bookAlignmentState.alignment else {
                return legacyCombinedProgressPresentation(for: detail)
            }
            let progress: EntityProgressCapability? = detail.capability()
            return BookCombinedProgressPresentation(
                progress: progress,
                reading: readingState.progressPresentation,
                chapterLabel: mappedBookChapters.first(where: \.isCurrentProgress)?.title,
                activitySeconds: detail.capability(EntityConsumptionCapability.self)?.activeSeconds,
                isLoading: bookProgressLoadingState.isLoading,
                isBusy: readingState.isMutating || isListeningMutating || isAudiobookLoading
                    || bookProgressLoadingState.isLoading,
                actions: BookCombinedProgressActions(
                    resume: alignment.resume,
                    isCompleted: progress?.completedAt != nil
                )
            )
        }

        /// Whether the Book offers reading and listening together. The server decides from the
        /// modalities the Book has content for; older servers fall back to the local check.
        func hasCombinedProgressCard(for detail: EntityDetail) -> Bool {
            guard AudiobookPlaybackProjection(detail: detail) != nil else { return false }
            if let alignment = bookAlignmentState.alignment {
                return alignment.supportsReadingAndListening
            }
            return !bookAlignmentState.usesServerAlignment && legacyHasCombinedProgressCard(for: detail)
        }

        // MARK: - Actions - Resume Targets

        /// Where "Continue Reading" opens: the server's exact reading position (resumed against the
        /// device's own checkpoint), else the reading position it aligned from listening (opened as
        /// given). Nil resumes the reader from its own position.
        func readingResumeOpening(
            for detail: EntityDetail
        ) -> (destination: BookReadingDestination, command: BookReaderCommand)? {
            guard bookAlignmentState.usesServerAlignment else {
                return legacyReadingResumeDestination(for: detail).map { ($0, .resume) }
            }
            guard let resume = bookAlignmentState.alignment?.resume else { return nil }
            if let exact = resume.exactReading {
                return exact.destination(inWork: detail.id).map { ($0, .resume) }
            }
            return resume.switchToReading.aligned?.reading?.destination(inWork: detail.id).map { ($0, .read) }
        }

        /// The reading position aligned from the audiobook that is playing, fetched from the server
        /// after the latest listening position has been reported.
        func currentAudiobookReadingTarget(
            for detail: EntityDetail
        ) async -> BookReaderLocationTarget? {
            guard musicPlayer.currentTrack != nil else { return nil }
            guard bookAlignmentState.usesServerAlignment else {
                return legacyCurrentAudiobookReadingTarget()
            }
            guard musicPlayer.context?.playbackOwnerEntityID == detail.id else { return nil }
            musicPlayer.persistProgressHeartbeat()
            await musicPlayer.flushPendingPlaybackReports()
            await loadBookAlignment(for: detail)
            guard let reading = bookAlignmentState.alignment?.resume?.switchToReading.aligned?.reading,
                let chapterLocation = reading.chapterLocation
            else { return nil }
            return BookReaderLocationTarget(location: chapterLocation, progression: reading.chapterFraction ?? 0)
        }

        // MARK: - Actions - Opening

        func openBookChapter(_ chapter: BookChapterMapping, combined: Bool) {
            guard case .content(let detail) = state.phase,
                let readTarget = chapter.readTarget
            else { return }

            if combined {
                if bookAlignmentState.usesServerAlignment {
                    openCombinedChapter(chapter, detail: detail)
                } else {
                    openLegacyCombinedChapter(chapter, detail: detail)
                }
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

        /// Starts both sides of a chosen chapter: the server's combined position when it sits in
        /// that chapter, otherwise the start of the chapter on both sides.
        private func openCombinedChapter(_ chapter: BookChapterMapping, detail: EntityDetail) {
            if let combined = bookAlignmentState.alignment?.resume?.combined.aligned,
                combined.rowID == chapter.id,
                combined.reading != nil,
                combined.listening != nil
            {
                Task { await openCombinedReader(for: detail) }
                return
            }
            guard let track = chapter.audioTrack, let readTarget = chapter.readTarget else { return }
            pauseCompanionAudiobook(of: detail)
            presentBookReader(
                detail: detail,
                destination: readTarget.chapterStart,
                command: .read,
                companion: AudiobookResumePoint(
                    trackID: track.id,
                    trackOffsetSeconds: chapter.audioStartSeconds ?? 0
                )
            )
        }

        func openCombinedReader(for detail: EntityDetail) async {
            if musicPlayer.context?.playbackOwnerEntityID == detail.id,
                musicPlayer.context?.playbackOwnerEntityKind == .book
            {
                if musicPlayer.isPlaying { musicPlayer.pause() }
                await musicPlayer.flushPendingPlaybackReports()
            }
            await loadDetail()
            guard case .content(let refreshedDetail) = state.phase,
                refreshedDetail.id == detail.id
            else { return }
            guard bookAlignmentState.usesServerAlignment else {
                openLegacyCombinedReader(for: refreshedDetail)
                return
            }

            await loadBookAlignment(for: refreshedDetail)
            guard let combined = bookAlignmentState.alignment?.resume?.combined.aligned,
                let reading = combined.reading,
                let listening = combined.listening
            else { return }
            presentBookReader(
                detail: refreshedDetail,
                destination: reading.destination(inWork: refreshedDetail.id),
                command: .read,
                companion: listening.resumePoint
            )
        }

        /// Opens the reader at `destination`, optionally starting the audiobook alongside. A nil
        /// destination resumes the reader from its own saved position.
        func presentBookReader(
            detail: EntityDetail,
            destination: BookReadingDestination?,
            command: BookReaderCommand,
            companion: AudiobookResumePoint? = nil
        ) {
            guard dependencies.readerService != nil else { return }
            let readingUpdatedAt = detail.capability(EntityProgressCapability.self)?.readingPosition.updatedAt
            let companionBookID = companion == nil ? nil : detail.id
            switch destination {
            case .epubLocator(let location):
                readerPresentation = .init(
                    detail: detail,
                    command: command,
                    initialEPUBLocation: location,
                    initialEPUBUpdatedAt: readingUpdatedAt,
                    companionAudiobookBookID: companionBookID,
                    companionAudiobookTrackID: companion?.trackID,
                    companionAudiobookStartSeconds: companion?.trackOffsetSeconds ?? 0
                )
            case .epubChapter(let target):
                readerPresentation = .init(
                    detail: detail,
                    command: command,
                    initialEPUBLocation: target.location,
                    initialEPUBProgression: target.progression,
                    initialEPUBUpdatedAt: readingUpdatedAt,
                    companionAudiobookBookID: companionBookID,
                    companionAudiobookTrackID: companion?.trackID,
                    companionAudiobookStartSeconds: companion?.trackOffsetSeconds ?? 0
                )
            case .chapterPage(let chapterID, let pageIndex):
                Task {
                    guard let chapter = try? await dependencies.detailLoader.loadEntity(id: chapterID) else {
                        return
                    }
                    readerPresentation = .init(
                        detail: chapter,
                        command: .page(pageIndex),
                        companionAudiobookBookID: companionBookID,
                        companionAudiobookTrackID: companion?.trackID,
                        companionAudiobookStartSeconds: companion?.trackOffsetSeconds ?? 0
                    )
                }
            case nil:
                readerPresentation = .init(
                    detail: detail,
                    command: .resume,
                    initialEPUBUpdatedAt: readingUpdatedAt,
                    companionAudiobookBookID: companionBookID,
                    companionAudiobookTrackID: companion?.trackID,
                    companionAudiobookStartSeconds: companion?.trackOffsetSeconds ?? 0
                )
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

        /// Pauses this Book's audiobook before the reader takes over the combined session.
        func pauseCompanionAudiobook(of detail: EntityDetail) {
            let isCurrentBook =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrentBook, musicPlayer.isPlaying { musicPlayer.pause() }
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
                refreshBookChapterRows(for: presentation.detail)
                pendingCombinedPlaybackTask = nil
            }
        }
    }
#endif
