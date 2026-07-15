import SwiftUI

#if !os(tvOS)

    struct VideoPlaybackPosterView: View {
        let detail: EntityDetail
        let ownerLink: EntityLink
        let phase: VideoPlaybackPreparationPhase
        let onPlay: (Double?) -> Void

        var body: some View {
            ZStack {
                extendedArtwork
                phaseContent
            }
            .frame(maxWidth: .infinity, minHeight: 180)
            .aspectRatio(16 / 9, contentMode: .fit)
            .compositingGroup()
            .mask {
                bottomExtensionMask
            }
            .clipped()
        }

        private var extendedArtwork: some View {
            ZStack {
                artwork
                LinearGradient(
                    colors: [.black.opacity(0.12), .black.opacity(0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }

        private var bottomExtensionMask: some View {
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 0.7),
                    .init(color: .white.opacity(0.74), location: 0.84),
                    .init(color: Color.clear, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        private var artwork: some View {
            let presentation = EntityDetailPresentation(detail: detail)
            return RemotePosterImage(
                path: presentation.heroPath
                    ?? presentation.posterPath
                    ?? ownerLink.thumbnailPreview?.artworkPath,
                previewPath: ownerLink.thumbnailPreview?.artworkPath,
                fallbackSeed: detail.title,
                systemImage: presentation.systemImage,
                contentMode: .fill
            )
            .accessibilityHidden(true)
        }

        @ViewBuilder
        private var phaseContent: some View {
            switch phase {
            case .idle:
                playbackActions
            case .loading:
                ProgressView("Preparing video…")
                    .font(.headline)
                    .tint(PrismediaColor.onMedia)
                    .foregroundStyle(PrismediaColor.onMedia)
                    .padding(.horizontal, PrismediaSpacing.extraLarge)
                    .frame(minHeight: 52)
                    .glassEffect(.regular, in: .capsule)
                    .accessibilityIdentifier("video-detail.preparing")
            case .failure(let message):
                VStack(spacing: PrismediaSpacing.medium) {
                    Label("Video Unavailable", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                    Text(message)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    playButton(title: "Try Again", systemImage: "arrow.clockwise") {
                        onPlay(nil)
                    }
                    .accessibilityIdentifier("video-detail.retry")
                }
                .foregroundStyle(PrismediaColor.onMedia)
                .padding(PrismediaSpacing.extraLarge)
                .frame(maxWidth: 420)
            case .ready:
                ProgressView()
                    .tint(PrismediaColor.onMedia)
                    .accessibilityLabel("Opening video")
            }
        }

        @ViewBuilder
        private var playbackActions: some View {
            GlassEffectContainer(spacing: PrismediaSpacing.medium) {
                if resumeSeconds > 1 {
                    HStack(spacing: PrismediaSpacing.medium) {
                        playButton(
                            title: "Resume \(playbackTimestamp(resumeSeconds))",
                            systemImage: "play.fill"
                        ) {
                            onPlay(nil)
                        }
                        .accessibilityIdentifier("video-detail.resume")

                        playButton(title: "Start Over", systemImage: "arrow.counterclockwise") {
                            onPlay(0)
                        }
                        .accessibilityIdentifier("video-detail.play-from-beginning")
                    }
                } else {
                    playButton(title: "Play", systemImage: "play.fill") {
                        onPlay(nil)
                    }
                    .accessibilityIdentifier("video-detail.play")
                }
            }
            .padding(.horizontal, PrismediaSpacing.extraLarge)
        }

        private func playButton(
            title: String,
            systemImage: String,
            action: @escaping () -> Void
        ) -> some View {
            PrismediaButton(
                title,
                systemImage: systemImage,
                variant: .prominent,
                action: action
            )
            .accessibilityLabel("\(title) \(detail.title)")
            .accessibilityHint("Prepares the video and begins playback")
        }

        private var resumeSeconds: Double {
            let detailResumeSeconds = detail.capabilities.compactMap { capability -> Double? in
                guard case .playback(let playback) = capability else { return nil }
                return playback.resumeSeconds
            }.first
            return VideoInitialResumePosition.resolve(
                detailResumeSeconds: detailResumeSeconds,
                thumbnailResumeSeconds: ownerLink.thumbnailPreview?.resumeSeconds
            )
        }

        private func playbackTimestamp(_ seconds: Double) -> String {
            let total = max(0, Int(seconds.rounded(.down)))
            let hours = total / 3_600
            let minutes = (total % 3_600) / 60
            let remainingSeconds = total % 60

            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
            }
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }

    #if DEBUG
        #Preview("Video Playback Poster") {
            let id = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            let json = """
                {"id":"\(id.uuidString)","kind":"video","title":"Signal in the Static","hasSourceMedia":true,"capabilities":[],"childrenByKind":[],"relationships":[]}
                """
            let detail = try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
            VideoPlaybackPosterView(
                detail: detail,
                ownerLink: EntityLink(entityID: detail.id, kind: detail.kind),
                phase: .idle,
                onPlay: { _ in }
            )
        }
    #endif
#endif
