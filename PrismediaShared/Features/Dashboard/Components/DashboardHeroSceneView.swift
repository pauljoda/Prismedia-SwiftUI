import SwiftUI

struct DashboardHeroSceneView: View {
    let presentation: DashboardHeroPresentation
    let sceneIndex: Int
    let trickplayFrames: [TrickplayPlaylist.Frame]
    let maxPixelSize: Int

    var body: some View {
        ZStack {
            if !trickplayFrames.isEmpty {
                RemotePosterImage(
                    path: presentation.scenePaths.first,
                    previewPath: presentation.item.bestCoverPath,
                    fallbackSeed: presentation.item.title,
                    systemImage: "play.rectangle",
                    retainsCurrentImageWhileLoading: true,
                    maxPixelSize: maxPixelSize
                )
                .opacity(sceneIndex == 0 ? 1 : 0)

                ForEach(trickplayFrames.indices, id: \.self) { index in
                    SpriteFrameView(
                        frame: trickplayFrames[index],
                        imageURL: trickplayFrames[index].imageURL
                    )
                    .opacity(sceneIndex == index + 1 ? 1 : 0)
                }
            } else if presentation.scenePaths.isEmpty {
                RemotePosterImage(
                    path: nil,
                    fallbackSeed: presentation.item.title,
                    systemImage: "play.rectangle",
                    maxPixelSize: maxPixelSize
                )
            } else {
                ForEach(presentation.scenePaths, id: \.self) { path in
                    RemotePosterImage(
                        path: path,
                        previewPath: presentation.item.bestCoverPath,
                        fallbackSeed: presentation.item.title,
                        systemImage: "play.rectangle",
                        retainsCurrentImageWhileLoading: true,
                        maxPixelSize: maxPixelSize
                    )
                    .opacity(path == selectedPath ? 1 : 0)
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private var selectedPath: String? {
        guard !presentation.scenePaths.isEmpty else { return nil }
        let index = min(max(sceneIndex, 0), presentation.scenePaths.count - 1)
        return presentation.scenePaths[index]
    }
}

#if DEBUG
    #Preview("Dashboard Hero Scene") {
        PreviewShell(signedIn: true) {
            DashboardHeroSceneView(
                presentation: DashboardHeroPresentation(item: PrismediaPreviewData.videos[0]),
                sceneIndex: 0,
                trickplayFrames: [],
                maxPixelSize: 1_024
            )
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
        }
    }
#endif
