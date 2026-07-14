import SwiftUI

struct DashboardHeroPageView: View {
    @State private var artworkPalette: ArtworkPalette?

    let presentation: DashboardHeroPresentation
    let sceneIndex: Int
    let trickplayFrames: [TrickplayPlaylist.Frame]
    let viewportWidth: CGFloat
    let reservesProgressIndicatorSpace: Bool
    let onNavigate: (EntityLink) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DashboardHeroArtworkView(
                presentation: presentation,
                sceneIndex: sceneIndex,
                trickplayFrames: trickplayFrames
            )

            DashboardHeroContentView(
                presentation: presentation,
                viewportWidth: viewportWidth,
                accent: resolvedAccent,
                reservesProgressIndicatorSpace: reservesProgressIndicatorSpace,
                onNavigate: onNavigate
            )
        }
        .background {
            DashboardHeroArtworkContinuationView(
                presentation: presentation,
                sceneIndex: sceneIndex,
                trickplayFrames: trickplayFrames
            )
        }
        .frame(width: viewportWidth, alignment: .topLeading)
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
                sceneIndex: 0,
                trickplayFrames: [],
                viewportWidth: 390,
                reservesProgressIndicatorSpace: true,
                onNavigate: { _ in }
            )
        }
    }
#endif
