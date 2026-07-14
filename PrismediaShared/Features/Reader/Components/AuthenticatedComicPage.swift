import SwiftUI

struct AuthenticatedComicPage: View {
    let page: EntityThumbnail
    let cache: BookReaderPageCache
    var fit = true

    @State private var failed = false

    var body: some View {
        Group {
            if let image = cache.images[page.id] {
                platformImage(image)
                    .resizable()
                    .aspectRatio(contentMode: fit ? .fit : .fill)
                    .frame(maxWidth: .infinity, maxHeight: fit ? .infinity : nil)
                    .clipped()
            } else if failed {
                ContentUnavailableView("Page Unavailable", systemImage: "photo.badge.exclamationmark")
            } else {
                ProgressView().tint(PrismediaColor.accent)
            }
        }
        .background(Color.black)
        .accessibilityLabel(page.title)
        .task(id: page.id) {
            do {
                _ = try await cache.data(for: page.id)
            } catch {
                failed = true
            }
        }
    }

    private func platformImage(_ image: PlatformReaderImage) -> Image {
        Image(decorative: image, scale: 1, orientation: .up)
    }
}
#if DEBUG
    #Preview("Authenticated Comic Page") {
        AuthenticatedComicPage(
            page: ComicReaderPreviewData.pageThumbnail,
            cache: ComicReaderPreviewData.pageCache
        )
        .frame(width: 320, height: 480)
    }
#endif
