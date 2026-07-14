import SwiftUI

#if os(tvOS)
    struct TVEntityDetailBackdrop: View {
        @Binding var palette: ArtworkPalette?

        let heroPath: String?
        let posterPath: String?
        let previewPath: String?
        let fallbackSeed: String
        let systemImage: String

        var body: some View {
            Group {
                if let heroPath {
                    ArtworkPaletteSurface(
                        artworkPath: heroPath,
                        previewPath: posterPath ?? previewPath,
                        fallbackSeed: fallbackSeed,
                        systemImage: systemImage,
                        palette: $palette
                    ) {
                        RemotePosterImage(
                            path: heroPath,
                            previewPath: posterPath ?? previewPath,
                            fallbackSeed: fallbackSeed,
                            systemImage: systemImage,
                            contentMode: .fill,
                            retainsCurrentImageWhileLoading: true,
                            maxPixelSize: 2_048
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(backdropGradients)
                    }
                } else if let fallbackArtworkPath = posterPath ?? previewPath {
                    ArtworkPaletteSurface(
                        artworkPath: fallbackArtworkPath,
                        previewPath: previewPath,
                        fallbackSeed: fallbackSeed,
                        systemImage: systemImage,
                        palette: $palette
                    ) {
                        Color.clear
                    }
                } else {
                    PrismediaBackdrop()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }

        private var backdropGradients: some View {
            ZStack {
                LinearGradient(
                    colors: [
                        PrismediaColor.background.opacity(0.82),
                        PrismediaColor.background.opacity(0.16),
                        .clear,
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    colors: [
                        .clear,
                        PrismediaColor.background.opacity(0.2),
                        PrismediaColor.background.opacity(0.92),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Entity Detail Backdrop · Hero") {
        @Previewable @State var palette: ArtworkPalette?
        PreviewShell(signedIn: true) {
            TVEntityDetailBackdrop(
                palette: $palette,
                heroPath: "/preview/hero.jpg",
                posterPath: "/preview/poster.jpg",
                previewPath: nil,
                fallbackSeed: "A Storm Blows In",
                systemImage: "film"
            )
        }
        .frame(width: 1_920, height: 1_080)
    }
#endif
