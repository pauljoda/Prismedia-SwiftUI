import AVFoundation
import SwiftUI

struct EntityImageVideoView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var player = EntityImageLoopingPlayer()
    @State private var isPausedByUser = false
    @State private var hasExplicitPlaybackRequest = false
    @State private var playbackClaimID = UUID()

    private let entityID: UUID
    private let path: String?
    private let isPlaybackActive: Bool
    private let isPrewarmActive: Bool
    private let interaction: EntityImageMediaInteraction
    private let videoGravity: AVLayerVideoGravity
    private let showsControls: Bool
    private let onReadyChanged: (Bool) -> Void
    let title: String

    init(
        entityID: UUID,
        path: String,
        title: String,
        isPlaybackActive: Bool = true,
        isPrewarmActive: Bool? = nil,
        contentMode: ContentMode = .fit,
        interaction: EntityImageMediaInteraction = .viewer,
        showsControls: Bool = true,
        onReadyChanged: @escaping (Bool) -> Void = { _ in }
    ) {
        self.entityID = entityID
        self.path = path
        self.title = title
        self.isPlaybackActive = isPlaybackActive
        self.isPrewarmActive = isPrewarmActive ?? isPlaybackActive
        self.interaction = interaction
        videoGravity = contentMode == .fit ? .resizeAspect : .resizeAspectFill
        self.showsControls = showsControls
        self.onReadyChanged = onReadyChanged
    }

    #if DEBUG
        init(previewTitle: String) {
            entityID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            path = nil
            title = previewTitle
            isPlaybackActive = true
            isPrewarmActive = true
            interaction = .viewer
            videoGravity = .resizeAspect
            showsControls = true
            onReadyChanged = { _ in }
        }
    #endif

    var body: some View {
        playbackSurface
    }

    private var playbackSurface: some View {
        GeometryReader { geometry in
            ZStack {
                if let mediaFrame = EntityImageVideoProgressLayout.fittedMediaFrame(
                    containerSize: geometry.size,
                    mediaSize: player.presentationSize
                ) {
                    mediaSurface
                        .frame(width: mediaFrame.width, height: mediaFrame.height)
                        .overlay(alignment: .bottom) {
                            if interaction.showsVideoProgress {
                                progressMeter
                            }
                        }
                        .position(x: mediaFrame.midX, y: mediaFrame.midY)
                } else {
                    mediaSurface
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .clipped()
        .toolbar {
            #if os(iOS)
                if interaction.showsPlaybackControls, showsControls {
                    ToolbarItemGroup(placement: .bottomBar) {
                        playbackButtons
                    }
                }
            #elseif os(macOS)
                if interaction.showsPlaybackControls, showsControls {
                    ToolbarItemGroup(placement: .primaryAction) {
                        playbackButtons
                    }
                }
            #endif
        }
        .task(id: loadableMediaURL) {
            guard let loadableMediaURL else {
                player.unload()
                return
            }
            player.load(url: loadableMediaURL)
            synchronizePlayback()
        }
        .onChange(of: shouldPlay, initial: true) { _, _ in
            synchronizePlayback()
        }
        .onChange(of: effectiveMuted, initial: true) { _, isMuted in
            player.setMuted(isMuted)
        }
        .onChange(of: player.isReady, initial: true) { _, isReady in
            onReadyChanged(isReady)
        }
        .onChange(of: reduceMotion) { _, isEnabled in
            if isEnabled { hasExplicitPlaybackRequest = false }
        }
        .onDisappear {
            onReadyChanged(false)
            environment.imagePlaybackSession.deactivate(
                entityID,
                claimID: playbackClaimID
            )
            player.unload()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("entity.image.video.\(entityID.uuidString)")
    }

    @ViewBuilder
    private var playbackButtons: some View {
        playbackButton
        muteButton
    }

    private var playbackButton: some View {
        Button(
            shouldPlay ? "Pause looping image" : "Play looping image",
            systemImage: shouldPlay ? "pause.fill" : "play.fill",
            action: togglePlayback
        )
    }

    private var muteButton: some View {
        Button(
            effectiveMuted ? "Unmute" : "Mute",
            systemImage: effectiveMuted
                ? "speaker.slash.fill"
                : "speaker.wave.2.fill",
            action: toggleMute
        )
    }

    @ViewBuilder
    private var mediaSurface: some View {
        let surface = NativeImageVideoSurface(
            player: player.player,
            videoGravity: videoGravity
        )
        .allowsHitTesting(false)
        .opacity(player.isReady ? 1 : 0)
        .accessibilityLabel(title)
        .accessibilityValue(shouldPlay ? "Playing" : "Paused")

        if interaction.allowsPlaybackToggle {
            surface.accessibilityAction(named: "Toggle Playback", togglePlayback)
        } else {
            surface
        }
    }

    private var progressMeter: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(PrismediaColor.background.opacity(0.5))
            Rectangle()
                .fill(PrismediaColor.accent)
                .scaleEffect(x: player.progress, y: 1, anchor: .leading)
        }
        .frame(height: 3)
        .accessibilityHidden(true)
    }

    private var mediaURL: URL? {
        guard let path else { return nil }
        return environment.client?.authenticatedMediaURL(for: path)
    }

    private var loadableMediaURL: URL? {
        isPrewarmActive ? mediaURL : nil
    }

    private var shouldPlay: Bool {
        EntityImageAutoplayPolicy.shouldPlay(
            isVisible: isPlaybackActive,
            isPausedByUser: isPausedByUser,
            reduceMotion: reduceMotion,
            isSceneActive: scenePhase == .active,
            isExplicitPlaybackRequested: hasExplicitPlaybackRequest
        )
    }

    private var effectiveMuted: Bool {
        environment.imagePlaybackSession.isMuted(for: playbackClaimID)
    }

    private func togglePlayback() {
        if reduceMotion, !hasExplicitPlaybackRequest {
            hasExplicitPlaybackRequest = true
            isPausedByUser = false
        } else {
            isPausedByUser.toggle()
        }
        synchronizePlayback()
    }

    private func toggleMute() {
        environment.imagePlaybackSession.toggleMute(
            entityID: entityID,
            claimID: playbackClaimID
        )
        player.setMuted(effectiveMuted)
    }

    private func synchronizePlayback() {
        if shouldPlay {
            environment.imagePlaybackSession.activate(
                entityID,
                claimID: playbackClaimID
            )
        } else {
            environment.imagePlaybackSession.deactivate(
                entityID,
                claimID: playbackClaimID
            )
        }
        player.setMuted(effectiveMuted)
        player.setPlaybackAllowed(shouldPlay)
    }
}

#if DEBUG
    #Preview("Video-backed Image") {
        PreviewShell {
            EntityImageVideoView(previewTitle: "Looping Image Preview")
                .background(PrismediaColor.background)
        }
    }
#endif
