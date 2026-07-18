import SwiftUI

struct EntityGridSelectionSurface<Content: View>: View {
    let item: EntityThumbnail
    let isSelectionActive: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    let collectionOptions: [EntityThumbnail]
    let collectionOptionsAreLoading: Bool
    let collectionOptionsLoadFailed: Bool
    let onAddToCollection: ((EntityThumbnail) -> Void)?
    let onReloadCollectionOptions: (() -> Void)?
    let content: Content

    init(
        item: EntityThumbnail,
        isSelectionActive: Bool,
        isSelected: Bool,
        onToggle: @escaping () -> Void,
        collectionOptions: [EntityThumbnail] = [],
        collectionOptionsAreLoading: Bool = false,
        collectionOptionsLoadFailed: Bool = false,
        onAddToCollection: ((EntityThumbnail) -> Void)? = nil,
        onReloadCollectionOptions: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.item = item
        self.isSelectionActive = isSelectionActive
        self.isSelected = isSelected
        self.onToggle = onToggle
        self.collectionOptions = collectionOptions
        self.collectionOptionsAreLoading = collectionOptionsAreLoading
        self.collectionOptionsLoadFailed = collectionOptionsLoadFailed
        self.onAddToCollection = onAddToCollection
        self.onReloadCollectionOptions = onReloadCollectionOptions
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        #if os(tvOS)
            if let onAddToCollection {
                selectionSurface
                    .contextMenu {
                        Menu("Add to Collection", systemImage: "rectangle.stack.badge.plus") {
                            collectionMenu(onAddToCollection: onAddToCollection)
                        }
                    }
            } else {
                selectionSurface
            }
        #else
            selectionSurface
        #endif
    }

    #if os(tvOS)
        @ViewBuilder
        private func collectionMenu(
            onAddToCollection: @escaping (EntityThumbnail) -> Void
        ) -> some View {
            if collectionOptionsAreLoading {
                Button("Loading Collections…") {}
                    .disabled(true)
            } else if collectionOptionsLoadFailed {
                Button("Try Loading Collections Again", systemImage: "arrow.clockwise") {
                    onReloadCollectionOptions?()
                }
            } else if collectionOptions.isEmpty {
                Button("No Collections Available") {}
                    .disabled(true)
            } else {
                ForEach(collectionOptions) { collection in
                    Button(collection.title) {
                        onAddToCollection(collection)
                    }
                    .accessibilityIdentifier(
                        "add-to-collection.option.\(collection.id.uuidString)"
                    )
                }
            }
        }
    #endif

    private var selectionSurface: some View {
        content
            .allowsHitTesting(!isSelectionActive)
            .overlay {
                if isSelectionActive {
                    Button(action: onToggle) {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Select \(item.title)")
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityIdentifier("entity.grid.selection.item.\(item.id.uuidString)")
                }
            }
            .overlay(alignment: .topTrailing) {
                if isSelectionActive {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(isSelected ? PrismediaColor.accent : PrismediaColor.onMedia)
                        .padding(PrismediaSpacing.small)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
    }
}

#if DEBUG
    #Preview("Selection Surface · Selected") {
        EntityGridSelectionSurface(
            item: PrismediaPreviewData.series,
            isSelectionActive: true,
            isSelected: true,
            onToggle: {}
        ) {
            EntityThumbnailCardView(item: PrismediaPreviewData.series)
        }
        .frame(width: 180)
        .padding()
        .preferredColorScheme(.dark)
    }

    #Preview("Selection Surface · Accessibility") {
        EntityGridSelectionSurface(
            item: PrismediaPreviewData.book,
            isSelectionActive: true,
            isSelected: false,
            onToggle: {}
        ) {
            EntityThumbnailCardView(item: PrismediaPreviewData.book, layout: .list)
        }
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
