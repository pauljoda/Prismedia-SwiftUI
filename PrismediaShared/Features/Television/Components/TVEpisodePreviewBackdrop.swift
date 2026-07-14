import SwiftUI

#if os(tvOS)
    struct TVEpisodePreviewBackdrop: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var previewFrames: [TrickplayPlaylist.Frame] = []
        @State private var sceneIndex = 0
        @State private var panProgress: CGFloat = 0
        @State private var frameIsVisible = false

        let episode: EntityThumbnail?
        let seriesHeroPath: String?
        let loader: (any TrickplayFrameLoading)?

        var body: some View {
            ZStack {
                RemotePosterImage(
                    path: episode?.bestHeroPath ?? seriesHeroPath,
                    previewPath: episode?.bestCoverPath,
                    fallbackSeed: episode?.title ?? "Series",
                    systemImage: "tv",
                    retainsCurrentImageWhileLoading: true,
                    maxPixelSize: 2_048
                )
                .opacity(frameIsVisible ? 0 : 1)
                .scaleEffect(frameIsVisible && !reduceMotion ? 1.018 : 1)

                if let frame = activeFrame {
                    SpriteFrameView(frame: frame, imageURL: frame.imageURL)
                        .opacity(frameIsVisible ? 1 : 0)
                        .scaleEffect(reduceMotion ? 1 : 1.02 + (0.012 * panProgress))
                        .offset(panOffset(for: frame))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .task(id: previewRequestID) {
                await runPreview()
            }
            .accessibilityHidden(true)
            .allowsHitTesting(false)
        }

        private var activeFrame: TrickplayPlaylist.Frame? {
            guard sceneIndex > 0, sceneIndex <= previewFrames.count else { return nil }
            return previewFrames[sceneIndex - 1]
        }

        private var previewRequestID: String {
            "\(episode?.id.uuidString ?? "series")|\(episode?.trickplayPlaylistPath ?? "none")|reduce:\(reduceMotion)"
        }

        @MainActor
        private func runPreview() async {
            previewFrames = []
            sceneIndex = 0
            panProgress = 0
            frameIsVisible = false
            guard !reduceMotion,
                let loader,
                let playlistPath = episode?.trickplayPlaylistPath
            else { return }

            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            let loaded = await loader.loadFrames(playlistPath: playlistPath)
            guard !Task.isCancelled else { return }
            previewFrames = TVEpisodePreviewFrameSampler.sample(loaded, limit: 4)
            guard !previewFrames.isEmpty else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(sceneIndex == 0 ? 3 : 4))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    frameIsVisible = false
                }
                try? await Task.sleep(for: .milliseconds(420))
                guard !Task.isCancelled else { return }
                sceneIndex = (sceneIndex + 1) % (previewFrames.count + 1)
                panProgress = 0
                guard sceneIndex > 0 else { continue }
                withAnimation(.easeInOut(duration: 0.4)) {
                    frameIsVisible = true
                }
                withAnimation(.linear(duration: 3.8)) {
                    panProgress = 1
                }
            }
        }

        private func panOffset(for frame: TrickplayPlaylist.Frame) -> CGSize {
            guard !reduceMotion, activeFrame?.startTime == frame.startTime else { return .zero }
            let frameIndex = previewFrames.firstIndex(where: { $0.startTime == frame.startTime }) ?? 0
            let direction: CGFloat = frameIndex.isMultiple(of: 2) ? 1 : -1
            return CGSize(
                width: direction * (-7 + (14 * panProgress)),
                height: direction * (4 - (8 * panProgress))
            )
        }
    }
#endif

#if os(tvOS) && DEBUG
    #Preview("TV Episode Preview Backdrop · Thumbnail") {
        PreviewShell(signedIn: true) {
            TVEpisodePreviewBackdrop(
                episode: TVSeasonsPreviewData.episodeThumbnail,
                seriesHeroPath: "/preview/hero.jpg",
                loader: nil
            )
        }
        .frame(width: 1_920, height: 1_080)
    }
#endif
