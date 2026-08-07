import SwiftUI

/// Artwork for a reference draft that does not yet have an EntityThumbnail.
struct EntityReferenceDraftArtworkView: View {
    @ScaledMetric(relativeTo: .body) private var widthScale: CGFloat = 1

    let title: String
    let kind: EntityKind
    let artworkPath: String?
    let width: CGFloat

    var body: some View {
        let presentation = EntityThumbnailArtworkPresentation(kind: kind)

        EntityThumbnailArtworkFrame(aspectRatio: presentation.aspectRatio) {
            EntityArtworkSurfaceView(surface: presentation.surface) {
                RemotePosterImage(
                    path: artworkPath,
                    fallbackSeed: title,
                    systemImage: kind.thumbnailFallbackSystemImage,
                    contentMode: presentation.contentMode,
                    maxPixelSize: 512
                )
            }
        }
        .frame(width: width * widthScale)
        .background(PrismediaColor.controlFill)
        .compositingGroup()
        .clipShape(.rect(cornerRadius: PrismediaRadius.compact, style: .continuous))
        .accessibilityHidden(true)
    }
}

#if DEBUG
    #Preview("Reference Draft Artwork") {
        PreviewShell {
            EntityReferenceDraftArtworkView(
                title: "Proposed Movie",
                kind: .movie,
                artworkPath: nil,
                width: 72
            )
            .padding()
            .background(PrismediaBackdrop())
        }
    }
#endif
