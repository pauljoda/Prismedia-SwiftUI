import SwiftUI

struct DashboardHeroArtworkView: View {
    let presentation: DashboardHeroPresentation

    var body: some View {
        Color.clear
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .overlay {
                RemotePosterImage(
                    path: presentation.thumbnailPath,
                    fallbackSeed: presentation.item.title,
                    systemImage: "play.rectangle",
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
                presentation: DashboardHeroPresentation(item: PrismediaPreviewData.videos[0])
            )
            .frame(height: 440)
        }
    }
#endif
