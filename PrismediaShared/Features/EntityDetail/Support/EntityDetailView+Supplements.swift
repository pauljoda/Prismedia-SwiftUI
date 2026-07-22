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
    func mainSupplementView(
        for detail: EntityDetail,
        onTVGridFocusMoved: @MainActor @escaping () -> Void
    ) -> some View {
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
                },
                onTVGridFocusMoved: onTVGridFocusMoved
            )
            .id("entity-detail.collection-grid")
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
}
