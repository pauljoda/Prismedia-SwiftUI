import SwiftUI

struct ResolvedVideoPlaybackView: View {
    let detail: EntityDetail
    let service: any VideoPlaybackServicing

    let controller: VideoPlaybackController
    let presentationMode: VideoPlaybackPresentationMode
    let onFullscreenChange: (Bool) -> Void
    @State private var isFullScreen = false
    @State private var filmstripFinishedPreparing = false
    @State private var filmstripUnavailable = false

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
                                onFullscreen: { isFullScreen = true }
                            )
                        }
                    }
                    .aspectRatio(16 / 9, contentMode: .fit)

                    #if !os(tvOS)
                        if let trickplayPath, !filmstripUnavailable {
                            VideoFilmstripView(
                                playlistPath: trickplayPath,
                                service: service,
                                controller: controller,
                                markers: markers,
                                onInitialLoadCompleted: { available in
                                    filmstripFinishedPreparing = true
                                    filmstripUnavailable = !available
                                }
                            )
                            .padding(.top, filmstripTopSpacing)
                            .accessibilityIdentifier("video-detail.filmstrip")
                        }
                    #endif

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
                isInteractive: isInteractive
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
            onFullscreenChange(isPresented)
        }
        .alert("Couldn’t Play Video", isPresented: errorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(controller.errorMessage ?? "Please try again.")
        }
    }

    private var trickplayPath: String? {
        detail.capabilities.compactMap { capability -> String? in
            guard case .files(let files) = capability else { return nil }
            return files.items.first(where: { $0.role == "trickplay" })?.path
        }.first
    }

    private var markers: [EntityMarker] {
        detail.capabilities.compactMap { capability -> [EntityMarker]? in
            guard case .markers(let markers) = capability else { return nil }
            return markers.items
        }.first ?? []
    }

    private var filmstripTopSpacing: CGFloat {
        #if os(iOS)
            6
        #else
            0
        #endif
    }

    private var resumeSeconds: Double {
        detail.capabilities.compactMap { capability -> Double? in
            guard case .playback(let playback) = capability else { return nil }
            return playback.resumeSeconds
        }.first ?? 0
    }

    private var isInteractive: Bool {
        VideoPlaybackReadiness.isInteractive(
            playerReady: controller.isReadyToPlay,
            optionsReady: controller.arePlaybackOptionsReady,
            filmstripReady: presentationMode == .fullscreenOnly
                || trickplayPath == nil
                || filmstripFinishedPreparing
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
            service: VideoPlaybackPreviewService(),
            controller: controller,
            presentationMode: .inline,
            onFullscreenChange: { _ in }
        )
        .background(Color.black)
    }
#endif
