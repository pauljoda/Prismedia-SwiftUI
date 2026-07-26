import SwiftUI

/// Reveals an artwork-derived content layer, or the spectrum when no palette is available.
public struct PrismediaArtworkScreenBackgroundModifier: ViewModifier {
    let palette: ArtworkPalette?

    public init(palette: ArtworkPalette?) {
        self.palette = palette
    }

    public func body(content: Content) -> some View {
        #if os(iOS)
            content
                .scrollContentBackground(.hidden)
                .containerBackground(for: .navigation) {
                    ArtworkPaletteBackdrop(palette: palette)
                }
                .background { ArtworkPaletteBackdrop(palette: palette) }
                .animation(.easeInOut(duration: 0.18), value: palette)
        #elseif os(tvOS)
            content
                .background { ArtworkPaletteBackdrop(palette: palette) }
                .animation(.easeInOut(duration: 0.18), value: palette)
        #else
            content
                .scrollContentBackground(.hidden)
                .background { ArtworkPaletteBackdrop(palette: palette) }
                .animation(.easeInOut(duration: 0.18), value: palette)
        #endif
    }
}

extension View {
    public func prismediaScreenBackground(palette: ArtworkPalette?) -> some View {
        modifier(PrismediaArtworkScreenBackgroundModifier(palette: palette))
    }
}

#if DEBUG
    #Preview("Artwork Screen Background · Spectrum Fallback") {
        NavigationStack {
            List {
                Label("Palette-aware page", systemImage: "paintpalette")
            }
            .navigationTitle("Prismedia")
        }
        .modifier(PrismediaArtworkScreenBackgroundModifier(palette: nil))
        .preferredColorScheme(.dark)
    }
#endif
