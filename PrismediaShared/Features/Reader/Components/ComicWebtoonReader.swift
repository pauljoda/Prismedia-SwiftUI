import SwiftUI

struct ComicWebtoonReader: View {
    @State private var restoredPageIDs: [UUID]?

    let manifest: BookReaderManifest
    let currentIndex: Int
    let navigationRequestID: Int
    let counterText: String
    let pageCache: BookReaderPageCache
    let isAdvancingChapter: Bool
    let onMove: (Int) -> Void
    let onToggleControls: () -> Void
    let onEndAction: () -> Void

    var body: some View {
        GeometryReader { viewport in
            ScrollViewReader { proxy in
                webtoonPages(viewport: viewport, proxy: proxy)
            }
        }
        .accessibilityLabel("Webtoon reader, \(counterText)")
        .accessibilityIdentifier("comic-reader.page")
    }

    @ViewBuilder
    private func webtoonPages(
        viewport: GeometryProxy,
        proxy: ScrollViewProxy
    ) -> some View {
        let pageIDs = manifest.pages.map(\.id)
        let pages = ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(Array(manifest.pages.enumerated()), id: \.element.id) { index, page in
                    AuthenticatedComicPage(page: page, cache: pageCache, fit: false)
                        .id(page.id)
                        .background {
                            GeometryReader { pageGeometry in
                                Color.clear.preference(
                                    key: ComicPageOffsetPreferenceKey.self,
                                    value: [
                                        index: pageGeometry.frame(
                                            in: .named("comic-scroll")
                                        ).minY
                                    ]
                                )
                            }
                        }
                }

                ComicReaderChapterEnd(
                    nextChapterTitle: manifest.nextChapter?.title,
                    isAdvancingChapter: isAdvancingChapter,
                    action: onEndAction
                )
                .frame(minHeight: 280)
                .id("comic-reader-end")
            }
        }
        .coordinateSpace(.named("comic-scroll"))
        .task(
            id: ComicReaderPreloadKey(
                chapterIDs: manifest.chapters.map(\.id),
                index: currentIndex,
                options: ComicReaderOptions()
            )
        ) {
            await ComicReaderPagePreloader(cache: pageCache).prefetch(
                around: currentIndex,
                manifest: manifest,
                options: ComicReaderOptions()
            )
        }
        .task(id: pageIDs) {
            restoredPageIDs = nil
            await Task.yield()
            guard !Task.isCancelled,
                manifest.pages.indices.contains(currentIndex)
            else { return }

            proxy.scrollTo(manifest.pages[currentIndex].id, anchor: .top)
        }
        .onChange(of: navigationRequestID) {
            guard manifest.pages.indices.contains(currentIndex) else { return }
            proxy.scrollTo(manifest.pages[currentIndex].id, anchor: .top)
        }
        .onPreferenceChange(ComicPageOffsetPreferenceKey.self) { offsets in
            guard manifest.pages.indices.contains(currentIndex) else { return }
            if restoredPageIDs != pageIDs {
                guard let targetOffset = offsets[currentIndex] else { return }
                if abs(targetOffset) <= 2 {
                    restoredPageIDs = pageIDs
                } else {
                    proxy.scrollTo(manifest.pages[currentIndex].id, anchor: .top)
                }
                return
            }

            let anchor = viewport.size.height * 0.45
            let index =
                offsets
                .filter { $0.value <= anchor }
                .max(by: { $0.value < $1.value })?
                .key
            if let index { onMove(index) }
        }

        #if os(tvOS)
            pages
        #else
            pages
                .simultaneousGesture(
                    SpatialTapGesture().onEnded { value in
                        handleTap(value.location.x, width: viewport.size.width, proxy: proxy)
                    },
                    including: .gesture
                )
        #endif
    }

    #if !os(tvOS)
        private func handleTap(_ x: CGFloat, width: CGFloat, proxy: ScrollViewProxy) {
            switch ComicReaderNavigation.tapZone(x: x, width: width) {
            case .controls:
                onToggleControls()
            case .previous:
                let target = max(0, currentIndex - 1)
                onMove(target)
                proxy.scrollTo(manifest.pages[target].id, anchor: .top)
            case .next:
                let target = min(manifest.pages.count - 1, currentIndex + 1)
                onMove(target)
                proxy.scrollTo(manifest.pages[target].id, anchor: .top)
            }
        }
    #endif
}
#if DEBUG
    #Preview("Comic Webtoon Reader") {
        ComicWebtoonReader(
            manifest: ComicReaderPreviewData.manifest,
            currentIndex: 0,
            navigationRequestID: 0,
            counterText: "1 of 1",
            pageCache: ComicReaderPreviewData.pageCache,
            isAdvancingChapter: false,
            onMove: { _ in },
            onToggleControls: {},
            onEndAction: {}
        )
        .background(.black)
    }
#endif
