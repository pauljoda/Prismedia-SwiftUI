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
            } else if isEnabled {
                fallbackExtension
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

    private var fallbackExtension: some View {
        ZStack {
            LinearGradient(
                colors: fallbackColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    PrismediaColor.onMedia.opacity(0.08),
                    .clear,
                    PrismediaColor.background.opacity(0.16),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var fallbackColors: [Color] {
        let palette = Self.fallbackPalettes[
            StableStringHash.paletteIndex(
                for: item.title,
                paletteCount: Self.fallbackPalettes.count
            )
        ]
        return palette.map { Color(hex: $0) }
    }

    private static let fallbackPalettes: [[UInt32]] = [
        [0x1A1028, 0x2D1B4E, 0x4A2040],
        [0x0F1A2E, 0x1B3A5C, 0x0D2847],
        [0x1A0F0A, 0x3D2415, 0x5C3A1B],
        [0x0A1A14, 0x153D2B, 0x1B5C3F],
        [0x1A1018, 0x3D1535, 0x5C1B4A],
        [0x1A180A, 0x3D3515, 0x5C4F1B],
        [0x0A0F1A, 0x15243D, 0x1B365C],
        [0x1A0A12, 0x3D1528, 0x5C1B3B],
    ]

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
