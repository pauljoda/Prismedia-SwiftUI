#if os(iOS) || os(macOS)
    import Foundation

    /// Book detail behavior for servers before 3.8, which keep one shared cursor and no alignment
    /// projection. The app aligns positions itself here; everything in this file is removed with
    /// the LegacyBookAlignment folder.
    extension EntityDetailView {
        // MARK: - Actions - Legacy Chapter Rows

        func refreshLegacyBookChapterRows(for detail: EntityDetail) {
            var chapters = LegacyBookChapterRowBuilder().build(
                readableChapters: readableBookChapters,
                audioTracks: audiobookProjection?.tracks ?? [],
                audioChapters: bookAlignmentState.legacyAudioChapters,
                explicitMappings: bookAlignmentState.legacyMappings
            )
            let mappings = LegacyBookProgressMappingBuilder().build(
                bookID: detail.id,
                chapters: chapters,
                readerMode: readingState.manifest?.readerMode
                    ?? detail.capability(EntityProgressCapability.self)?.readingPosition.mode,
                hasReadableRendition: detail.bookFormat != .audio
            )
            let currentChapterID = LegacyBookProgressMappingResolver().currentChapterID(
                bookID: detail.id,
                chapters: chapters,
                mappings: mappings,
                progress: detail.capability(EntityProgressCapability.self)?.readingPosition
            )
            if let index = chapters.firstIndex(where: { $0.id == currentChapterID }) {
                chapters[index].isCurrentProgress = true
            }
            mappedBookChapters = chapters
        }

        func legacyBookProgressMappings(for detail: EntityDetail) -> [PlaybackProgressMapping] {
            LegacyBookProgressMappingBuilder().build(
                bookID: detail.id,
                chapters: mappedBookChapters,
                readerMode: readingState.manifest?.readerMode
                    ?? detail.capability(EntityProgressCapability.self)?.readingPosition.mode,
                hasReadableRendition: detail.bookFormat != .audio
            )
        }

        func legacyBookChapterMappingEditorPresentation(
            for detail: EntityDetail,
            audioTracks: [MusicTrack]
        ) -> BookChapterMappingEditorPresentation? {
            guard detail.kind == .book, !readableBookChapters.isEmpty else { return nil }
            return BookChapterMappingEditorPresentation(
                readableChapters: readableBookChapters,
                audioTracks: audioTracks,
                audioChapters: bookAlignmentState.legacyAudioChapters,
                mappings: bookAlignmentState.legacyMappings,
                loadErrorMessage: bookAlignmentState.errorMessage,
                separateExplanation: nil
            )
        }

        // MARK: - Actions - Legacy Progress Card

        func legacyCombinedProgressPresentation(
            for detail: EntityDetail
        ) -> BookCombinedProgressPresentation {
            let mappingsAreReady = !legacyBookProgressMappings(for: detail).isEmpty
            let currentChapter = mappedBookChapters.first(where: \.isCurrentProgress)
            let hasUnpairedPosition =
                detail.capability(EntityProgressCapability.self) != nil
                && legacyCombinedResumeTarget(for: detail) == nil
            let firstPairedChapter = mappedBookChapters.first {
                $0.readTarget != nil && $0.audioTrack != nil
            }
            let continueEach = BookCombinedProgressActions.continueEach
            return BookCombinedProgressPresentation(
                progress: detail.capability(),
                reading: readingState.progressPresentation,
                chapterLabel: currentChapter?.title,
                activitySeconds: detail.capability(EntityConsumptionCapability.self)?.activeSeconds,
                isLoading: bookProgressLoadingState.isLoading,
                isBusy: readingState.isMutating || isListeningMutating || isAudiobookLoading
                    || bookProgressLoadingState.isLoading || !mappingsAreReady,
                actions: hasUnpairedPosition
                    ? BookCombinedProgressActions(
                        readingTitle: continueEach.readingTitle,
                        listeningTitle: continueEach.listeningTitle,
                        combinedTitle: "Start Both at First Paired Chapter",
                        combinedExplanation:
                            "Your current chapter has no paired audio. Starting both begins at \(firstPairedChapter?.title ?? "the first paired chapter")."
                    )
                    : continueEach
            )
        }

        func legacyHasCombinedProgressCard(for detail: EntityDetail) -> Bool {
            detail.kind == .book && detail.bookFormat != .audio
        }

        // MARK: - Actions - Legacy Resume

        func legacyCombinedResumeTarget(
            for detail: EntityDetail
        ) -> LegacyBookCombinedResumeTarget? {
            LegacyBookCombinedResumeResolver().resolveLatestContinuation(
                chapters: mappedBookChapters,
                mappings: legacyBookProgressMappings(for: detail),
                progress: detail.capability(EntityProgressCapability.self)
            )
        }

        func legacyReadingResumeDestination(for detail: EntityDetail) -> BookReadingDestination? {
            let target = LegacyBookCombinedResumeResolver().resolveContinuation(
                chapters: mappedBookChapters,
                mappings: legacyBookProgressMappings(for: detail),
                progress: detail.capability(EntityProgressCapability.self)?.readingPosition
            )?.readingTarget
            switch target {
            case .savedLocation(let location):
                return location.map(BookReadingDestination.epubLocator)
            case .chapter(let location, let progression):
                return .epubChapter(BookReaderLocationTarget(location: location, progression: progression))
            case .entityChapter, nil:
                return nil
            }
        }

        func legacyAudiobookResume(for detail: EntityDetail) -> AudiobookResumePoint? {
            if detail.bookFormat != .audio,
                let target = legacyCombinedResumeTarget(for: detail)
            {
                return AudiobookResumePoint(
                    trackID: target.audioTrackID,
                    trackOffsetSeconds: target.audioStartSeconds
                )
            }
            return LegacyBookCombinedResumeResolver().resolveAudioResume(
                chapters: mappedBookChapters,
                mappings: legacyBookProgressMappings(for: detail),
                progress: detail.capability()
            )
        }

        func legacyCurrentAudiobookReadingTarget() -> BookReaderLocationTarget? {
            guard let track = musicPlayer.currentTrack else { return nil }
            return LegacyBookCombinedResumeResolver().resolveReadingTarget(
                chapters: mappedBookChapters,
                trackID: track.id,
                trackOffsetSeconds: musicPlayer.elapsedTime
            )
        }

        /// Promotes an older server's absolute audiobook resume seconds into the Book cursor once.
        func promoteLegacyAudiobookProgressIfNeeded(for detail: EntityDetail) async {
            guard !bookAlignmentState.usesServerAlignment,
                detail.kind == .book,
                let projection = audiobookProjection,
                projection.bookID == detail.id,
                let legacyPlayback: EntityConsumptionCapability = detail.capability(),
                legacyPlayback.resumeSeconds > 0
            else { return }

            let mappings = legacyBookProgressMappings(for: detail)
            guard
                let request = LegacyBookProgressMappingResolver().legacyProgressPromotionRequest(
                    tracks: projection.tracks,
                    mappings: mappings,
                    legacyResumeSeconds: legacyPlayback.resumeSeconds,
                    progress: detail.capability()
                )
            else { return }

            do {
                if let playbackService = dependencies.audioPlaybackService {
                    try await playbackService.reportEntityProgress(id: detail.id, request: request)
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
            refreshBookChapterRows(for: refreshedDetail)
            dependencies.onEntityMutated()
        }

        // MARK: - Actions - Legacy Opening

        func openLegacyCombinedChapter(_ chapter: BookChapterMapping, detail: EntityDetail) {
            guard
                let target = LegacyBookCombinedResumeResolver().resolveChapter(
                    chapter,
                    mappings: legacyBookProgressMappings(for: detail),
                    progress: detail.capability(EntityProgressCapability.self)?.readingPosition
                )
            else { return }
            pauseCompanionAudiobook(of: detail)
            presentLegacyCombinedReader(detail: detail, target: target)
        }

        func openLegacyCombinedReader(for detail: EntityDetail) {
            refreshBookChapterRows(for: detail)
            let target =
                legacyCombinedResumeTarget(for: detail)
                ?? LegacyBookCombinedResumeResolver().resolveContinuation(
                    chapters: mappedBookChapters,
                    mappings: legacyBookProgressMappings(for: detail),
                    progress: nil
                )
            guard let target else { return }
            presentLegacyCombinedReader(detail: detail, target: target)
        }

        private func presentLegacyCombinedReader(
            detail: EntityDetail,
            target: LegacyBookCombinedResumeTarget
        ) {
            let command: BookReaderCommand
            if case .savedLocation = target.readingTarget {
                command = .resume
            } else {
                command = .read
            }
            presentBookReader(
                detail: detail,
                destination: target.readingTarget.destination,
                command: command,
                companion: AudiobookResumePoint(
                    trackID: target.audioTrackID,
                    trackOffsetSeconds: target.audioStartSeconds
                )
            )
        }

        // MARK: - Actions - Legacy Listening Reports

        /// The first mapped audio part and the cursor report that restarts listening from it.
        func legacyStartListeningOverReport(
            for detail: EntityDetail
        ) -> (trackID: UUID, request: EntityProgressUpdateRequest)? {
            guard let mapping = legacyBookProgressMappings(for: detail).first else { return nil }
            return (
                mapping.itemID,
                EntityProgressUpdateRequest(
                    currentEntityID: mapping.currentEntityID,
                    unit: mapping.unit,
                    index: mapping.startIndex,
                    total: mapping.total,
                    mode: mapping.mode,
                    completed: false,
                    reset: true,
                    location: nil,
                    activityKind: .listening,
                    listening: BookListeningPositionRequest(
                        trackEntityID: mapping.itemID,
                        markerID: mapping.audioMarkerID,
                        offsetSeconds: 0
                    )
                )
            )
        }

        /// The shared cursor echoed back with a new completion state.
        func legacyListeningCompletionReport(
            for detail: EntityDetail,
            progress: EntityProgressCapability,
            completed: Bool
        ) -> EntityProgressUpdateRequest {
            EntityProgressUpdateRequest(
                currentEntityID: progress.currentEntityID ?? detail.id,
                unit: progress.unit,
                index: progress.index,
                total: progress.total,
                mode: progress.mode,
                completed: completed,
                location: progress.location,
                activityKind: .listening
            )
        }
    }
#endif
