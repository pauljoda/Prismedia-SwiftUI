import SwiftUI

struct VideoFullscreenPreparationView: View {
    let title: String
    let phase: VideoPlaybackPreparationPhase
    let isReadyToPlay: Bool
    let playRequested: Bool
    let resumeSeconds: Double?
    let onResume: () -> Void
    let onRestart: () -> Void
    let onDismiss: () -> Void

    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @State private var resumeCountdown = 3
    @State private var hasSelectedPlaybackAction = false

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
            } else if isReadyToPlay, let resumeSeconds, resumeSeconds > 0 {
                VStack(spacing: PrismediaSpacing.medium) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PrismediaSpacing.medium) {
                            resumeButton(resumeSeconds: resumeSeconds)
                            restartButton
                        }

                        VStack(spacing: PrismediaSpacing.small) {
                            resumeButton(resumeSeconds: resumeSeconds)
                            restartButton
                        }
                    }

                    Text("Resuming automatically in \(resumeCountdown)…")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(PrismediaColor.onMedia.opacity(0.82))
                }
            } else {
                VStack(spacing: PrismediaSpacing.medium) {
                    ProgressView()
                        .tint(artworkPrimaryAccent)
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
        .task(id: resumeCountdownIsActive) {
            guard resumeCountdownIsActive else { return }
            resumeCountdown = 3
            do {
                for remaining in stride(from: 3, through: 1, by: -1) {
                    resumeCountdown = remaining
                    try await Task.sleep(for: .seconds(1))
                }
            } catch {
                return
            }
            guard resumeCountdownIsActive else { return }
            selectResume()
        }
        .accessibilityIdentifier("video-player.surface")
    }

    private func resumeButton(resumeSeconds: Double) -> some View {
        Button(action: selectResume) {
            Label(
                "Resume \(VideoPlaybackPresentation.clockTime(resumeSeconds))",
                systemImage: "play.fill"
            )
            .font(.headline.weight(.semibold))
            .frame(minWidth: 150, minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonBorderShape(.capsule)
        .buttonStyle(.glass)
        .accessibilityHint("Resumes automatically after the countdown")
        .accessibilityIdentifier("video-detail.resume")
    }

    private var restartButton: some View {
        Button(action: selectRestart) {
            Label("Start Over", systemImage: "arrow.counterclockwise")
                .font(.headline.weight(.semibold))
                .frame(minWidth: 150, minHeight: 44)
                .contentShape(Capsule())
        }
        .buttonBorderShape(.capsule)
        .buttonStyle(.glass)
        .accessibilityHint("Starts the video from the beginning")
        .accessibilityIdentifier("video-detail.play-from-beginning")
    }

    private var resumeCountdownIsActive: Bool {
        isReadyToPlay
            && !playRequested
            && !hasSelectedPlaybackAction
            && VideoPlaybackLaunchPolicy.shouldOfferResumeChoice(resumeSeconds: resumeSeconds)
    }

    private func selectResume() {
        guard !hasSelectedPlaybackAction else { return }
        hasSelectedPlaybackAction = true
        onResume()
    }

    private func selectRestart() {
        guard !hasSelectedPlaybackAction else { return }
        hasSelectedPlaybackAction = true
        onRestart()
    }

    private var statusText: String {
        if playRequested { return "Starting playback…" }
        if case .failure = phase { return "Playback unavailable" }
        return "Preparing video…"
    }

    private var statusEyebrow: String {
        if playRequested { return "STARTING" }
        if case .failure = phase { return "UNAVAILABLE" }
        return isReadyToPlay ? "CHOOSE PLAYBACK" : "PREPARING"
    }
}

#if DEBUG
    #Preview("Fullscreen Video Preparation") {
        VideoFullscreenPreparationView(
            title: "Signal in the Static",
            phase: .ready,
            isReadyToPlay: true,
            playRequested: false,
            resumeSeconds: 734,
            onResume: {},
            onRestart: {},
            onDismiss: {}
        )
    }
#endif
