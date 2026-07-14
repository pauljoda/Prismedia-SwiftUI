import SwiftUI

public struct RemotePosterImage: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @State private var artworkImage: Image?
    @State private var displayedURL: URL?
    let path: String?
    let previewPath: String?
    let fallbackSeed: String
    let systemImage: String
    let contentMode: ContentMode
    let imageCornerRadius: CGFloat
    let retainsCurrentImageWhileLoading: Bool
    let maxPixelSize: Int

    public init(
        path: String?,
        previewPath: String? = nil,
        fallbackSeed: String = "Prismedia",
        systemImage: String = "photo",
        contentMode: ContentMode = .fill,
        imageCornerRadius: CGFloat = 0,
        retainsCurrentImageWhileLoading: Bool = false,
        maxPixelSize: Int = 2_048
    ) {
        self.path = path
        self.previewPath = previewPath
        self.fallbackSeed = fallbackSeed
        self.systemImage = systemImage
        self.contentMode = contentMode
        self.imageCornerRadius = imageCornerRadius
        self.retainsCurrentImageWhileLoading = retainsCurrentImageWhileLoading
        self.maxPixelSize = max(1, maxPixelSize)
    }

    public var body: some View {
        Group {
            if let artworkImage {
                remoteImage(artworkImage)
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task(id: artworkRequestID) {
            let validURLs = [artworkURL, previewArtworkURL].compactMap { $0 }
            guard !validURLs.isEmpty else {
                artworkImage = nil
                displayedURL = nil
                return
            }
            if let displayedURL,
                !validURLs.contains(displayedURL),
                !retainsCurrentImageWhileLoading
            {
                artworkImage = nil
                self.displayedURL = nil
            }

            if artworkImage == nil,
                let previewArtworkURL,
                let previewImage = await loadImage(for: previewArtworkURL)
            {
                guard !Task.isCancelled else { return }
                artworkImage = previewImage
                displayedURL = previewArtworkURL
            }

            guard let artworkURL, displayedURL != artworkURL else { return }
            guard let loadedImage = await loadImage(for: artworkURL) else { return }
            guard !Task.isCancelled else { return }
            artworkImage = loadedImage
            displayedURL = artworkURL
        }
    }

    private var artworkURL: URL? {
        environment.client?.assetURL(for: path)
    }

    private var previewArtworkURL: URL? {
        environment.client?.assetURL(for: previewPath)
    }

    private var artworkRequestID: String {
        "\(artworkURL?.absoluteString ?? "")|\(previewArtworkURL?.absoluteString ?? "")|\(maxPixelSize)"
    }

    @ViewBuilder
    private func remoteImage(_ image: Image) -> some View {
        if contentMode == .fit {
            image
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: imageCornerRadius, style: .continuous))
        } else {
            image
                .resizable()
                .scaledToFill()
                .clipShape(.rect(cornerRadius: imageCornerRadius, style: .continuous))
        }
    }

    private func loadImage(for url: URL) async -> Image? {
        let decoded: CGImage
        if let cached = environment.artworkLoader.cachedImage(
            for: url,
            maxPixelSize: maxPixelSize
        ) {
            decoded = cached
        } else {
            guard
                let loaded = try? await environment.artworkLoader.image(
                    for: url,
                    maxPixelSize: maxPixelSize
                )
            else {
                return nil
            }
            decoded = loaded
        }
        return Image(decorative: decoded, scale: 1, orientation: .up)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: fallbackColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    PrismediaColor.onMedia.opacity(0.11),
                    .clear,
                    PrismediaColor.background.opacity(PrismediaOpacity.statusFill),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(PrismediaColor.onMedia.opacity(0.7))
                .symbolRenderingMode(.hierarchical)
        }
        .clipShape(.rect(cornerRadius: imageCornerRadius, style: .continuous))
    }

    private var fallbackColors: [Color] {
        let palette = Self.fallbackPalettes[
            StableStringHash.paletteIndex(
                for: fallbackSeed,
                paletteCount: Self.fallbackPalettes.count
            )
        ]
        return palette.map { Color(hex: $0) }
    }

    /// Exact deterministic gradient palette used by Prismedia Web. Matching the
    /// title hash keeps placeholder artwork recognizable across clients.
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
}

#if DEBUG
    #Preview("Remote Artwork Placeholder") {
        PreviewShell {
            VStack(spacing: PrismediaSpacing.extraLarge) {
                RemotePosterImage(path: nil)
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .prismediaCard()

                RemotePosterImage(
                    path: "/preview/missing.jpg",
                    fallbackSeed: "Midnight Console Vol. 1",
                    systemImage: "book"
                )
                .aspectRatio(2.0 / 3.0, contentMode: .fit)
                .prismediaCard()
            }
            .padding(PrismediaSpacing.extraLarge)
            .background(PrismediaBackdrop())
        }
    }
#endif
