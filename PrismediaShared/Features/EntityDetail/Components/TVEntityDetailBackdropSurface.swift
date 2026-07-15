import SwiftUI

#if os(tvOS)
    struct TVEntityDetailBackdropSurface<Content: View>: View {
        @Binding private var palette: ArtworkPalette?

        let heroPath: String?
        let posterPath: String?
        let previewPath: String?
        let fallbackSeed: String
        let systemImage: String
        @ViewBuilder let content: Content

        init(
            heroPath: String?,
            posterPath: String?,
            previewPath: String?,
            fallbackSeed: String,
            systemImage: String,
            palette: Binding<ArtworkPalette?>,
            @ViewBuilder content: () -> Content
        ) {
            self.heroPath = heroPath
            self.posterPath = posterPath
            self.previewPath = previewPath
            self.fallbackSeed = fallbackSeed
            self.systemImage = systemImage
            _palette = palette
            self.content = content()
        }

        var body: some View {
            content
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .environment(\.artworkPalette, activePalette)
                .environment(
                    \.artworkPrimaryAccent,
                    activePalette?.primary.color ?? PrismediaColor.accent
                )
                .environment(
                    \.artworkSecondaryText,
                    activePalette?.secondary.color ?? PrismediaColor.textSecondary
                )
                .background {
                    TVEntityDetailBackdrop(
                        palette: $palette,
                        heroPath: heroPath,
                        posterPath: posterPath,
                        previewPath: previewPath,
                        fallbackSeed: fallbackSeed,
                        systemImage: systemImage
                    )
                    .ignoresSafeArea()
                }
        }

        private var activePalette: ArtworkPalette? {
            heroPath == nil ? nil : palette
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Entity Detail Backdrop Surface · No Hero") {
        @Previewable @State var palette: ArtworkPalette?
        PreviewShell(signedIn: true) {
            TVEntityDetailBackdropSurface(
                heroPath: nil,
                posterPath: "/preview/poster.jpg",
                previewPath: nil,
                fallbackSeed: "A Storm Blows In",
                systemImage: "film",
                palette: $palette
            ) {
                Text("A Storm Blows In")
                    .font(.largeTitle.bold())
                    .padding(72)
            }
        }
        .frame(width: 1_920, height: 1_080)
    }
#endif
