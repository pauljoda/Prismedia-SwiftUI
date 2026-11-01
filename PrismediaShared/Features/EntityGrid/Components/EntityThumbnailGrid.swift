import SwiftUI

struct EntityThumbnailGrid<ItemContent: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var listWidth: CGFloat = 0
    @State private var bookFold: CGRect?

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
        let displayItems = EntitySharedSourceEpisodePresentation.coalesced(items)
        self.items = displayItems
        self.mediaSequence = mediaSequence ?? EntityMediaSequence(items: displayItems)
        self.minimumColumnWidth = minimumColumnWidth
        self.displayMode = displayMode
        self.density = density
        self.itemContent = itemContent
    }

    @ViewBuilder
    var body: some View {
        switch displayMode {
        case .list:
            #if os(iOS)
                LazyVGrid(columns: listColumns, alignment: .leading, spacing: PrismediaSpacing.medium) {
                    itemsView
                }
                .environment(\.entityListColumnCount, effectiveListColumnCount)
                // The width changes frame by frame while the sidebar slides. A
                // new grid for each column count keeps the scroll view from
                // following a reflowed row down the list, and swapping it
                // without animation avoids cross-fading the two grids.
                .id(effectiveListColumnCount)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    withTransaction(\.disablesAnimations, true) {
                        listWidth = width
                    }
                }
                .onBookFoldChange { bookFold = $0 }
            #else
                LazyVStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                    itemsView
                }
            #endif
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

    /// List rows in as many columns of at least ``listColumnMinimumWidth`` as
    /// fit: one on a phone or beside the sidebar, two across a wide page, so a
    /// row never stretches across iPhone Duo's open display.
    private var listColumns: [GridItem] {
        if let foldedListColumns {
            return foldedListColumns
        }

        return Array(
            repeating: GridItem(.flexible(), spacing: PrismediaSpacing.large, alignment: .top),
            count: effectiveListColumnCount
        )
    }

    /// Folded like a book, two list columns sit one on each side of the fold,
    /// with the fold as their gutter, so no row's artwork lands on the hinge.
    private var foldedListColumns: [GridItem]? {
        guard effectiveListColumnCount == 2,
              let bookFold,
              bookFold.minX >= Self.listColumnMinimumWidth,
              listWidth - bookFold.maxX >= Self.listColumnMinimumWidth
        else {
            return nil
        }

        return [
            GridItem(.fixed(bookFold.minX), spacing: bookFold.width, alignment: .top),
            GridItem(.fixed(listWidth - bookFold.maxX), alignment: .top)
        ]
    }

    private var effectiveListColumnCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : Self.listColumnCount(for: listWidth)
    }

    private static var listColumnMinimumWidth: CGFloat { 280 }

    private static func listColumnCount(for width: CGFloat) -> Int {
        max(1, Int((width + PrismediaSpacing.large) / (listColumnMinimumWidth + PrismediaSpacing.large)))
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
