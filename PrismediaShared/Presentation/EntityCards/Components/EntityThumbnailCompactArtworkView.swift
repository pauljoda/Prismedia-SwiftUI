import SwiftUI

/// Decoration-free entity artwork for compact rows and grids. The host chooses
/// width; the thumbnail remains the sole owner of media geometry and fitting.
struct EntityThumbnailCompactArtworkView: View {
    @ScaledMetric(relativeTo: .body) private var widthScale: CGFloat = 1

    private let title: String
    private let kind: EntityKind
    private let artworkPath: String?
    private let presentation: EntityThumbnailArtworkPresentation
    private let nominalWidth: CGFloat?

    init(
        item: EntityThumbnail,
        artworkPathOverride: String? = nil,
        width: CGFloat? = nil
    ) {
        title = item.title
        kind = item.kind
        artworkPath = artworkPathOverride ?? item.bestCoverPath
        presentation = item.thumbnailArtworkPresentation
        nominalWidth = width
    }

    init(
        title: String,
        kind: EntityKind,
        artworkPath: String?,
        width: CGFloat? = nil
    ) {
        self.title = title
        self.kind = kind
        self.artworkPath = artworkPath
        presentation = EntityThumbnailArtworkPresentation(kind: kind)
        nominalWidth = width
    }

    var body: some View {
        EntityThumbnailArtworkFrame(aspectRatio: presentation.aspectRatio) {
            RemotePosterImage(
                path: artworkPath,
                fallbackSeed: title,
                systemImage: kind.thumbnailFallbackSystemImage,
                contentMode: presentation.contentMode,
                maxPixelSize: 512
            )
        }
        .frame(width: scaledWidth)
        .frame(maxWidth: nominalWidth == nil ? .infinity : nil, alignment: .leading)
        .background(PrismediaColor.controlFill)
        .compositingGroup()
        .clipShape(.rect(cornerRadius: PrismediaRadius.compact, style: .continuous))
        .accessibilityHidden(true)
    }

    private var scaledWidth: CGFloat? {
        nominalWidth.map { $0 * widthScale }
    }
}

#if DEBUG
    #Preview("Compact Entity Artwork · Canonical Shapes") {
        let square = EntityThumbnail(id: UUID(), kind: .audioLibrary, title: "Square Album")
        let poster = EntityThumbnail(id: UUID(), kind: .movie, title: "Poster Movie")
        let person = EntityThumbnail(id: UUID(), kind: .person, title: "Portrait Person")
        let video = EntityThumbnail(id: UUID(), kind: .video, title: "Wide Video")
        let studio = EntityThumbnail(id: UUID(), kind: .studio, title: "Ultrawide Studio")
        let movieVideo = EntityThumbnail(
            id: UUID(),
            kind: .video,
            title: "Movie-owned Video",
            parentEntityID: UUID(),
            parentKind: .movie
        )

        PreviewShell {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                    ForEach([square, poster, person, video, studio, movieVideo]) { item in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                            EntityThumbnailCompactArtworkView(item: item, width: 88)
                            Text(item.title)
                                .font(.caption)
                                .lineLimit(2)
                                .frame(width: 88, alignment: .leading)
                        }
                    }
                }
                .padding(PrismediaSpacing.extraLarge)
            }
            .background(PrismediaBackdrop())
        }
    }

    #Preview("Compact Entity Artwork · Accessibility") {
        PreviewShell {
            EntityThumbnailCompactArtworkView(
                item: EntityThumbnail(id: UUID(), kind: .person, title: "Portrait Person"),
                width: 52
            )
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
