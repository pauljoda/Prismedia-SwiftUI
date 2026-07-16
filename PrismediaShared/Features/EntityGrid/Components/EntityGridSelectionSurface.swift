import SwiftUI

struct EntityGridSelectionSurface<Content: View>: View {
    let item: EntityThumbnail
    let isSelectionActive: Bool
    let isSelected: Bool
    let onToggle: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
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
