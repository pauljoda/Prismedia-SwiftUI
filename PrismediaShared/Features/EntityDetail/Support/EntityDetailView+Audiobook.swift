import Foundation

extension EntityDetailView {
    #if os(iOS) || os(macOS)
        func playBookChapter(_ chapter: BookChapterMapping) {
            guard case .content(let detail) = state.phase,
                let projection = audiobookProjection,
                projection.bookID == detail.id,
                let track = chapter.audioTrack
            else { return }
            play(projection, startingAt: track.id, startSeconds: 0)
        }

        func unifiedAudiobookResume(for detail: EntityDetail) -> AudiobookResumePoint? {
            if detail.bookFormat != .audio,
                let target = combinedResumeTarget(for: detail)
            {
                return AudiobookResumePoint(
                    trackID: target.audioTrackID,
                    trackOffsetSeconds: target.audioStartSeconds
                )
            }
            return BookCombinedResumeResolver().resolveAudioResume(
                chapters: mappedBookChapters,
                mappings: bookProgressMappings(for: detail),
                progress: detail.capability()
            )
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
                currentResume = unifiedAudiobookResume(for: detail).map {
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
            let progress: EntityProgressCapability? = detail.capability()
            let completed = progress?.completedAt != nil
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrent && !completed {
                musicPlayer.resume()
                return
            }
            if completed {
                Task { await startListeningOver(detail) }
                return
            }
            if let resume = unifiedAudiobookResume(for: detail) {
                play(
                    projection,
                    startingAt: resume.trackID,
                    startSeconds: resume.trackOffsetSeconds
                )
            } else {
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

        func play(
            _ projection: AudiobookPlaybackProjection,
            startingAt trackID: UUID,
            startSeconds: Double
        ) {
            musicPlayer.play(
                tracks: projection.tracks,
                startingAt: trackID,
                queueMode: .ordered,
                context: MusicPlaybackContext(
                    playbackOwnerEntityID: projection.bookID,
                    playbackOwnerTitle: projection.title,
                    playbackOwnerEntityKind: .book,
                    bookProgressMappings: currentDetail.map { bookProgressMappings(for: $0) }
                ),
                startSeconds: startSeconds
            )
        }

        func startListeningOver(_ detail: EntityDetail) async {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id,
                let playbackService = dependencies.audioPlaybackService,
                let mapping = bookProgressMappings(for: detail).first,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            do {
                await musicPlayer.flushPendingPlaybackReports()
                musicPlayer.setAudiobookCompletionState(false)
                try await playbackService.reportEntityProgress(
                    id: detail.id,
                    request: EntityProgressUpdateRequest(
                        currentEntityID: mapping.currentEntityID,
                        unit: mapping.unit,
                        index: mapping.startIndex,
                        total: mapping.total,
                        mode: mapping.mode,
                        completed: false,
                        reset: true,
                        location: nil
                    )
                )
                play(projection, startingAt: mapping.trackID, startSeconds: 0)
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
            let marksCompleted = progress.completedAt == nil
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            do {
                await musicPlayer.flushPendingPlaybackReports()
                if isCurrent { musicPlayer.setAudiobookCompletionState(marksCompleted) }
                try await playbackService.reportEntityProgress(
                    id: detail.id,
                    request: EntityProgressUpdateRequest(
                        currentEntityID: progress.currentEntityID ?? detail.id,
                        unit: progress.unit,
                        index: progress.index,
                        total: progress.total,
                        mode: progress.mode,
                        completed: marksCompleted,
                        location: progress.location
                    )
                )
                await refreshAudiobookDetail()
            } catch {
                if isCurrent { musicPlayer.setAudiobookCompletionState(!marksCompleted) }
                audiobookErrorMessage = error.localizedDescription
            }
            isListeningMutating = false
        }

        func currentAudiobookResume(for detail: EntityDetail) -> Double {
            guard let projection = audiobookProjection else { return 0 }
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            if isCurrent, let track = musicPlayer.currentTrack {
                return projection.absoluteTime(
                    trackID: track.id,
                    trackOffsetSeconds: musicPlayer.elapsedTime
                )
            }
            let progress: EntityProgressCapability? = detail.capability()
            let resume = BookCombinedResumeResolver().resolveAudioResume(
                chapters: mappedBookChapters,
                mappings: bookProgressMappings(for: detail),
                progress: progress
            )
            return resume.map {
                projection.absoluteTime(
                    trackID: $0.trackID,
                    trackOffsetSeconds: $0.trackOffsetSeconds
                )
            } ?? 0
        }

        func refreshAudiobookDetail() async {
            await loadDetail()
            if case .content(let refreshed) = state.phase {
                await loadAudiobook(for: refreshed)
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
