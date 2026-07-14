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
            .clipped()
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
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
