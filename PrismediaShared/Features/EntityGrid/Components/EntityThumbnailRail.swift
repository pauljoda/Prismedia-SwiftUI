import SwiftUI

/// A horizontally scrolling rail of Entity thumbnails with consistent artwork sizing.
struct EntityThumbnailRail<ItemContent: View>: View {
    let items: [EntityThumbnail]
    let maximumItemCount: Int?
    let artworkHeight: CGFloat
    let contentInsets: EdgeInsets
    @ViewBuilder let itemContent: (EntityThumbnail, CGFloat) -> ItemContent

    init(
        items: [EntityThumbnail],
        maximumItemCount: Int? = nil,
        artworkHeight: CGFloat = 216,
        contentInsets: EdgeInsets = EdgeInsets(),
        @ViewBuilder itemContent: @escaping (EntityThumbnail, CGFloat) -> ItemContent
    ) {
        self.items = items
        self.maximumItemCount = maximumItemCount
        self.artworkHeight = artworkHeight
        self.contentInsets = contentInsets
        self.itemContent = itemContent
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: PrismediaSpacing.small) {
                ForEach(visibleItems) { item in
                    itemContent(item, width(for: item))
                }
            }
            .padding(contentInsets)
        }
        .scrollIndicators(.hidden)
    }

    private var visibleItems: ArraySlice<EntityThumbnail> {
        guard let maximumItemCount else { return items[...] }
        return items.prefix(maximumItemCount)
    }

    private func width(for item: EntityThumbnail) -> CGFloat {
        item.thumbnailArtworkPresentation.width(forHeight: artworkHeight)
    }
}

#if DEBUG
    #Preview("Entity Thumbnail Rail") {
        EntityThumbnailRail(items: PrismediaPreviewData.allEntities) { item, width in
            EntityThumbnailNavigationSurface(
                item: item,
                layout: .rail,
                preferredWidth: width
            )
        }
        .padding()
    }
#endif
