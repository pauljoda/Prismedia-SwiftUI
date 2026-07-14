import SwiftUI

struct VideoFullscreenPreparationView: View {
    let title: String
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
                    Text("Preparing video…")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.82))
                }
            } else {
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(PrismediaColor.onMedia)
                        .frame(width: 62, height: 62)
                        .contentShape(Circle())
                }
                .buttonBorderShape(.circle)
                .buttonStyle(.glass(.clear))
                .accessibilityLabel("Play")
                .accessibilityIdentifier("video-detail.play")
            }

            VStack(spacing: 0) {
                HStack(spacing: PrismediaSpacing.medium) {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraSmall) {
                        Text(playRequested ? "PREPARING" : "PRESS PLAY")
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
}

#if DEBUG
    #Preview("Fullscreen Video Preparation") {
        VideoFullscreenPreparationView(
            title: "Signal in the Static",
            playRequested: false,
            onPlay: {},
            onDismiss: {}
        )
    }
#endif
