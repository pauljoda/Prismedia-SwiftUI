import SwiftUI

struct EntityDetailArtworkSurface<Content: View>: View {
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
            .frame(maxWidth: .infinity, alignment: .leading)
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
                GeometryReader { geometry in
                    ArtworkPaletteSurface(
                        artworkPath: artworkPath,
                        previewPath: previewPath,
                        fallbackSeed: fallbackSeed,
                        systemImage: systemImage,
                        palette: $palette
                    ) {
                        Color.clear
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                    }
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

#if DEBUG
    #Preview("Entity Detail Artwork Surface · Narrow") {
        @Previewable @State var palette: ArtworkPalette?

        PreviewShell(signedIn: true) {
            EntityDetailArtworkSurface(
                artworkPath: "/preview/poster.jpg",
                fallbackSeed: "A Storm Blows In",
                systemImage: "film",
                palette: $palette
            ) {
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                        Text("A Storm Blows In")
                            .font(.largeTitle.bold())
                        Text(
                            "A deliberately long summary that must wrap inside the narrow phone viewport instead of expanding the entire detail surface."
                        )
                        PrismediaButton(
                            "Play",
                            systemImage: "play.fill",
                            variant: .prominent,
                            form: .fill,
                            primaryTint: PrismediaColor.spectrumCyan
                        ) {}
                    }
                    .padding(PrismediaSpacing.extraLarge)
                }
            }
        }
        .frame(width: 320, height: 680)
        .preferredColorScheme(.dark)
    }
#endif
