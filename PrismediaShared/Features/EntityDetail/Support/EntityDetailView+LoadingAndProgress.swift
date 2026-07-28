import SwiftUI

extension EntityDetailView {
    func reloadCollectionMembers() async {
        guard case .content(let detail) = state.phase else { return }
        await loadCollectionMembers(for: detail, force: true)
    }

    func loadCollectionMembers(for detail: EntityDetail, force: Bool = false) async {
        guard detail.kind == .collection else {
            collectionMembersState.reset()
            return
        }
        guard
            let request = collectionMembersState.beginLoad(
                collectionID: detail.id,
                force: force
            )
        else { return }

        let outcome = await collectionMembersService.load(collectionID: detail.id)
        collectionMembersState.finishLoad(outcome, request: request)
    }

    func loadDetailIfNeeded() async {
        guard state.needsLoadOnAppearance else { return }
        videoPlaybackPreparation.reset()
        await loadDetail(preservingContent: false)
    }

    func loadDetail(
        preservingContent: Bool = true
    ) async {
        guard let request = state.beginLoad(preservingContent: preservingContent) else { return }
        let outcome = await service.load(id: link.entityID, kind: link.kind)
        state.finishLoad(outcome, request: request)
        #if os(iOS) || os(macOS)
            guard case .content(let detail) = state.phase else { return }
            await refreshIdentifyAvailability(for: detail)
        #endif
    }

    func refreshDetailContent() async {
        await loadDetail()
        #if os(iOS) || os(macOS)
            await refreshAcquisitionStatus()
        #endif
        guard case .content(let refreshedDetail) = state.phase else { return }
        await loadVideoProgress(for: refreshedDetail)
        await loadReadingState(for: refreshedDetail)
        await loadCollectionMembers(for: refreshedDetail, force: true)
        await loadAudiobook(for: refreshedDetail)
        await loadBookChapters(for: refreshedDetail)
    }

    func loadVideoProgress(for detail: EntityDetail) async {
        guard detail.kind == .videoSeries || detail.kind == .videoSeason else {
            if videoProgressEpisode != nil {
                videoProgressEpisode = nil
            }
            if videoProgressErrorMessage != nil {
                videoProgressErrorMessage = nil
            }
            return
        }

        do {
            let nextEpisode = try await videoProgressService.loadProgressEpisode(for: detail)
            if videoProgressEpisode != nextEpisode {
                videoProgressEpisode = nextEpisode
            }
            if videoProgressErrorMessage != nil {
                videoProgressErrorMessage = nil
            }
        } catch is CancellationError {
            return
        } catch {
            if videoProgressEpisode != nil {
                videoProgressEpisode = nil
            }
            let nextMessage = error.localizedDescription
            if videoProgressErrorMessage != nextMessage {
                videoProgressErrorMessage = nextMessage
            }
        }
    }

    func videoProgressCardPresentation(
        for detail: EntityDetail
    ) -> MediaProgressCardPresentation? {
        guard let progress: EntityProgressCapability = detail.capability(),
            let videoProgress = VideoContainerProgressPresentation(
                progress: progress,
                episode: videoProgressEpisode.map(VideoProgressEpisode.init(detail:))
            )
        else { return nil }
        return MediaProgressCardPresentation(
            videoProgress: videoProgress,
            isBusy: isVideoProgressMutating,
            canMutate: videoProgressService.canMutate
        )
    }

    func continueVideoProgress() {
        guard let episode = videoProgressEpisode,
            let playbackLink = VideoProgressPlaybackRoute.link(for: episode)
        else { return }
        if playbackLink.entityID == state.detail?.id {
            beginPlayback(playbackLink)
        } else {
            advancedEntityLink = playbackLink
        }
    }

    func toggleVideoProgressCompletion() async {
        guard !isVideoProgressMutating,
            let detail = state.detail,
            let progress: EntityProgressCapability = detail.capability(),
            let presentation = VideoContainerProgressPresentation(
                progress: progress,
                episode: videoProgressEpisode.map(VideoProgressEpisode.init(detail:))
            )
        else { return }

        isVideoProgressMutating = true
        videoProgressErrorMessage = nil
        defer { isVideoProgressMutating = false }

        do {
            let updated = try await videoProgressService.toggleCompletion(
                container: detail,
                presentation: presentation
            )
            state.replaceContent(with: updated)
            videoProgressEpisode = try await videoProgressService.loadProgressEpisode(for: updated)
            dependencies.onEntityMutated()
        } catch is CancellationError {
            return
        } catch {
            videoProgressErrorMessage = error.localizedDescription
        }
    }

    func startVideoProgressOver() async {
        guard !isVideoProgressMutating, let detail = state.detail else { return }

        isVideoProgressMutating = true
        videoProgressErrorMessage = nil
        defer { isVideoProgressMutating = false }

        do {
            let updated = try await videoProgressService.startOver(container: detail)
            state.replaceContent(with: updated)
            videoProgressEpisode = try await videoProgressService.loadProgressEpisode(for: updated)
            dependencies.onEntityMutated()
        } catch is CancellationError {
            return
        } catch {
            videoProgressErrorMessage = error.localizedDescription
        }
    }

    func refreshAfterAcquisitionMutation() async {
        dependencies.onEntityMutated()
        await loadDetail()
        #if os(iOS) || os(macOS)
            await refreshAcquisitionStatus()
        #endif
    }

    #if os(iOS) || os(macOS)
        func refreshAcquisitionStatus() async {
            guard let acquisitionService = dependencies.acquisitionService else { return }
            do {
                let monitorState = try await acquisitionService.loadState(entityID: link.entityID)
                guard !Task.isCancelled else { return }
                acquisitionStatus = monitorState.latestAcquisition?.status
                    ?? monitorState.monitor?.acquisitionStatus
            } catch is CancellationError {
                return
            } catch {
                // The detail and its navigation thumbnail remain usable when this
                // best-effort acquisition status refresh is temporarily unavailable.
            }
        }
    #endif

    func handlePrunedEntity() {
        videoPlaybackSession?.inlinePlaybackWillNavigate()
        dependencies.onEntityMutated()
        dismiss()
    }

    func updateRating(_ value: Int?) async -> Bool {
        await performMutation(.rating(value))
    }

    func toggleFlag(_ action: EntityDetailActionID) async -> Bool {
        let mutation: EntityDetailMutation?
        switch action {
        case .favorite:
            mutation = state.favoriteToggleMutation
        case .organized:
            mutation = state.organizedToggleMutation
        default:
            mutation = nil
        }
        guard let mutation else { return false }
        return await performMutation(mutation)
    }

    func performMutation(_ mutation: EntityDetailMutation) async -> Bool {
        guard let request = state.beginMutation(canMutate: service.canMutate) else {
            return false
        }

        let saveOutcome = await service.save(mutation, id: link.entityID)
        guard state.finishMutationSave(saveOutcome, request: request) else {
            return false
        }

        let refreshOutcome = await service.load(id: link.entityID, kind: link.kind)
        state.finishMutationRefresh(refreshOutcome, request: request)
        return true
    }
}
