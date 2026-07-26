import SwiftUI

/// An artwork-derived page atmosphere that falls back to Prismedia's spectrum.
public struct ArtworkPaletteBackdrop: View {
    let palette: ArtworkPalette?

    public init(palette: ArtworkPalette?) {
        self.palette = palette
    }

    public var body: some View {
        if let palette {
            ZStack {
                palette.background.color

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
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        } else {
            PrismediaBackdrop()
        }
    }
}

#if DEBUG
    #Preview("Artwork Palette Backdrop") {
        ArtworkPaletteBackdrop(
            palette: ArtworkPalette(
                background: ArtworkColor(red: 0.03, green: 0.08, blue: 0.16),
                primary: ArtworkColor(red: 0.16, green: 0.72, blue: 0.92),
                secondary: ArtworkColor(red: 0.88, green: 0.42, blue: 0.18)
            )
        )
        .preferredColorScheme(.dark)
    }
#endif
