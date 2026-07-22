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

        func audiobookPresentation(for detail: EntityDetail) -> AudiobookPlaybackPresentation? {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id
            else { return nil }
            let playback = detail.capability(EntityPlaybackCapability.self)
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
                currentResume = playback?.resumeSeconds ?? 0
            }
            return AudiobookPlaybackPresentation(
                totalDuration: projection.totalDuration,
                partCount: projection.tracks.count,
                resumeSeconds: currentResume,
                isCompleted: playback?.completedAt != nil,
                isCurrentAudiobook: isCurrent,
                isPlaying: musicPlayer.isPlaying,
                isBusy: isListeningMutating || isAudiobookLoading
            )
        }

        func beginListening(to detail: EntityDetail) {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id
            else { return }
            let completed = detail.capability(EntityPlaybackCapability.self)?.completedAt != nil
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
            let savedResume = detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
            play(projection, resumeSeconds: savedResume)
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
                    playbackOwnerEntityKind: .book
                ),
                startSeconds: startSeconds
            )
        }

        func startListeningOver(_ detail: EntityDetail) async {
            guard let projection = audiobookProjection,
                projection.bookID == detail.id,
                let playbackService = dependencies.audioPlaybackService,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            do {
                await musicPlayer.flushPendingPlaybackReports()
                musicPlayer.setAudiobookCompletionState(false)
                try await playbackService.updateEntityPlayback(
                    id: detail.id,
                    resumeSeconds: 0,
                    completed: false
                )
                play(projection, resumeSeconds: 0)
                await refreshAudiobookDetail()
            } catch {
                audiobookErrorMessage = error.localizedDescription
            }
            isListeningMutating = false
        }

        func toggleListeningCompletion(_ detail: EntityDetail) async {
            guard let presentation = audiobookPresentation(for: detail),
                let playbackService = dependencies.audioPlaybackService,
                !isListeningMutating
            else { return }
            isListeningMutating = true
            audiobookErrorMessage = nil
            let marksCompleted = presentation.progress.status != .completed
            let isCurrent =
                musicPlayer.context?.playbackOwnerEntityID == detail.id
                && musicPlayer.context?.playbackOwnerEntityKind == .book
            do {
                await musicPlayer.flushPendingPlaybackReports()
                if isCurrent { musicPlayer.setAudiobookCompletionState(marksCompleted) }
                try await playbackService.updateEntityPlayback(
                    id: detail.id,
                    resumeSeconds: presentation.progress.status == .completed
                        ? 0
                        : currentAudiobookResume(for: detail),
                    completed: marksCompleted
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
            return detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
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

    func pauseCompanionAudiobook(
        for presentation: EntityReaderPresentation?
    ) {
        #if os(iOS) || os(macOS)
            guard let bookID = presentation?.companionAudiobookBookID,
                musicPlayer.context?.playbackOwnerEntityID == bookID,
                musicPlayer.context?.playbackOwnerEntityKind == .book,
                musicPlayer.isPlaying
            else { return }
            musicPlayer.pause()
        #endif
    }
}
