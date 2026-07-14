import Foundation

struct EntityMediaFeedPreparationService: Sendable {
    func prepare(
        _ items: [EntityThumbnail],
        contentLoader: EntityMediaContentLoader,
        videoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)? = nil
    ) async -> [EntityMediaFeedPreparedItem] {
        await withTaskGroup(
            of: (Int, EntityMediaFeedPreparedItem).self,
            returning: [EntityMediaFeedPreparedItem].self
        ) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let preparedItem = await prepare(
                        item,
                        contentLoader: contentLoader,
                        videoAspectRatioLoader: videoAspectRatioLoader
                    )
                    return (index, preparedItem)
                }
            }

            var indexedItems: [(Int, EntityMediaFeedPreparedItem)] = []
            indexedItems.reserveCapacity(items.count)
            for await indexedItem in group {
                indexedItems.append(indexedItem)
            }
            return indexedItems.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private func prepare(
        _ item: EntityThumbnail,
        contentLoader: EntityMediaContentLoader,
        videoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)?
    ) async -> EntityMediaFeedPreparedItem {
        let fallbackAspectRatio = EntityMediaFeedLayout.rowAspectRatio(
            item.thumbnailArtworkPresentation.aspectRatio
        )
        guard item.kind == .image else {
            return EntityMediaFeedPreparedItem(
                item: item,
                projection: nil,
                aspectRatio: fallbackAspectRatio
            )
        }

        let detail: EntityDetail
        do {
            try Task.checkCancellation()
            detail = try await contentLoader.loadDetail(id: item.id)
            try Task.checkCancellation()
        } catch {
            return EntityMediaFeedPreparedItem(
                item: item,
                projection: nil,
                aspectRatio: fallbackAspectRatio
            )
        }

        let projection = EntityImageMediaProjection(detail: detail)
        let technical = detail.capabilities.lazy.compactMap {
            capability -> EntityTechnicalCapability? in
            guard case .technical(let value) = capability else { return nil }
            return value
        }.first
        let technicalAspectRatio = EntityMediaFeedLayout.aspectRatio(
            pixelWidth: technical?.width,
            pixelHeight: technical?.height,
            fallback: 0
        )

        var aspectRatio = fallbackAspectRatio
        if projection.mediaKind == .video {
            aspectRatio =
                await videoAspectRatio(
                    playbackPath: projection.playbackPath,
                    loader: videoAspectRatioLoader
                )
                ?? (technicalAspectRatio > 0 ? technicalAspectRatio : fallbackAspectRatio)
        } else if technicalAspectRatio > 0 {
            aspectRatio = technicalAspectRatio
        } else if projection.sourcePath != nil {
            do {
                let data = try await contentLoader.loadSourceData(id: item.id)
                try Task.checkCancellation()
                aspectRatio =
                    await Task.detached(priority: .utility) {
                        EntityMediaFeedIntrinsicAspectRatio.resolve(data: data)
                    }.value ?? fallbackAspectRatio
                try Task.checkCancellation()
            } catch {}
        }

        return EntityMediaFeedPreparedItem(
            item: item,
            projection: projection,
            aspectRatio: EntityMediaFeedLayout.rowAspectRatio(aspectRatio)
        )
    }

    private func videoAspectRatio(
        playbackPath: String?,
        loader: (any EntityImageVideoAspectRatioLoading)?
    ) async -> Double? {
        guard let playbackPath, let loader else { return nil }
        do {
            let aspectRatio = try await loader.loadVideoAspectRatio(path: playbackPath)
            try Task.checkCancellation()
            guard aspectRatio.isFinite, aspectRatio > 0 else { return nil }
            return aspectRatio
        } catch {
            return nil
        }
    }
}
