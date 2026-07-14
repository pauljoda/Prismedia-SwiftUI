import SwiftUI

struct DashboardHeroArtworkView: View {
    let presentation: DashboardHeroPresentation
    let sceneIndex: Int
    let trickplayFrames: [TrickplayPlaylist.Frame]

    var body: some View {
        Color.clear
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
                DashboardHeroSceneView(
                    presentation: presentation,
                    sceneIndex: sceneIndex,
                    trickplayFrames: trickplayFrames,
                    maxPixelSize: 1_536
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .compositingGroup()
            .clipped()
            .mask(artworkFade)
            .frame(maxWidth: .infinity)
            .backgroundExtensionEffect()
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    private var artworkFade: some View {
        LinearGradient(
            stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.78),
                .init(color: .black.opacity(0.78), location: 0.9),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#if DEBUG
    #Preview("Dashboard Hero Artwork · Static") {
        PreviewShell(signedIn: true) {
            DashboardHeroArtworkView(
                presentation: DashboardHeroPresentation(item: PrismediaPreviewData.videos[0]),
                sceneIndex: 0,
                trickplayFrames: []
            )
            .frame(height: 440)
        }
    }
#endif
