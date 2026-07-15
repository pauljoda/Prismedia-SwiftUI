import SwiftUI

struct DashboardHeroPageView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var artworkPalette: ArtworkPalette?

    let presentation: DashboardHeroPresentation
    let viewportWidth: CGFloat
    let heroHeight: CGFloat
    let reservesProgressIndicatorSpace: Bool
    let onNavigate: (EntityLink) -> Void

    var body: some View {
        DashboardHeroArtworkView(presentation: presentation)
            .backgroundExtensionEffect(isEnabled: !reduceTransparency)
            .frame(width: viewportWidth, height: heroHeight)
            .overlay(alignment: .bottomLeading) {
                DashboardHeroContentView(
                    presentation: presentation,
                    viewportWidth: viewportWidth,
                    accent: resolvedAccent,
                    reservesProgressIndicatorSpace: reservesProgressIndicatorSpace,
                    onNavigate: onNavigate
                )
            }
            .clipped()
            .prismediaArtworkPalette(
                for: presentation.item.bestCoverPath,
                palette: $artworkPalette
            )
    }

    private var resolvedAccent: Color {
        artworkPalette?.primary.color ?? PrismediaColor.accent
    }
}

#if DEBUG
    #Preview("Dashboard Hero Page") {
        let presentations = PrismediaPreviewData.videos.map(DashboardHeroPresentation.init)
        PreviewShell(signedIn: true) {
            DashboardHeroPageView(
                presentation: presentations[0],
                viewportWidth: 390,
                heroHeight: 440,
                reservesProgressIndicatorSpace: true,
                onNavigate: { _ in }
            )
        }
    }
#endif
