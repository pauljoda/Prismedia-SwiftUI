import SwiftUI

struct DashboardHeroArtworkContinuationView: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    let presentation: DashboardHeroPresentation
    let sceneIndex: Int
    let trickplayFrames: [TrickplayPlaylist.Frame]

    var body: some View {
        GeometryReader { geometry in
            DashboardHeroSceneView(
                presentation: presentation,
                sceneIndex: sceneIndex,
                trickplayFrames: trickplayFrames,
                maxPixelSize: 512
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .scaleEffect(1.08)
            .blur(radius: reduceTransparency ? 0 : 20)
            .overlay(legibilityGradient)
            .overlay(accessibilityScrim)
            .clipped()
        }
        .backgroundExtensionEffect()
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var legibilityGradient: some View {
        LinearGradient(
            colors: [
                PrismediaColor.background.opacity(0.08),
                PrismediaColor.background.opacity(0.34),
                PrismediaColor.background.opacity(0.72),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var accessibilityScrim: some View {
        PrismediaColor.background.opacity(
            reduceTransparency
                ? 0.66
                : colorSchemeContrast == .increased ? 0.34 : 0.12
        )
    }
}

#if DEBUG
    #Preview("Dashboard Hero Artwork Continuation") {
        PreviewShell(signedIn: true) {
            DashboardHeroArtworkContinuationView(
                presentation: DashboardHeroPresentation(item: PrismediaPreviewData.videos[0]),
                sceneIndex: 0,
                trickplayFrames: []
            )
            .frame(width: 390, height: 420)
        }
    }
#endif
