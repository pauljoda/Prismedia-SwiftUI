import SwiftUI

struct EntityMediaFeedView: View {
    @State private var contentLoader: EntityMediaContentLoader
    @State private var visibleItemIDs = Set<UUID>()
    @State private var preparedItemsByID: [UUID: EntityMediaFeedPreparedItem] = [:]
    @State private var requestedPreparedCount: Int

    private let items: [EntityThumbnail]
    private let mediaSequence: EntityMediaSequence
    private let videoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)?
    private let selection: EntityGridSelectionState
    private let onToggleSelection: (UUID) -> Void
    private let onOpen: (EntityThumbnail, EntityMediaSequence) -> Void
    private let onItemAppear: (UUID) -> Void

    init(
        items: [EntityThumbnail],
        mediaSequence: EntityMediaSequence,
        dependencies: EntityMediaFeedDependencies,
        selection: EntityGridSelectionState = EntityGridSelectionState(),
        onToggleSelection: @escaping (UUID) -> Void = { _ in },
        onOpen: @escaping (EntityThumbnail, EntityMediaSequence) -> Void,
        onItemAppear: @escaping (UUID) -> Void
    ) {
        self.items = items
        self.mediaSequence = mediaSequence
        videoAspectRatioLoader = dependencies.videoAspectRatioLoader
        self.selection = selection
        self.onToggleSelection = onToggleSelection
        self.onOpen = onOpen
        self.onItemAppear = onItemAppear
        _contentLoader = State(
            initialValue: EntityMediaContentLoader(
                detailLoader: dependencies.detailLoader,
                sourceLoader: dependencies.sourceLoader,
                retainedItems: items
            )
        )
        _requestedPreparedCount = State(
            initialValue: min(Self.preparationBatchSize, items.count)
        )
    }

    var body: some View {
        let preparedItems = leadingPreparedItems(in: items)
        let request = preparationRequest
        let orderedIDs = items.map(\.id)
        let videoIDs = Set(
            preparedItems.lazy.filter {
                $0.projection?.mediaKind == .video && $0.projection?.playbackPath != nil
            }.map(\.id)
        )
        let playbackItemID = EntityMediaFeedPlaybackPolicy.playbackID(
            orderedIDs: orderedIDs,
            visibleIDs: visibleItemIDs
        )
        let prewarmItemIDs = EntityMediaFeedPlaybackPolicy.prewarmIDs(
            orderedIDs: orderedIDs,
            visibleIDs: visibleItemIDs,
            eligibleIDs: videoIDs
        )

        LazyVStack(alignment: .leading, spacing: EntityMediaFeedLayout.interItemSpacing) {
            ForEach(Array(preparedItems.enumerated()), id: \.element.id) { index, preparedItem in
                EntityGridSelectionSurface(
                    item: preparedItem.item,
                    isSelectionActive: selection.isActive,
                    isSelected: selection.selectedIDs.contains(preparedItem.id),
                    onToggle: { onToggleSelection(preparedItem.id) }
                ) {
                    EntityMediaFeedItemView(
                        preparedItem: preparedItem,
                        mediaSequence: mediaSequence,
                        contentLoader: contentLoader,
                        isPlaybackActive: !selection.isActive && preparedItem.id == playbackItemID,
                        isPrewarmEligible: prewarmItemIDs.contains(preparedItem.id),
                        onOpen: onOpen
                    ) { isVisible in
                        visibilityDidChange(for: preparedItem.id, isVisible: isVisible)
                    }
                }
                .onAppear {
                    onItemAppear(preparedItem.id)
                    requestNextPreparationBatchIfNeeded(
                        visibleIndex: index,
                        preparedCount: preparedItems.count
                    )
                }
            }

            if preparedItems.count < items.count {
                ProgressView("Preparing media…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PrismediaSpacing.extraLarge)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, EntityMediaFeedLayout.horizontalInset)
        .task(id: request) {
            await prepareRequestedItems(for: request)
        }
        .onChange(of: items) { _, newItems in
            reconcilePreparedItems(with: newItems)
        }
    }

    private var preparationRequest: EntityMediaFeedPreparationRequest {
        EntityMediaFeedPreparationRequest(
            items: items,
            requestedCount: min(requestedPreparedCount, items.count)
        )
    }

    private func leadingPreparedItems(
        in items: [EntityThumbnail]
    ) -> [EntityMediaFeedPreparedItem] {
        var preparedItems: [EntityMediaFeedPreparedItem] = []
        preparedItems.reserveCapacity(items.count)
        for item in items {
            guard
                let preparedItem = preparedItemsByID[item.id],
                preparedItem.item == item
            else { break }
            preparedItems.append(preparedItem)
        }
        return preparedItems
    }

    private func prepareRequestedItems(
        for request: EntityMediaFeedPreparationRequest
    ) async {
        await contentLoader.retain(request.items)
        let retainedIDs = Set(request.items.map(\.id))
        visibleItemIDs.formIntersection(retainedIDs)

        let requestedItems = request.items.prefix(request.requestedCount).filter { item in
            preparedItemsByID[item.id]?.item != item
        }
        guard !requestedItems.isEmpty else { return }
        let preparedItems = await EntityMediaFeedPreparationService().prepare(
            Array(requestedItems),
            contentLoader: contentLoader,
            videoAspectRatioLoader: videoAspectRatioLoader
        )
        guard !Task.isCancelled, request == preparationRequest else { return }
        for preparedItem in preparedItems {
            preparedItemsByID[preparedItem.id] = preparedItem
        }
    }

    private func reconcilePreparedItems(with newItems: [EntityThumbnail]) {
        let currentItems = Dictionary(uniqueKeysWithValues: newItems.map { ($0.id, $0) })
        preparedItemsByID = preparedItemsByID.filter { id, preparedItem in
            currentItems[id] == preparedItem.item
        }
        visibleItemIDs.formIntersection(currentItems.keys)

        let preparedCount = leadingPreparedItems(in: newItems).count
        let minimumLeadingBatch = min(Self.preparationBatchSize, newItems.count)
        requestedPreparedCount = min(
            newItems.count,
            max(minimumLeadingBatch, preparedCount + Self.preparationBatchSize)
        )
    }

    private func requestNextPreparationBatchIfNeeded(
        visibleIndex: Int,
        preparedCount: Int
    ) {
        guard preparedCount < items.count else { return }
        let triggerIndex = max(0, preparedCount - Self.preparationPrefetchDistance)
        guard visibleIndex >= triggerIndex else { return }
        requestedPreparedCount = min(
            items.count,
            max(requestedPreparedCount, preparedCount + Self.preparationBatchSize)
        )
    }

    private func visibilityDidChange(for itemID: UUID, isVisible: Bool) {
        if isVisible {
            visibleItemIDs.insert(itemID)
            return
        }
        visibleItemIDs.remove(itemID)
    }

    private static let preparationBatchSize = 5
    private static let preparationPrefetchDistance = 2
}

#if DEBUG
    #Preview("Image Media Feed") {
        let loader = EntityMediaPreviewLoader(
            details: EntityMediaFeedPreviewData.details
        )
        PreviewShell(signedIn: true) {
            ScrollView {
                EntityMediaFeedView(
                    items: EntityMediaFeedPreviewData.items,
                    mediaSequence: EntityMediaSequence(items: EntityMediaFeedPreviewData.items),
                    dependencies: EntityMediaFeedDependencies(
                        detailLoader: loader,
                        sourceLoader: loader
                    ),
                    onOpen: { _, _ in },
                    onItemAppear: { _ in }
                )
            }
        }
    }
#endif
