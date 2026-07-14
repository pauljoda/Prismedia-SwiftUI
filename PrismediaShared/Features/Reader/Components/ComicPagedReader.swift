import SwiftUI

struct ComicPagedReader: View {
    let manifest: BookReaderManifest
    let currentIndex: Int
    let options: ComicReaderOptions
    let showingEndPage: Bool
    let counterText: String
    let pageCache: BookReaderPageCache
    let isAdvancingChapter: Bool
    let onGesture: (ComicReaderGesture) -> Void
    let onTap: (CGFloat, CGFloat) -> Void
    let onEndAction: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let pages = ZStack {
                if showingEndPage {
                    ComicReaderChapterEnd(
                        nextChapterTitle: manifest.nextChapter?.title,
                        isAdvancingChapter: isAdvancingChapter,
                        action: onEndAction
                    )
                } else {
                    spread
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())

            #if os(tvOS)
                pages
            #else
                pages.gesture(
                    pagedGesture(width: geometry.size.width),
                    including: .gesture
                )
            #endif
        }
        .accessibilityLabel("Comic page, \(counterText)")
        .accessibilityIdentifier("comic-reader.page")
    }

    private var spread: some View {
        let indexes = ComicReaderNavigation.spread(
            index: currentIndex,
            total: manifest.pages.count,
            options: options
        )

        return HStack(spacing: PrismediaSpacing.small) {
            ForEach(indexes, id: \.self) { index in
                AuthenticatedComicPage(page: manifest.pages[index], cache: pageCache)
            }
        }
        .padding(.horizontal, indexes.count > 1 ? 12 : 0)
        .task(
            id: ComicReaderPreloadKey(
                chapterIDs: manifest.chapters.map(\.id),
                index: currentIndex,
                options: options
            )
        ) {
            await ComicReaderPagePreloader(cache: pageCache).prefetch(
                around: currentIndex,
                manifest: manifest,
                options: options
            )
        }
    }

    #if !os(tvOS)
        private func pagedGesture(width: CGFloat) -> some Gesture {
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    let translation = value.translation
                    let moved = hypot(translation.width, translation.height)
                    guard moved > 10 else {
                        onTap(value.startLocation.x, width)
                        return
                    }

                    onGesture(
                        ComicReaderNavigation.gesture(
                            deltaX: translation.width,
                            deltaY: translation.height
                        ))
                }
        }
    #endif
}
#if DEBUG
    #Preview("Comic Paged Reader") {
        ComicPagedReader(
            manifest: ComicReaderPreviewData.manifest,
            currentIndex: 0,
            options: ComicReaderOptions(),
            showingEndPage: false,
            counterText: "1 of 1",
            pageCache: ComicReaderPreviewData.pageCache,
            isAdvancingChapter: false,
            onGesture: { _ in },
            onTap: { _, _ in },
            onEndAction: {}
        )
        .background(.black)
    }
#endif
