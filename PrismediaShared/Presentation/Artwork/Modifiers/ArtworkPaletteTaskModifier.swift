import SwiftUI

struct ArtworkPaletteTaskModifier: ViewModifier {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Binding var palette: ArtworkPalette?

    let artworkPath: String?
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .task(id: requestID) {
                guard isEnabled, let artworkURL else {
                    palette = nil
                    return
                }
                let resolved = await environment.artworkPaletteLoader.palette(for: artworkURL)
                guard !Task.isCancelled else { return }
                palette = resolved
            }
    }

    private var artworkURL: URL? {
        environment.client?.assetURL(for: artworkPath)
    }

    private var requestID: String {
        guard isEnabled else { return "disabled" }
        return artworkURL?.absoluteString ?? "missing"
    }
}

extension View {
    func prismediaArtworkPalette(
        for artworkPath: String?,
        isEnabled: Bool = true,
        palette: Binding<ArtworkPalette?>
    ) -> some View {
        modifier(
            ArtworkPaletteTaskModifier(
                palette: palette,
                artworkPath: artworkPath,
                isEnabled: isEnabled
            )
        )
    }
}

#if DEBUG
    #Preview("Artwork Palette Task · Disabled") {
        @Previewable @State var palette: ArtworkPalette?
        PreviewShell {
            Text(palette == nil ? "Fallback accent" : "Artwork accent")
                .padding()
                .modifier(
                    ArtworkPaletteTaskModifier(
                        palette: $palette,
                        artworkPath: nil,
                        isEnabled: false
                    )
                )
        }
    }
#endif
