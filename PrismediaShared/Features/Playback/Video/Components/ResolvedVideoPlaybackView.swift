import SwiftUI

struct ResolvedVideoPlaybackView: View {
    let detail: EntityDetail
    let controller: VideoPlaybackController
    let presentationMode: VideoPlaybackPresentationMode
    let trickplayPlaylistPath: String?
    let trickplayFrameLoader: (any TrickplayFrameLoading)?
    let onFullscreenChange: (Bool) -> Void
    @State private var isFullScreen = false

    var body: some View {
        Group {
            if presentationMode == .inline {
                VStack(spacing: 0) {
                    Group {
                        if isFullScreen {
                            Color.black
                        } else {
                            PrismediaVideoPlayerView(
                                controller: controller,
                                title: detail.title,
                                isInteractive: isInteractive,
                                isExpanded: false,
                                badges: controller.badges,
                                trickplayPlaylistPath: trickplayPlaylistPath,
                                trickplayFrameLoader: trickplayFrameLoader,
                                onFullscreen: { isFullScreen = true }
                            )
                        }
                    }
                    .aspectRatio(16 / 9, contentMode: .fit)

                    if !controller.badges.isEmpty {
                        VideoStatusChips(badges: controller.badges)
                    }
                }
            } else {
                Color.clear
                    .frame(height: 0)
                    .accessibilityHidden(true)
            }
        }
        .modifier(
            VideoFullscreenPresentationModifier(
                isPresented: $isFullScreen,
                controller: controller,
                title: detail.title,
                isInteractive: isInteractive,
                trickplayPlaylistPath: trickplayPlaylistPath,
                trickplayFrameLoader: trickplayFrameLoader,
                onDismiss: { onFullscreenChange(false) }
            )
        )
        #if DEBUG
            .task {
                if presentationMode == .fullscreenOnly
                    || PrismediaUITestBootstrap.startsVideoInFullscreen()
                {
                    isFullScreen = true
                }
            }
        #else
            .task {
                guard presentationMode == .fullscreenOnly else { return }
                isFullScreen = true
            }
        #endif
        .onChange(of: isFullScreen) { _, isPresented in
            guard isPresented else { return }
            onFullscreenChange(true)
        }
        .alert("Couldn’t Play Video", isPresented: errorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(controller.errorMessage ?? "Please try again.")
        }
    }

    private var isInteractive: Bool {
        VideoPlaybackReadiness.isInteractive(
            playerReady: controller.isReadyToPlay,
            optionsReady: controller.arePlaybackOptionsReady
        )
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { controller.errorMessage != nil },
            set: { if !$0 { controller.dismissError() } }
        )
    }
}

#if DEBUG
    #Preview("Resolved Video Playback") {
        let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let json = """
            {"id":"\(id.uuidString)","kind":"video","title":"Signal in the Static","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}
            """
        let detail = try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
        let controller = VideoPlaybackController(videoID: id, service: VideoPlaybackPreviewService())
        ResolvedVideoPlaybackView(
            detail: detail,
            controller: controller,
            presentationMode: .inline,
            trickplayPlaylistPath: nil,
            trickplayFrameLoader: nil,
            onFullscreenChange: { _ in }
        )
        .background(Color.black)
    }
#endif
