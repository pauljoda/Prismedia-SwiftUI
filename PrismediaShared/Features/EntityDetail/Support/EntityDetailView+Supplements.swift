import SwiftUI

extension EntityDetailView {
    var activePlaybackOwnerLink: EntityLink? {
        if let thumbnailPlaybackLink { return thumbnailPlaybackLink }
        if suppressesRoutePlayback { return nil }
        return link
    }

    func ratingDidChange(_ value: Int?) {
        Task {
            if await updateRating(value) {
                dependencies.onEntityMutated()
            }
        }
    }

    func visibleChildGroups(in detail: EntityDetail) -> [EntityGroup] {
        switch detail.kind {
        case .book where detail.bookFormat == .epub && AudiobookPlaybackProjection(detail: detail) != nil:
            detail.childrenByKind.filter { $0.kind != .audioTrack }
        case .movie:
            detail.childrenByKind.filter { $0.kind != .video }
        default:
            detail.childrenByKind
        }
    }

    @ViewBuilder
    func childGroupsView(for detail: EntityDetail) -> some View {
        if GalleryChildGroupsPresentation.isAvailable(for: detail.kind) {
            GalleryDetailChildGroupsView(
                galleryID: detail.id,
                groups: detail.childrenByKind,
                horizontalPadding: detailHorizontalPadding,
                dependencies: dependencies
            )
        } else if detail.kind == .videoSeason {
            EntityDetailChildGroupsView(
                groups: visibleChildGroups(in: detail),
                horizontalPadding: detailHorizontalPadding,
                onPrimaryAction: beginThumbnailPlayback
            )
        } else {
            EntityDetailChildGroupsView(
                groups: visibleChildGroups(in: detail),
                horizontalPadding: detailHorizontalPadding
            )
        }
    }

    @ViewBuilder
    func mainSupplementView(for detail: EntityDetail) -> some View {
        if let referencePresentation = EntityDetailReferencedContentPresentation(detail: detail),
            let entityGridLoader = dependencies.entityGridLoader
        {
            EntityDetailReferencedContentView(
                presentation: referencePresentation,
                loader: entityGridLoader
            )
            .padding(.horizontal, detailHorizontalPadding)
        }

        if detail.kind == .collection {
            CollectionMembersView(
                collectionID: detail.id,
                phase: collectionMembersState.phase,
                horizontalPadding: detailHorizontalPadding,
                retry: {
                    Task { await reloadCollectionMembers() }
                }
            )
        } else if !visibleChildGroups(in: detail).isEmpty {
            childGroupsView(for: detail)
        }
    }

    func beginThumbnailPlayback(_ thumbnail: EntityThumbnail) {
        beginPlayback(EntityLink(thumbnail: thumbnail, intent: .playback))
    }

    func beginPlayback(_ playbackLink: EntityLink) {
        suppressesRoutePlayback = false
        thumbnailPlaybackLink = playbackLink
    }

    func beginDetailVideoPlayback() {
        beginPlayback(
            EntityLink(
                entityID: link.entityID,
                kind: link.kind,
                parentEntityID: link.parentEntityID,
                parentKind: link.parentKind,
                intent: .playback,
                sourceThumbnail: link.sourceThumbnail,
                thumbnailPreview: link.thumbnailPreview,
                mediaSequence: link.mediaSequence
            )
        )
    }

    func hasPlayableVideo(_ detail: EntityDetail) -> Bool {
        PlayableVideoResolver.videoID(
            in: detail,
            sourceThumbnail: link.sourceThumbnail
        ) != nil
    }

    func videoPrimaryAction(for detail: EntityDetail) -> EntityDetailAction? {
        guard hasPlayableVideo(detail) else { return nil }
        let savedResume = detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
        let resumeSeconds = max(0, liveVideoResumeSeconds ?? savedResume)
        return EntityDetailAction(
            id: resumeSeconds > 0 ? .resume : .play,
            title: resumeSeconds > 0
                ? "Resume \(VideoPlaybackPresentation.clockTime(resumeSeconds))"
                : "Play",
            systemImage: "play.fill",
            isSelected: false,
            isPrimary: true
        )
    }

    func loadResolvedVideoTechnicalDetail(for detail: EntityDetail) async {
        resolvedVideoTechnicalDetail = nil
        guard let videoID = PlayableVideoResolver.videoID(
            in: detail,
            sourceThumbnail: link.sourceThumbnail
        ), videoID != detail.id else { return }

        do {
            let resolved = try await dependencies.detailLoader.loadEntity(
                id: videoID,
                kind: .video
            )
            guard !Task.isCancelled, currentDetail?.id == detail.id else { return }
            resolvedVideoTechnicalDetail = resolved
        } catch {
            // Thumbnail media facts remain available when the technical detail cannot load.
        }
    }
}
