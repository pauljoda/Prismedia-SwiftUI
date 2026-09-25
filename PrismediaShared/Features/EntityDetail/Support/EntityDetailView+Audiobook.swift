import Foundation

extension EntityDetailView {
    #if os(iOS) || os(macOS)
        /// Plays a chapter: the saved listening position when this chapter holds it, otherwise the
        /// start of the chapter's audio window.
        func playBookChapter(_ chapter: BookChapterMapping) {
            guard case .content(let detail) = state.phase,
                let projection = audiobookProjection,
                projection.bookID == detail.id,
                let track = chapter.audioTrack
            else { return }
            if let resume = bookAlignmentState.alignment?.resume,
                resume.listeningRowID == chapter.id,
                let exact = resume.exactListening
            {
                play(projection, startingAt: exact.trackEntityID, startSeconds: exact.resumePoint.trackOffsetSeconds)
                return
            }
            play(projection, startingAt: track.id, startSeconds: chapter.audioStartSeconds ?? 0)
        }

        /// Where "Continue Listening" starts: the server's exact listening position, else, for a
        /// Linked Book, the position it aligned from reading. Unknown while the server's progress
        /// contract is undecided.
        func unifiedAudiobookResume(for detail: EntityDetail) -> AudiobookResumePoint? {
            switch bookAlignmentState.contract {
            case .legacyCursor:
                return legacyAudiobookResume(for: detail)
            case .serverAlignment:
                guard let alignment = bookAlignmentState.alignment, let resume = alignment.resume else { return nil }
                if let exact = resume.exactListening { return exact.resumePoint }
                return alignment.isLinked ? resume.switchToListening.aligned?.listening?.resumePoint : nil
            case nil:
                return nil
            }
        }

        func audiobookPresentation(for detail: EntityDetail) -> AudiobookPlaybackPresentation? {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id
            else { return nil }
            let progress: EntityProgressCapability? = detail.capability()
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            let currentResume: Double
            if isCurrent, let currentTrack = musicPlayer.currentTrack {
                currentResume = projection.absoluteTime(
                    trackID: currentTrack.id,
                    trackOffsetSeconds: musicPlayer.elapsedTime
                )
            } else {
                currentResume =
                    unifiedAudiobookResume(for: detail).map {
                        projection.absoluteTime(
                            trackID: $0.trackID,
                            trackOffsetSeconds: $0.trackOffsetSeconds
                        )
                    } ?? 0
            }
            return AudiobookPlaybackPresentation(
                totalDuration: projection.totalDuration,
                partCount: projection.tracks.count,
                resumeSeconds: currentResume,
                isCompleted: progress?.completedAt != nil,
                isCurrentAudiobook: isCurrent,
                isPlaying: musicPlayer.isPlaying,
                isBusy: isListeningMutating || isAudiobookLoading
            )
        }

        func beginListening(to detail: EntityDetail) {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id
            else { return }
            guard bookAlignmentState.contract != nil else {
                Task { await beginListeningOnceContractIsDecided(to: detail) }
                return
            }
            let progress: EntityProgressCapability? = detail.capability()
            let completed = progress?.completedAt != nil
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            let decision = AudiobookContinuationPlanner().decision(
                isCompleted: completed,
                isCurrentAudiobook: isCurrent,
                requiresCanonicalProgress: detail.bookFormat != .audio,
                canonicalResume: unifiedAudiobookResume(for: detail)
            )
            switch decision {
            case .startOver:
                Task { await startListeningOver(detail) }
            case .resumeCurrentPlayer:
                musicPlayer.resume()
            case .play(let resume):
                play(
                    projection,
                    startingAt: resume.trackID,
                    startSeconds: resume.trackOffsetSeconds
                )
            case .playFromBeginning:
                play(projection, resumeSeconds: 0)
            }
        }

        func play(_ projection: AudiobookPlaybackProjection, resumeSeconds: Double) {
            guard let resume = projection.resumePoint(at: resumeSeconds) else { return }
            play(
                projection,
                startingAt: resume.trackID,
                startSeconds: resume.trackOffsetSeconds
            )
        }

        /// Reads the server's progress contract, then listens with the resume it reveals.
        private func beginListeningOnceContractIsDecided(to detail: EntityDetail) async {
            guard !isListeningMutating else { return }
            isListeningMutating = true
            let decided = await decideBookAlignmentContractIfNeeded(for: detail)
            isListeningMutating = false
            guard decided else { return }
            beginListening(to: detail)
        }

        /// Starts the player reporting under the known progress contract: exact listening
        /// checkpoints on 3.8+ servers, client-built cursor mappings on older ones. The player is
        /// never started while the contract is undecided, so no report reaches the track entities.
        func play(
            _ projection: AudiobookPlaybackProjection,
            startingAt trackID: UUID,
            startSeconds: Double
        ) {
            guard let contract = bookAlignmentState.contract else { return }
            let context: MusicPlaybackContext
            switch contract {
            case .serverAlignment:
                context = MusicPlaybackContext(
                    playbackOwnerEntityID: projection.bookID,
                    playbackOwnerTitle: projection.title,
                    playbackOwnerEntityKind: .book,
                    progressModality: .listening,
                    preservesQueueOrder: projection.preservesQueueOrder,
                    supportsPlaybackRate: projection.supportsPlaybackRate
                )
            case .legacyCursor:
                context = MusicPlaybackContext(
                    playbackOwnerEntityID: projection.bookID,
                    playbackOwnerTitle: projection.title,
                    playbackOwnerEntityKind: .book,
                    progressMappings: currentDetail.map { legacyBookProgressMappings(for: $0) },
                    preservesQueueOrder: projection.preservesQueueOrder,
                    supportsPlaybackRate: projection.supportsPlaybackRate
                )
            }
            musicPlayer.play(
                tracks: projection.tracks,
                startingAt: trackID,
                queueMode: .ordered,
                context: context,
                startSeconds: startSeconds
            )
        }

        /// Starts listening over from the first part; the reading position is untouched.
        func startListeningOver(_ detail: EntityDetail) async {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id,
                let playbackService = dependencies.audioPlaybackService,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            guard await decideBookAlignmentContractIfNeeded(for: detail),
                let restart = listeningRestartReport(for: detail, projection: projection)
            else {
                isListeningMutating = false
                return
            }
            do {
                await musicPlayer.flushPendingPlaybackReports()
                musicPlayer.setMappedProgressCompletionState(false)
                try await playbackService.reportEntityProgress(id: detail.id, request: restart.request)
                play(projection, startingAt: restart.trackID, startSeconds: 0)
                await refreshAudiobookDetail()
            } catch {
                audiobookErrorMessage = error.localizedDescription
            }
            isListeningMutating = false
        }

        func toggleListeningCompletion(_ detail: EntityDetail) async {
            guard let progress: EntityProgressCapability = detail.capability(),
                let playbackService = dependencies.audioPlaybackService,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            guard await decideBookAlignmentContractIfNeeded(for: detail),
                let request = listeningCompletionReport(
                    for: detail,
                    progress: progress,
                    completed: progress.completedAt == nil
                )
            else {
                isListeningMutating = false
                return
            }
            let marksCompleted = progress.completedAt == nil
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            do {
                await musicPlayer.flushPendingPlaybackReports()
                if isCurrent { musicPlayer.setMappedProgressCompletionState(marksCompleted) }
                try await playbackService.reportEntityProgress(id: detail.id, request: request)
                await refreshAudiobookDetail()
            } catch {
                if isCurrent { musicPlayer.setMappedProgressCompletionState(!marksCompleted) }
                audiobookErrorMessage = error.localizedDescription
            }
            isListeningMutating = false
        }

        /// The report that restarts listening from the first part, and the part to play. Nil while
        /// the server's progress contract is undecided.
        private func listeningRestartReport(
            for detail: EntityDetail,
            projection: AudiobookPlaybackProjection
        ) -> (trackID: UUID, request: EntityProgressUpdateRequest)? {
            switch bookAlignmentState.contract {
            case .legacyCursor:
                return legacyStartListeningOverReport(for: detail)
            case .serverAlignment:
                guard let firstTrack = projection.tracks.first else { return nil }
                return (
                    firstTrack.id,
                    .listening(
                        BookListeningPositionRequest(trackEntityID: firstTrack.id, markerID: nil, offsetSeconds: 0),
                        completed: false,
                        reset: true
                    )
                )
            case nil:
                return nil
            }
        }

        /// The report that marks the audiobook listened or not; the exact listening position rides
        /// along unchanged. Nil while the server's progress contract is undecided.
        private func listeningCompletionReport(
            for detail: EntityDetail,
            progress: EntityProgressCapability,
            completed: Bool
        ) -> EntityProgressUpdateRequest? {
            switch bookAlignmentState.contract {
            case .legacyCursor:
                return legacyListeningCompletionReport(for: detail, progress: progress, completed: completed)
            case nil:
                return nil
            case .serverAlignment:
                break
            }
            let position: BookListeningPositionRequest
            if let exact = bookAlignmentState.alignment?.resume?.exactListening {
                position = BookListeningPositionRequest(
                    trackEntityID: exact.trackEntityID,
                    markerID: exact.markerID,
                    offsetSeconds: max(0, exact.offsetSeconds)
                )
            } else if let checkpoint = progress.checkpoint(for: .listening) {
                position = BookListeningPositionRequest(
                    trackEntityID: checkpoint.positionEntityID,
                    markerID: checkpoint.markerID,
                    offsetSeconds: max(0, checkpoint.offsetSeconds ?? Double(checkpoint.index))
                )
            } else if let firstTrack = audiobookProjection?.tracks.first {
                position = BookListeningPositionRequest(trackEntityID: firstTrack.id, markerID: nil, offsetSeconds: 0)
            } else {
                return nil
            }
            return .listening(position, completed: completed)
        }

        func refreshAudiobookDetail() async {
            await loadDetail()
            if case .content(let refreshed) = state.phase {
                await loadAudiobook(for: refreshed)
                if !bookAlignmentState.usesLegacyAlignment {
                    // Resume targets are server-owned, and an undecided contract gets another read.
                    await loadBookAlignment(for: refreshed)
                }
            }
            dependencies.onEntityMutated()
        }
    #endif

    func companionPlayer(
        for presentation: EntityReaderPresentation
    ) -> MusicPlayerController? {
        #if os(iOS) || os(macOS)
            guard presentation.companionAudiobookBookID != nil else { return nil }
            return musicPlayer
        #else
            return nil
        #endif
    }

    func finishCompanionAudiobookPlayback(
        for presentation: EntityReaderPresentation?
    ) async {
        #if os(iOS) || os(macOS)
            guard let bookID = presentation?.companionAudiobookBookID,
                musicPlayer.context?.playbackOwnerEntityID == bookID,
                musicPlayer.context?.playbackOwnerEntityKind == .book
            else { return }
            if musicPlayer.isPlaying { musicPlayer.pause() }
            await musicPlayer.flushPendingPlaybackReports()
        #endif
    }
}
