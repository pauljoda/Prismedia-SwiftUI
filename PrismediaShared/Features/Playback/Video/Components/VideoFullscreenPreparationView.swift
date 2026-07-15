import SwiftUI

struct VideoFullscreenPreparationView: View {
    let title: String
    let phase: VideoPlaybackPreparationPhase
    let isReadyToPlay: Bool
    let playRequested: Bool
    let onPlay: () -> Void
    let onDismiss: () -> Void

    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    var body: some View {
        ZStack {
            Color.black

            if playRequested {
                VStack(spacing: PrismediaSpacing.medium) {
                    ProgressView()
                        .tint(artworkPrimaryAccent)
                    Text("Starting playback…")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.82))
                }
            } else {
                VStack(spacing: PrismediaSpacing.medium) {
                    Button(action: onPlay) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(PrismediaColor.onMedia)
                            .frame(width: 62, height: 62)
                            .contentShape(Circle())
                    }
                    .buttonBorderShape(.circle)
                    .buttonStyle(.glass(.clear))
                    .disabled(!isReadyToPlay)
                    .accessibilityLabel("Play")
                    .accessibilityHint(statusText)
                    .accessibilityIdentifier("video-detail.play")

                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.82))
                }
            }

            VStack(spacing: 0) {
                HStack(spacing: PrismediaSpacing.medium) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(statusEyebrow)
                            .font(.caption2.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(artworkPrimaryAccent)
                        Text(title)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                            .foregroundStyle(PrismediaColor.onMedia)
                    }
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .frame(width: 38, height: 38)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .accessibilityLabel("Exit Full Screen")
                }
                Spacer()
            }
            .padding(20)
        }
        .accessibilityIdentifier("video-player.surface")
    }

    private var statusText: String {
        if playRequested { return "Starting playback…" }
        if case .failure = phase { return "Playback unavailable" }
        return isReadyToPlay ? "Press play to begin" : "Preparing video…"
    }

    private var statusEyebrow: String {
        if playRequested { return "STARTING" }
        if case .failure = phase { return "UNAVAILABLE" }
        return isReadyToPlay ? "READY" : "PREPARING"
    }
}

#if DEBUG
    #Preview("Fullscreen Video Preparation") {
        VideoFullscreenPreparationView(
            title: "Signal in the Static",
            phase: .ready,
            isReadyToPlay: true,
            playRequested: false,
            onPlay: {},
            onDismiss: {}
        )
    }
#endif
