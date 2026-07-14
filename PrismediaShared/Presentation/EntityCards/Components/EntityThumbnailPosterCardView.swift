import SwiftUI

struct EntityThumbnailPosterCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: EntityThumbnail
    let layout: EntityThumbnailLayout
    let preferredWidth: CGFloat?
    let onPreviewHoldChanged: (Bool) -> Void

    var body: some View {
        EntityThumbnailArtworkView(
            item: item,
            layout: layout,
            preferredWidth: preferredWidth,
            onPreviewHoldChanged: onPreviewHoldChanged
        )
        .overlay(alignment: .bottomLeading) {
            if presentation.showsTitleOverlay {
                titleOverlay
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .prismediaCard(cornerRadius: layout == .wall ? 8 : 6)
    }

    private var presentation: EntityThumbnailCardPresentation {
        EntityThumbnailCardPresentation(item: item, layout: layout)
    }

    private var titleOverlay: some View {
        Text(item.title)
            .font(PrismediaTypography.captionEmphasized)
            .foregroundStyle(PrismediaColor.onMedia)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 2)
            .padding(PrismediaSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                LinearGradient(
                    colors: [.clear, PrismediaColor.background.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }
}

#if DEBUG
    #Preview("Poster Card Title Overlay") {
        PreviewShell {
            EntityThumbnailPosterCardView(
                item: EntityThumbnail(
                    id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
                    kind: .person,
                    title: "A Person With Artwork",
                    coverURL: "/preview/person.jpg"
                ),
                layout: .grid,
                preferredWidth: 180,
                onPreviewHoldChanged: { _ in }
            )
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
