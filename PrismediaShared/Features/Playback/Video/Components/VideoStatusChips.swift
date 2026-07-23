import SwiftUI

struct VideoStatusChips: View {
    let badges: [VideoPlaybackBadge]
    var overlaysVideo = false
    var contentHorizontalPadding = PrismediaSpacing.medium
    var scrollAnchor: UnitPoint = .leading
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent

    var body: some View {
        GlassEffectContainer(spacing: PrismediaSpacing.small) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PrismediaSpacing.small) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                        PrismediaGlassStatusChip(
                            badge.label,
                            systemImage: badge.systemImage,
                            tint: tint(for: badge.tone)
                        )
                        .accessibilityLabel(badge.label)
                    }
                }
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.vertical, PrismediaSpacing.small)
            }
            .defaultScrollAnchor(scrollAnchor)
        }
        .accessibilityIdentifier("video-detail.media-badges")
    }

    private func tint(for tone: VideoPlaybackBadge.Tone) -> Color {
        switch tone {
        case .direct: PrismediaColor.success
        case .transcode: PrismediaColor.warning
        case .neutral:
            overlaysVideo
                ? PrismediaColor.mediaOverlayGlassTint
                : artworkPrimaryAccent
        case .premium: PrismediaColor.spectrumViolet
        }
    }
}

#if DEBUG
    #Preview("Video Status Chips · Dark Content") {
        VideoStatusChips(badges: previewBadges)
            .background(PrismediaBackdrop())
            .preferredColorScheme(.dark)
    }

    #Preview("Video Status Chips · Bright Media") {
        ZStack {
            LinearGradient(colors: [.white, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            VideoStatusChips(badges: previewBadges, overlaysVideo: true)
        }
    }

    #Preview("Video Status Chips · Dark Media") {
        ZStack {
            LinearGradient(colors: [.black, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
            VideoStatusChips(badges: previewBadges, overlaysVideo: true)
        }
    }

    #Preview("Video Status Chips · Accessibility") {
        VideoStatusChips(badges: previewBadges)
            .background(PrismediaBackdrop())
            .environment(\.dynamicTypeSize, .accessibility3)
    }

    private let previewBadges = [
        VideoPlaybackBadge(label: "Direct Play", systemImage: "play.rectangle", tone: .direct),
        VideoPlaybackBadge(label: "4K", tone: .neutral),
        VideoPlaybackBadge(label: "Dolby Vision", systemImage: "sparkles", tone: .premium),
    ]
#endif
