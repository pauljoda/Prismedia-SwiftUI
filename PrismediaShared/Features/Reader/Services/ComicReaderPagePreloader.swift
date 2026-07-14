import SwiftUI

@MainActor
struct ComicReaderPagePreloader {
    let cache: BookReaderPageCache
    private let maximumConcurrentLoads = 2

    func prefetch(
        around index: Int,
        manifest: BookReaderManifest,
        options: ComicReaderOptions
    ) async {
        let visibleIndexes = ComicReaderNavigation.spread(
            index: index,
            total: manifest.pages.count,
            options: options
        )
        let preloadIndexes = ComicReaderNavigation.preloadIndexes(
            index: index,
            total: manifest.pages.count,
            options: options
        )
        let indexes = visibleIndexes + preloadIndexes
        cache.retainOnly(Set(indexes.map { manifest.pages[$0].id }))

        for batchStart in stride(from: 0, to: indexes.count, by: maximumConcurrentLoads) {
            let batchEnd = min(indexes.count, batchStart + maximumConcurrentLoads)
            await withTaskGroup(of: Void.self) { group in
                for index in indexes[batchStart..<batchEnd] {
                    let pageID = manifest.pages[index].id
                    group.addTask { _ = try? await cache.data(for: pageID) }
                }
            }
        }
    }
}
