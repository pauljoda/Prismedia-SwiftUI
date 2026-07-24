import SwiftUI

struct EntityThumbnailArtworkExtensionView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @State private var extensionImage: Image?

    let item: EntityThumbnail
    let outputAspectRatio: Double
    let maxPixelSize: Int
    let isEnabled: Bool

    init(
        item: EntityThumbnail,
        outputAspectRatio: Double,
        maxPixelSize: Int = 512,
        isEnabled: Bool = true
    ) {
        self.item = item
        self.outputAspectRatio = outputAspectRatio
        self.maxPixelSize = max(1, maxPixelSize)
        self.isEnabled = isEnabled
    }

    var body: some View {
        Group {
            if let extensionImage, isEnabled {
                extensionImage
                    .resizable()
                    .scaledToFill()
            } else {
                PrismediaColor.groupedContentBackground
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: requestID) {
            guard isEnabled, let artworkURL else {
                extensionImage = nil
                return
            }
            guard
                let rendered = await ArtworkExtensionImagePipeline.shared.image(
                    for: artworkURL,
                    artworkLoader: environment.artworkLoader,
                    sourceAspectRatio: item.thumbnailArtworkPresentation.aspectRatio,
                    outputAspectRatio: outputAspectRatio,
                    maxPixelSize: maxPixelSize
                ),
                !Task.isCancelled
            else { return }
            extensionImage = Image(decorative: rendered, scale: 1, orientation: .up)
        }
        .accessibilityHidden(true)
    }

    private var artworkURL: URL? {
        environment.client?.assetURL(for: item.bestCoverPath)
    }

    private var requestID: String {
        [
            isEnabled ? "enabled" : "disabled",
            artworkURL?.absoluteString ?? "",
            String(item.thumbnailArtworkPresentation.aspectRatio),
            String(outputAspectRatio),
            String(maxPixelSize),
        ].joined(separator: "|")
    }
}

#if DEBUG
    #Preview("Cached Artwork Extension") {
        PreviewShell {
            EntityThumbnailArtworkExtensionView(
                item: PrismediaPreviewData.videos[0],
                outputAspectRatio: EntityThumbnailCardPresentation.extendedLandscapeAspectRatio
            )
            .aspectRatio(
                EntityThumbnailCardPresentation.extendedLandscapeAspectRatio,
                contentMode: .fit
            )
            .frame(width: 320)
            .prismediaCard(cornerRadius: PrismediaRadius.badge)
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    }
#endif
