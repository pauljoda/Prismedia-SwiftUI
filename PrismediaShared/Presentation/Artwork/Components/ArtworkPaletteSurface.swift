import SwiftUI

struct ArtworkPaletteSurface<Content: View>: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Binding private var palette: ArtworkPalette?
    let artworkPath: String?
    let previewPath: String?
    let fallbackSeed: String
    let systemImage: String
    @ViewBuilder let content: Content

    init(
        artworkPath: String?,
        previewPath: String? = nil,
        fallbackSeed: String,
        systemImage: String,
        palette: Binding<ArtworkPalette?>,
        @ViewBuilder content: () -> Content
    ) {
        self.artworkPath = artworkPath
        self.previewPath = previewPath
        self.fallbackSeed = fallbackSeed
        self.systemImage = systemImage
        _palette = palette
        self.content = content()
    }

    var body: some View {
        content
            .environment(\.artworkPalette, palette)
            .environment(
                \.artworkPrimaryAccent,
                palette?.primary.color ?? PrismediaColor.accent
            )
            .environment(
                \.artworkSecondaryText,
                palette?.secondary.color ?? PrismediaColor.textSecondary
            )
            .background {
                backdrop
                    .ignoresSafeArea()
            }
            .animation(.easeInOut(duration: 0.18), value: palette)
            .task(id: requestID) {
                for url in artworkURLs {
                    guard !Task.isCancelled else { return }
                    if let resolved = await environment.artworkPaletteLoader.palette(for: url) {
                        guard !Task.isCancelled else { return }
                        palette = resolved
                        return
                    }
                }
            }
    }

    @ViewBuilder
    private var backdrop: some View {
        if let palette {
            ZStack {
                palette.background.color

                RemotePosterImage(
                    path: artworkPath,
                    previewPath: previewPath,
                    fallbackSeed: fallbackSeed,
                    systemImage: systemImage
                )
                .scaleEffect(1.42)
                .blur(radius: 76)
                .saturation(1.18)
                .opacity(0.78)

                RadialGradient(
                    colors: [palette.primary.color.opacity(0.4), .clear],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 520
                )

                RadialGradient(
                    colors: [palette.secondary.color.opacity(0.24), .clear],
                    center: .trailing,
                    startRadius: 10,
                    endRadius: 460
                )

                LinearGradient(
                    colors: [
                        PrismediaColor.background.opacity(0.16),
                        PrismediaColor.background.opacity(0.52),
                        PrismediaColor.background.opacity(0.8),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            ZStack {
                PrismediaColor.background

                RemotePosterImage(
                    path: artworkPath,
                    previewPath: previewPath,
                    fallbackSeed: fallbackSeed,
                    systemImage: systemImage
                )
                .scaleEffect(1.42)
                .blur(radius: 76)
                .saturation(1.12)
                .opacity(0.58)

                LinearGradient(
                    colors: [
                        PrismediaColor.background.opacity(0.3),
                        PrismediaColor.background.opacity(0.7),
                        PrismediaColor.background.opacity(0.88),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var artworkURLs: [URL] {
        let candidates = [artworkPath, previewPath]
            .compactMap { environment.client?.assetURL(for: $0) }
        return candidates.reduce(into: []) { urls, url in
            if !urls.contains(url) {
                urls.append(url)
            }
        }
    }

    private var requestID: String {
        artworkURLs.map(\.absoluteString).joined(separator: "|")
    }
}

#if DEBUG
    #Preview("Artwork Palette Surface · Base Fallback") {
        @Previewable @State var palette: ArtworkPalette?
        PreviewShell {
            ArtworkPaletteSurface(
                artworkPath: nil,
                fallbackSeed: "No Artwork",
                systemImage: "photo",
                palette: $palette
            ) {
                Text("System Background")
                    .font(.title.bold())
                    .foregroundStyle(.primary)
            }
        }
    }
#endif
