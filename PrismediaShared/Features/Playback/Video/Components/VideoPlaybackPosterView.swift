import SwiftUI

#if !os(tvOS)

    struct VideoPlaybackPosterView: View {
        let detail: EntityDetail
        let ownerLink: EntityLink
        let phase: VideoPlaybackPreparationPhase
        let onPlay: () -> Void

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
                playButton(title: "Play", systemImage: "play.fill")
                    .accessibilityIdentifier("video-detail.play")
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
                    playButton(title: "Try Again", systemImage: "arrow.clockwise")
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

        private func playButton(title: String, systemImage: String) -> some View {
            PrismediaButton(
                title,
                systemImage: systemImage,
                variant: .prominent,
                form: .fill,
                action: onPlay
            )
            .accessibilityLabel("\(title) \(detail.title)")
            .accessibilityHint("Prepares the video and begins playback")
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
                onPlay: {}
            )
        }
    #endif
#endif
