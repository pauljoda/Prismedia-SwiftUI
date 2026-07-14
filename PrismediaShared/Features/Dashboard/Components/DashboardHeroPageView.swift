import SwiftUI

struct DashboardHeroPageView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.displayScale) private var displayScale
    @State private var artworkPalette: ArtworkPalette?

    let presentation: DashboardHeroPresentation
    let sceneIndex: Int
    let trickplayFrames: [TrickplayPlaylist.Frame]
    let viewportWidth: CGFloat
    let topSafeAreaHeight: CGFloat
    let reservesProgressIndicatorSpace: Bool
    let onNavigate: (EntityLink) -> Void

    var body: some View {
        DashboardHeroArtworkView(
            presentation: presentation,
            sceneIndex: sceneIndex,
            trickplayFrames: trickplayFrames
        )
        .backgroundExtensionEffect(isEnabled: !reduceTransparency)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear
                .frame(height: max(topSafeAreaHeight, 0))
                .accessibilityHidden(true)
        }
        .safeAreaInset(edge: .bottom, spacing: -seamOverlap) {
            DashboardHeroContentView(
                presentation: presentation,
                viewportWidth: viewportWidth,
                accent: resolvedAccent,
                reservesProgressIndicatorSpace: reservesProgressIndicatorSpace,
                onNavigate: onNavigate
            )
        }
        .clipped()
        .frame(width: viewportWidth, alignment: .topLeading)
        .prismediaArtworkPalette(
            for: presentation.item.bestCoverPath,
            palette: $artworkPalette
        )
    }

    private var resolvedAccent: Color {
        artworkPalette?.primary.color ?? PrismediaColor.accent
    }

    private var seamOverlap: CGFloat {
        1 / max(displayScale, 1)
    }
}

#if DEBUG
    #Preview("Dashboard Hero Page") {
        let presentations = PrismediaPreviewData.videos.map(DashboardHeroPresentation.init)
        PreviewShell(signedIn: true) {
            DashboardHeroPageView(
                presentation: presentations[0],
                sceneIndex: 0,
                trickplayFrames: [],
                viewportWidth: 390,
                topSafeAreaHeight: 59,
                reservesProgressIndicatorSpace: true,
                onNavigate: { _ in }
            )
        }
    }
#endif
