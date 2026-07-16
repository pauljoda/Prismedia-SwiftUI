import SwiftUI

struct EntityThumbnailGrid<ItemContent: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let items: [EntityThumbnail]
    let mediaSequence: EntityMediaSequence
    let minimumColumnWidth: CGFloat
    let displayMode: EntityGridDisplayMode
    let density: EntityGridDensity
    @ViewBuilder let itemContent: (EntityThumbnail, EntityThumbnailLayout) -> ItemContent

    init(
        items: [EntityThumbnail],
        mediaSequence: EntityMediaSequence? = nil,
        minimumColumnWidth: CGFloat,
        displayMode: EntityGridDisplayMode = .grid,
        density: EntityGridDensity = .standard,
        @ViewBuilder itemContent: @escaping (EntityThumbnail, EntityThumbnailLayout) -> ItemContent
    ) {
        self.items = items
        self.mediaSequence = mediaSequence ?? EntityMediaSequence(items: items)
        self.minimumColumnWidth = minimumColumnWidth
        self.displayMode = displayMode
        self.density = density
        self.itemContent = itemContent
    }

    @ViewBuilder
    var body: some View {
        switch displayMode {
        case .list:
            LazyVStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                itemsView
            }
        case .feed:
            LazyVStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                itemsView
            }
            .frame(maxWidth: .infinity)
        case .wall:
            LazyVGrid(columns: columns, alignment: .leading, spacing: PrismediaSpacing.large) {
                itemsView
            }
        case .grid:
            LazyVGrid(columns: columns, alignment: .leading, spacing: PrismediaSpacing.large) {
                itemsView
            }
        }
    }

    private var itemsView: some View {
        ForEach(items) { item in
            let layout = displayMode.thumbnailLayout(for: item.kind)
            itemContent(item, layout)
                .environment(\.entityMediaSequence, mediaSequence)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible(), spacing: PrismediaSpacing.large, alignment: .top)]
        }

        return [
            GridItem(
                .adaptive(
                    minimum: density.minimumColumnWidth(
                        default: displayMode == .wall ? minimumColumnWidth * 0.72 : minimumColumnWidth
                    )
                ),
                spacing: PrismediaSpacing.large,
                alignment: .top
            )
        ]
    }
}

extension EntityThumbnailGrid {
    init(
        items: [EntityThumbnail],
        mediaSequence: EntityMediaSequence? = nil,
        minimumColumnWidth: CGFloat,
        displayMode: EntityGridDisplayMode = .grid,
        density: EntityGridDensity = .standard,
        @ViewBuilder itemContent: @escaping (EntityThumbnail) -> ItemContent
    ) {
        self.init(
            items: items,
            mediaSequence: mediaSequence,
            minimumColumnWidth: minimumColumnWidth,
            displayMode: displayMode,
            density: density
        ) { item, _ in
            itemContent(item)
        }
    }
}
#if DEBUG
    #Preview("Entity Thumbnail Grid") {
        ScrollView {
            EntityThumbnailGrid(items: PrismediaPreviewData.videos, minimumColumnWidth: 150) {
                EntityThumbnailCardView(item: $0)
            }
            .padding()
        }
    }

    #Preview("Video List Uses Rail Cards") {
        ScrollView {
            EntityThumbnailGrid(
                items: PrismediaPreviewData.videos,
                minimumColumnWidth: 150,
                displayMode: .list
            ) {
                EntityThumbnailCardView(item: $0, layout: $1)
            }
            .padding()
        }
    }
#endif
